import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'auto_name.dart';
import 'color_detect.dart';
import 'color_names.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'review_prompt.dart';

/// Holds the entire app state: the wardrobes and their clothing, the kinds
/// and types it's sorted into, the outfit canvas with what's currently on
/// it, saved outfits, the diary, settings — and persistence to disk.
class WardrobeStore extends ChangeNotifier {
  static const _fileName = 'satnik_v1.json';

  /// The state file's format, written as its `version`. An import from a
  /// newer one is refused.
  static const _stateVersion = 3;

  /// A copy of the state file as it was before kinds and types replaced the
  /// fixed categories and folders — kept in case that migration ever needs
  /// to be looked into.
  static const _preKindsBackupName = 'satnik_v1.pre-kinds.json';

  /// Localizations for text this store has to bake into stored data (default
  /// kind/type/wardrobe names) without a [BuildContext] —
  /// matching [localeCode], or the device locale when that's unset.
  /// The app's texts in its current language, for things said outside any
  /// screen (notifications).
  AppLocalizations get texts => _l10n;

  AppLocalizations get _l10n {
    final code = localeCode ?? PlatformDispatcher.instance.locale.languageCode;
    return lookupAppLocalizations(Locale(code == 'en' ? 'en' : 'cs'));
  }

  /// Every wardrobe, in display order. The *active* one's content lives in
  /// the plain fields below ([items], [outfits], [diary]) so the rest of the
  /// app never has to know there's more than one; every other wardrobe's
  /// content waits in [_stash] until it's switched to.
  List<Wardrobe> wardrobes = [];
  String activeWardrobeId = '';
  final Map<String, _WardrobeContent> _stash = {};

  /// How many items [wardrobeId] holds — the active one or a stashed one.
  int itemCountIn(String wardrobeId) =>
      wardrobeId == activeWardrobeId ? items.length : _stash[wardrobeId]?.items.length ?? 0;

  Wardrobe get activeWardrobe =>
      wardrobes.firstWhere((w) => w.id == activeWardrobeId);

  WardrobeTabKind screen = WardrobeTabKind.outfit;
  List<ClothingItem> items = [];
  /// Saved outfits, oldest first.
  List<SavedOutfit> outfits = [];

  /// The outfits written down as worn, oldest first.
  List<DiaryEntry> diary = [];

  /// Every kind of clothing, in display order — shared by all wardrobes.
  List<ClothingKind> kinds = [];

  ClothingKind? kindById(String id) {
    for (final k in kinds) {
      if (k.id == id) return k;
    }
    return null;
  }

  /// The kind's name, or its id if it's gone (shouldn't happen — a kind
  /// can only be deleted once no item uses it).
  String kindName(String kindId) => kindById(kindId)?.name ?? kindId;

  /// The name of [item]'s type (`null` only if its type is somehow gone).
  String? typeName(ClothingItem item) => kindById(item.cat)?.typeById(item.typeId)?.name;

  /// What to call [item]: its own name, or one made up from its color and
  /// type ("Zelená košile") — see [hasOwnName].
  String displayName(ClothingItem item) {
    final own = item.name;
    if (own != null && own.isNotEmpty) return own;
    final l = _l10n;
    final colors = item.colors;
    final type = typeName(item) ?? '';
    return autoItemName(
      languageCode: l.localeName,
      typeName: _otherTypeNames.contains(type) ? '' : type,
      kindName: kindName(item.cat),
      otherTypeName: l.otherTypeName,
      typeIsModifier: _modifierTypeNames.contains(type),
      colorName: colors == null || colors.isEmpty ? null : l.colorFamily(ColorFamily.of(colors.first).name),
    );
  }

  /// Everything [item] can be found by: its name (own or made up), kind,
  /// type, color and other details — the same in every search.
  List<String?> searchTexts(ClothingItem item) {
    final colors = item.colors;
    return [
      displayName(item),
      kindName(item.cat),
      typeName(item),
      if (colors != null && colors.isNotEmpty) _l10n.colorFamily(ColorFamily.of(colors.first).name),
      item.seller,
      item.size,
      item.price,
      item.note,
    ];
  }

  /// Whether [item]'s name was given by the user, not made up.
  bool hasOwnName(ClothingItem item) => item.name?.isNotEmpty ?? false;

  /// Type names the app has given dresses by default, which describe
  /// rather than name ("Summer", "Formal" dresses), in every language.
  /// Listed here, not taken from today's defaults: wardrobes made with
  /// earlier ones still have them.
  static const _modifierTypeNames = {'Letní', 'Společenské', 'Summer', 'Formal'};

  /// The catch-all type's name in every language (it's stored as created).
  static final _otherTypeNames = {
    lookupAppLocalizations(const Locale('cs')).otherTypeName,
    lookupAppLocalizations(const Locale('en')).otherTypeName,
  };

  /// The active wardrobe's items of one kind, in the order they were added.
  List<ClothingItem> itemsOfKind(String kindId) =>
      items.where((i) => i.cat == kindId).toList();

  /// Items of [kindId] in *every* wardrobe — a kind can only be deleted
  /// once there are none.
  int kindItemCount(String kindId) => _allItems.where((i) => i.cat == kindId).length;

  Iterable<ClothingItem> get _allItems => [
    ...items,
    for (final c in _stash.values) ...c.items,
  ];

  /// The outfit canvas: one card per slot. Shared by all wardrobes, like
  /// [kinds]; what each card shows is per session ([itemInSlot]).
  List<CanvasSlot> canvas = [];

  /// The slots shown — all of them, unless one's kind has gone missing.
  List<CanvasSlot> get visibleSlots =>
      canvas.where((s) => kindById(s.kindId) != null).toList();

  /// No room for another card (see [CanvasSlot.maxCount]).
  bool get canvasFull => visibleSlots.length >= CanvasSlot.maxCount;

  /// Which item each canvas slot shows, by slot id. Not persisted — every
  /// launch (and wardrobe switch) opens on a fresh random outfit.
  Map<String, String> _worn = {};

  CanvasSlot? slotById(String id) {
    for (final s in canvas) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// What [slotId]'s card shows — `null` for an empty card (its kind has no
  /// items to spare in this wardrobe).
  ClothingItem? itemInSlot(String slotId) {
    final slot = slotById(slotId);
    final it = itemById(_worn[slotId] ?? '');
    if (slot == null || it == null || it.cat != slot.kindId) return null;
    return it;
  }

  /// The visible slot [itemId] is worn in, if any.
  CanvasSlot? slotWearing(String itemId) {
    for (final s in visibleSlots) {
      if (itemInSlot(s.id)?.id == itemId) return s;
    }
    return null;
  }

  /// `null` follows the system/device locale; otherwise an explicit locale
  /// code like `'cs'` or `'en'` picked in settings.
  String? localeCode;

  /// `null` follows the system's light/dark setting; otherwise `'light'` or
  /// `'dark'` picked in settings (or onboarding).
  String? themeModeCode;

  /// The daily reminder to log the day's outfit in the diary: whether it's
  /// on, and when it comes, as minutes after midnight.
  bool reminderEnabled = false;
  int reminderMinutes = defaultReminderMinutes;
  static const defaultReminderMinutes = 20 * 60;

  ThemeMode get themeMode => switch (themeModeCode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// Whether the one-time onboarding screen has been completed. Checked by
  /// [main.dart] to decide what to show first.
  bool onboardingDone = false;

  /// Where the guided tour of the app (after onboarding) is: the step
  /// shown, or `null` once it's done or closed.
  int? tourStep;
  static const tourSteps = 5;

  /// When the app was first opened (or first opened since this was
  /// recorded), and when it last asked for a store rating — see
  /// [maybeAskForReview].
  DateTime? firstUsedAt;
  DateTime? reviewAskedAt;

  /// Went to the store to rate the app (from settings) — then the system
  /// popup isn't asked for any more.
  bool reviewRated = false;

  /// Whether [load] has finished at least once. Distinct from
  /// [onboardingDone] — this just guards against briefly showing onboarding
  /// (or the home screen) with pre-load default values before the real,
  /// persisted ones are in.
  bool loaded = false;

  String _toast = '';
  Timer? _toastTimer;
  String get toast => _toast;

  int _idSeq = 0;
  String _newId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  Future<void> load() async {
    Map<String, dynamic>? data;
    File? file;
    try {
      file = await _localFile();
      if (await file.exists()) {
        data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {
      // Unreadable state file — start from the empty defaults, but keep a
      // copy first: they're about to be saved over it.
      try {
        final f = file;
        if (f != null && await f.exists()) {
          await f.copy(p.join(f.parent.path, 'satnik_v1.unreadable-${DateTime.now().millisecondsSinceEpoch}.json'));
        }
      } catch (_) {}
    }

    var migrated = false;
    var fixed = false;
    if (data == null) {
      kinds = _defaultKinds();
      canvas = _defaultCanvas();
      final w = Wardrobe(id: _newWardrobeId(), name: _l10n.defaultWardrobeName);
      wardrobes = [w];
      _activate(w.id);
    } else {
      migrated = data['kinds'] == null;
      if (migrated && file != null) await _backUpBeforeKinds(file);
      // Outfits from collections, or saved before the canvas, are converted
      // as they're parsed (see SavedOutfit.legacyLayout); written back below.
      fixed = _outfitsNeedMigrating(data);
      await _loadFrom(data);
      fixed = _ensureTypes() || fixed;
    }

    final firstUse = firstUsedAt == null;
    firstUsedAt ??= DateTime.now();
    loaded = true;
    _applyFirstLaunchScreen();
    // A tour left unfinished picks up where it was.
    if (tourStep case final step? when step >= 0 && step < tourSteps) {
      _goToTourStep(step);
    } else {
      tourStep = null;
    }
    notifyListeners();
    // Write the migrated/fixed data right away, so it isn't redone (with
    // fresh type ids) on every launch until something else happens to save.
    if (migrated || fixed || firstUse) await _persist();
  }

  /// Whether saved outfits still need converting: kept in named
  /// collections, or saved before they had a canvas layout or an id. They
  /// get those as they're parsed; this says to write them back.
  static bool _outfitsNeedMigrating(Map<String, dynamic> data) {
    final wardrobes = data['wardrobes'];
    if (wardrobes is! List) return false;
    for (final w in wardrobes) {
      if (w is! Map) continue;
      if (w['outfits'] == null && w['saved'] != null) return true;
      for (final o in w['outfits'] as List? ?? const []) {
        if (o is Map && (o['slots'] == null || o['id'] == null)) return true;
      }
    }
    return false;
  }

  Future<void> _backUpBeforeKinds(File file) async {
    try {
      final backup = File(p.join(file.parent.path, _preKindsBackupName));
      if (!await backup.exists()) await file.copy(backup.path);
    } catch (_) {
      // A missing backup isn't worth failing the launch over.
    }
  }

  Future<void> _loadFrom(Map<String, dynamic> data) async {
    // Settings first — default names created below are in the user's
    // language.
    try {
      localeCode = data['localeCode'] as String?;
    } catch (_) {}
    try {
      themeModeCode = data['themeMode'] as String?;
    } catch (_) {}
    try {
      reminderEnabled = data['reminderEnabled'] as bool? ?? false;
      reminderMinutes = ((data['reminderMinutes'] as num?)?.toInt() ?? defaultReminderMinutes).clamp(0, 24 * 60 - 1);
    } catch (_) {}
    try {
      onboardingDone = data['onboardingDone'] as bool? ?? false;
      tourStep = (data['tourStep'] as num?)?.toInt();
    } catch (_) {}
    firstUsedAt = DateTime.tryParse('${data['firstUsedAt'] ?? ''}');
    reviewAskedAt = DateTime.tryParse('${data['reviewAskedAt'] ?? ''}');
    reviewRated = data['reviewRated'] == true;

    String? docsPath;
    try {
      docsPath = (await getApplicationDocumentsDirectory()).path;
    } catch (_) {}

    final rawWardrobes = [
      if (data['wardrobes'] case final List<dynamic> list)
        for (final e in list)
          if (e is Map<String, dynamic>) e,
    ];

    final rawKinds = data['kinds'];
    if (rawKinds is List) {
      kinds = [
        for (final e in rawKinds)
          if (e is Map<String, dynamic> && e['id'] is String) ClothingKind.fromJson(e),
      ];
      canvas = [
        for (final e in data['canvas'] as List<dynamic>? ?? const [])
          if (e is Map<String, dynamic>) ?_tryParseSlot(e),
      ];
    } else {
      _migrateToKinds(rawWardrobes, showDresses: data['showDresses'] as bool? ?? true);
      // _ensureTypes (after loading) files untyped items under "Other".
    }

    final parsed = <Wardrobe>[];
    for (final e in rawWardrobes) {
      // Never drop a wardrobe over a missing id/name — the next save would
      // then silently delete all of its content.
      final w = Wardrobe(
        id: e['id'] as String? ?? _newWardrobeId(),
        name: e['name'] as String? ?? _l10n.defaultWardrobeName,
      );
      parsed.add(w);
      _stash[w.id] = _WardrobeContent.fromJson(e, docsPath, newId: () => _newId('o'));
    }

    if (parsed.isEmpty) {
      parsed.add(Wardrobe(id: _newWardrobeId(), name: _l10n.defaultWardrobeName));
    }
    _ensureKindsForItems();

    wardrobes = parsed;
    final savedActive = data['activeWardrobeId'];
    _activate(
      parsed.any((w) => w.id == savedActive) ? savedActive as String : parsed.first.id,
    );
  }

  CanvasSlot? _tryParseSlot(Map<String, dynamic> json) {
    try {
      return CanvasSlot.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Turns the old fixed categories (`horni`, `saty`, `dolni`, `boty`) and
  /// their per-wardrobe folders into kinds with types, in the raw JSON
  /// before it's parsed: every folder used in any wardrobe becomes a type
  /// of its category's kind, and each item's folder name becomes that
  /// type's id. The old catch-all folder ("Nezařazené") is left out — its
  /// items end up under "Other" like any other untyped ones. Dresses only
  /// stay a kind if they were shown or someone has some.
  void _migrateToKinds(List<Map<String, dynamic>> rawWardrobes, {required bool showDresses}) {
    final hasDresses = rawWardrobes.any(
      (w) => (w['items'] as List<dynamic>? ?? const []).any((i) => i is Map && i['cat'] == 'saty'),
    );
    kinds = [
      for (final k in _defaultKinds(withTypes: false))
        if (k.id != 'saty' || showDresses || hasDresses) k,
    ];
    final unsorted = {
      lookupAppLocalizations(const Locale('cs')).unsortedName,
      lookupAppLocalizations(const Locale('en')).unsortedName,
    };

    String? typeIdFor(String cat, String? folder) {
      final name = folder?.trim() ?? '';
      if (name.isEmpty || unsorted.contains(name)) return null;
      var kind = kindById(cat);
      if (kind == null) {
        kind = ClothingKind(id: cat, name: cat);
        kinds.add(kind);
      }
      for (final t in kind.types) {
        if (t.name == name) return t.id;
      }
      final t = ClothingType(id: _newId('t'), name: name);
      kind.types.add(t);
      return t.id;
    }

    for (final w in rawWardrobes) {
      // Folders first, in the order they were arranged; then any folder an
      // item uses that somehow wasn't listed.
      if (w['knownFolders'] case final Map<String, dynamic> folders) {
        folders.forEach((cat, names) {
          if (names is! List) return;
          for (final n in names) {
            if (n is String) typeIdFor(cat, n);
          }
        });
      }
      for (final item in w['items'] as List<dynamic>? ?? const []) {
        if (item is! Map<String, dynamic> || item['cat'] is! String) continue;
        item['typeId'] = typeIdFor(item['cat'] as String, item['folder'] as String?);
        item.remove('folder');
      }
      w.remove('knownFolders');
    }
    canvas = _defaultCanvas();
  }

  /// An item whose kind is missing (a damaged file) gets a kind of its own
  /// rather than becoming unreachable.
  void _ensureKindsForItems() {
    for (final it in _allItems) {
      if (kindById(it.cat) == null) kinds.add(ClothingKind(id: it.cat, name: it.cat));
    }
  }

  /// Every item has a type and every kind at least one: a kind without
  /// types gets "Other", and so does any item without a (valid) type — e.g.
  /// one that was in the old catch-all folder. Returns whether anything
  /// changed.
  bool _ensureTypes() {
    var changed = false;
    for (final kind in kinds) {
      if (kind.types.isEmpty) {
        _otherType(kind);
        changed = true;
      }
    }
    for (final it in _allItems) {
      final kind = kindById(it.cat);
      if (kind == null || kind.typeById(it.typeId) != null) continue;
      it.typeId = _otherType(kind).id;
      changed = true;
    }
    return changed;
  }

  /// [kind]'s "Other" type, created (at the end) if it has none.
  ClothingType _otherType(ClothingKind kind) {
    final name = _l10n.otherTypeName;
    for (final t in kind.types) {
      if (t.name == name) return t;
    }
    final t = ClothingType(id: _newId('t'), name: name);
    kind.types = [...kind.types, t];
    return t;
  }

  /// The kinds a fresh install starts with — the four that used to be
  /// fixed categories — with a few common types each ([withTypes]).
  List<ClothingKind> _defaultKinds({bool withTypes = true}) {
    final l = _l10n;
    List<ClothingType> types(String csv) => [
      if (withTypes)
        for (final n in csv.split(','))
          if (n.trim().isNotEmpty) ClothingType(id: _newId('t'), name: n.trim()),
    ];
    return [
      ClothingKind(id: 'horni', name: l.categoryHorni, types: types(l.defaultTypesTop)),
      ClothingKind(id: 'saty', name: l.categorySaty, types: types(l.defaultTypesDress)),
      ClothingKind(id: 'dolni', name: l.categoryDolni, types: types(l.defaultTypesBottom)),
      ClothingKind(id: 'boty', name: l.categoryBoty, types: types(l.defaultTypesShoes)),
    ];
  }

  /// Top, bottom and shoes, laid out the way the outfit screen used to be.
  List<CanvasSlot> _defaultCanvas() => [
    CanvasSlot(id: _newId('s'), kindId: 'horni', x: 0.42, y: 0.22),
    CanvasSlot(id: _newId('s'), kindId: 'dolni', x: 0.56, y: 0.53),
    CanvasSlot(id: _newId('s'), kindId: 'boty', x: 0.40, y: 0.83, scale: 0.8),
  ];

  String _newWardrobeId() => 'w-${DateTime.now().microsecondsSinceEpoch}';

  _WardrobeContent get _liveContent => _WardrobeContent(
    items: items,
    outfits: outfits,
    diary: diary,
  );

  /// Makes [id] the active wardrobe: moves its content out of [_stash] into
  /// the live fields, and resets what the canvas shows (which refers to
  /// item ids from whichever wardrobe was active before). The previously
  /// active wardrobe must already have been stashed.
  void _activate(String id) {
    final c = _stash.remove(id) ?? _WardrobeContent.empty();
    activeWardrobeId = id;
    items = c.items;
    outfits = c.outfits;
    diary = c.diary;
    // Open on a random outfit, as if Shuffle had just been pressed — with
    // pinned garments already on their cards, since that's what Shuffle
    // keeps (otherwise a pin would sit on an item that isn't even showing).
    _worn = {};
    for (final it in items.where((i) => i.pinned)) {
      for (final s in visibleSlots) {
        if (s.kindId == it.cat && !_worn.containsKey(s.id)) {
          _worn[s.id] = it.id;
          break;
        }
      }
    }
    _shuffleSelection();
  }

  /// A brand-new wardrobe opens on the Wardrobe tab — there's nothing to
  /// build an outfit from yet, so the Outfit tab's empty cards are a worse
  /// landing spot than the wardrobe itself. Once there's at least one item,
  /// later launches land on the Outfit tab as usual.
  void _applyFirstLaunchScreen() {
    if (items.isEmpty) screen = WardrobeTabKind.wardrobe;
  }

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  /// Saves everything to disk. Saves are queued, one after another: two
  /// running at once would write the same temp file, and one could rename
  /// the other's half-written file into place. Each writes the state as it
  /// is when its turn comes, so a queued save never writes stale data.
  Future<void> _persist() {
    // Writing before load() has populated [wardrobes] would overwrite the
    // real file with an empty wardrobe list.
    if (!loaded) return Future.value();
    return _saving = _saving.then((_) => _write());
  }

  Future<void> _saving = Future.value();

  /// Everything that's saved, as written to the state file.
  Map<String, dynamic> get stateJson => {
    'version': _stateVersion,
    'kinds': kinds.map((k) => k.toJson()).toList(),
    'canvas': canvas.map((s) => s.toJson()).toList(),
    'wardrobes': [
      for (final w in wardrobes)
        {
          'id': w.id,
          'name': w.name,
          ...(w.id == activeWardrobeId
                  ? _liveContent
                  : _stash[w.id] ?? _WardrobeContent.empty())
              .toJson(),
        },
    ],
    'activeWardrobeId': activeWardrobeId,
    'localeCode': localeCode,
    'themeMode': themeModeCode,
    'reminderEnabled': reminderEnabled,
    'reminderMinutes': reminderMinutes,
    'onboardingDone': onboardingDone,
    'tourStep': ?tourStep,
    'firstUsedAt': ?firstUsedAt?.toIso8601String(),
    'reviewAskedAt': ?reviewAskedAt?.toIso8601String(),
    if (reviewRated) 'reviewRated': true,
  };

  Future<void> _write() async {
    try {
      final file = await _localFile();
      final data = stateJson;
      // Write to a temp file and rename over the real one, so a crash or
      // kill mid-write can never leave a half-written/corrupt state file.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(data));
      await tmp.rename(file.path);
    } catch (_) {
      // Best-effort persistence; nothing the UI can do about a write failure.
    }
  }

  /// For changes that come in bursts (dragging a card): saved once they
  /// settle.
  void _persistSoon() {
    _canvasPersistTimer?.cancel();
    _canvasPersistTimer = Timer(const Duration(milliseconds: 400), _persist);
  }

  Timer? _canvasPersistTimer;

  void setScreen(WardrobeTabKind s) {
    screen = s;
    notifyListeners();
  }

  void flash(String msg) {
    _toast = msg;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      _toast = '';
      notifyListeners();
    });
  }

  /// Id lookup, indexed — the outfits list resolves every item of every outfit
  /// on each rebuild. [items] is only ever replaced, never changed in
  /// place, so a new list instance is what invalidates the index.
  ClothingItem? itemById(String id) {
    if (!identical(_indexedItems, items)) {
      _itemIndex = {for (final i in items) i.id: i};
      _indexedItems = items;
    }
    return _itemIndex[id];
  }

  List<ClothingItem>? _indexedItems;
  Map<String, ClothingItem> _itemIndex = const {};

  // ---------------------------------------------------------------------
  // Kinds and types

  bool _isFreeKindName(String name, {String? except}) => name.isNotEmpty && !kindNameTaken(name, except: except);

  /// Whether another kind (not [except]) is already called [name].
  bool kindNameTaken(String name, {String? except}) => kinds.any((k) => k.id != except && k.name == name.trim());

  /// Whether another type of [kindId] (not [except]) is already called
  /// [name].
  bool typeNameTaken(String kindId, String name, {String? except}) =>
      kindById(kindId)?.types.any((t) => t.id != except && t.name == name.trim()) ?? false;

  /// Adds a new kind (a no-op for a blank or taken name), starting with
  /// a single "Other" type so clothing can be added to it right away.
  ClothingKind? addKind(String rawName) {
    final name = rawName.trim();
    if (!_isFreeKindName(name)) return null;
    final kind = ClothingKind(id: _newId('k'), name: name);
    _otherType(kind);
    kinds = [...kinds, kind];
    notifyListeners();
    _persist();
    return kind;
  }

  void renameKind(String kindId, String rawName) {
    final name = rawName.trim();
    final kind = kindById(kindId);
    if (kind == null || !_isFreeKindName(name, except: kindId)) return;
    kind.name = name;
    kinds = [...kinds];
    notifyListeners();
    _persist();
  }

  /// Moves the kind at [oldIndex] to [newIndex] (both in the list as it is
  /// before the move).
  void reorderKinds(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= kinds.length) return;
    final reordered = [...kinds];
    reordered.insert(newIndex.clamp(0, kinds.length - 1), reordered.removeAt(oldIndex));
    kinds = reordered;
    notifyListeners();
    _persist();
  }

  /// Deletes a kind along with its canvas cards — only once no wardrobe has
  /// any items of it; returns whether it was deleted.
  bool deleteKind(String kindId) {
    if (kindItemCount(kindId) > 0) return false;
    kinds = kinds.where((k) => k.id != kindId).toList();
    canvas = canvas.where((s) => s.kindId != kindId).toList();
    notifyListeners();
    _persist();
    return true;
  }

  /// Adds a type to [kindId] (a no-op for a blank or taken name there),
  /// returning it.
  ClothingType? addType(String kindId, String rawName) {
    final name = rawName.trim();
    final kind = kindById(kindId);
    if (kind == null || name.isEmpty || kind.types.any((t) => t.name == name)) return null;
    final type = ClothingType(id: _newId('t'), name: name);
    kind.types = [...kind.types, type];
    kinds = [...kinds];
    notifyListeners();
    _persist();
    return type;
  }

  void renameType(String kindId, String typeId, String rawName) {
    final name = rawName.trim();
    final kind = kindById(kindId);
    final type = kind?.typeById(typeId);
    if (kind == null || type == null || name.isEmpty) return;
    if (kind.types.any((t) => t.id != typeId && t.name == name)) return;
    type.name = name;
    kinds = [...kinds];
    notifyListeners();
    _persist();
  }

  /// How many items, in every wardrobe, are of type [typeId].
  int typeItemCount(String kindId, String typeId) =>
      _allItems.where((i) => i.cat == kindId && i.typeId == typeId).length;

  /// Deletes a type, moving its items (in every wardrobe) to [moveTo] — by
  /// default the kind's first other type. A kind's last type can't be
  /// deleted.
  void deleteType(String kindId, String typeId, {String? moveTo}) {
    final kind = kindById(kindId);
    if (kind == null || kind.types.length < 2 || kind.typeById(typeId) == null) return;
    final rest = kind.types.where((t) => t.id != typeId).toList();
    final target = rest.firstWhere((t) => t.id == moveTo, orElse: () => rest.first);
    kind.types = rest;
    kinds = [...kinds];
    for (final it in _allItems) {
      if (it.cat == kindId && it.typeId == typeId) it.typeId = target.id;
    }
    items = [...items];
    notifyListeners();
    _persist();
  }

  /// Moves [kindId]'s type at [oldIndex] to [newIndex].
  void reorderTypes(String kindId, int oldIndex, int newIndex) {
    final kind = kindById(kindId);
    if (kind == null || oldIndex < 0 || oldIndex >= kind.types.length) return;
    final reordered = [...kind.types];
    reordered.insert(newIndex.clamp(0, reordered.length - 1), reordered.removeAt(oldIndex));
    kind.types = reordered;
    kinds = [...kinds];
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------
  // Items

  /// Moves the item at [oldIndex] among [typeId]'s items (in this
  /// wardrobe, in the order they're shown) to [newIndex]. Items of other
  /// types keep their places.
  void reorderItemsInType(String kindId, String typeId, int oldIndex, int newIndex) {
    bool inType(ClothingItem it) => it.cat == kindId && it.typeId == typeId;
    final group = items.where(inType).toList();
    if (oldIndex < 0 || oldIndex >= group.length) return;
    group.insert(newIndex.clamp(0, group.length - 1), group.removeAt(oldIndex));
    var next = 0;
    items = [for (final it in items) inType(it) ? group[next++] : it];
    notifyListeners();
    _persist();
  }

  Future<String> _newImageCopy(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'satnik_images'));
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
    final ext = p.extension(sourcePath);
    final dest = p.join(
      imagesDir.path,
      '${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Adds one new item per path in [sourceImagePaths] (all of kind [kindId]
  /// and type [typeId] — the kind's first type if that isn't one of its) — e.g. picking several photos at once to add a
  /// handful of t-shirts in one go. A photo that fails to copy just leaves
  /// that one item photo-less rather than failing the whole batch; the
  /// count of such failures is reported back rather than flashed here,
  /// since composing user-facing text needs a [BuildContext].
  Future<({List<ClothingItem> items, int photoFailures})> addItems(
    String kindId,
    String typeId, {
    required List<String> sourceImagePaths,
  }) async {
    final kind = kindById(kindId);
    final type = kind?.typeById(typeId) ?? (kind == null ? null : kind.types.firstOrNull ?? _otherType(kind));
    final newItems = <ClothingItem>[];
    var photoFailures = 0;
    for (final sourcePath in sourceImagePaths) {
      String? imagePath;
      try {
        imagePath = await _newImageCopy(sourcePath);
      } catch (_) {
        // Keep the item usable even if the photo couldn't be saved — losing
        // the whole item over a storage hiccup is worse.
        photoFailures++;
      }
      newItems.add(
        ClothingItem(
          id: '$kindId-new-${DateTime.now().microsecondsSinceEpoch}-${newItems.length}',
          cat: kindId,
          typeId: type?.id,
          imagePath: imagePath,
        ),
      );
    }
    items = [...items, ...newItems];
    _fillEmptySlots();
    notifyListeners();
    await _persist();
    for (final it in newItems) {
      unawaited(ensureColors(it.id));
    }
    return (items: newItems, photoFailures: photoFailures);
  }

  /// Files an item under another kind and/or type.
  void moveItem(String itemId, String kindId, String typeId) {
    final it = itemById(itemId);
    final kind = kindById(kindId);
    final type = kind?.typeById(typeId);
    if (it == null || kind == null || type == null) return;
    it.cat = kindId;
    it.typeId = type.id;
    items = [...items];
    // A card of the old kind can't show it any more.
    _fillEmptySlots();
    _unpinUnworn();
    notifyListeners();
    _persist();
  }

  /// Sets whichever of an item's optional details are passed (a blank value
  /// clears it). Called on every keystroke, so saving to disk is debounced.
  void setItemInfo(
    String id, {
    String? name,
    String? seller,
    String? size,
    String? price,
    String? note,
  }) {
    final it = itemById(id);
    if (it == null) return;
    String? clean(String v) => v.trim().isEmpty ? null : v.trim();
    if (name != null) it.name = clean(name);
    if (seller != null) it.seller = clean(seller);
    if (size != null) it.size = clean(size);
    if (price != null) it.price = clean(price);
    if (note != null) it.note = clean(note);
    // Called on every keystroke; the detail sheet keeps its own text, so the
    // rest of the app (all three tabs stay alive) is told once typing pauses,
    // together with the save — not rebuilt per character.
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 600), () {
      notifyListeners();
      _persist();
    });
  }

  Timer? _persistTimer;

  final Set<String> _detectingColors = {};

  /// Detects a newly added item's colors from its photo.
  Future<void> ensureColors(String id) async {
    final it = itemById(id);
    if (it == null) return;
    if (await _detect(it)) await _persist();
  }

  /// Background pass after startup: detects colors for every item, in every
  /// wardrobe, that doesn't have them yet (e.g. added before detection
  /// existed). A few photos at a time, each analyzed off the UI isolate; a
  /// pass cut short by closing the app just continues next time.
  Future<void> detectMissingColors() async {
    final pending = _allItems.where((it) => it.colors == null && it.imagePath != null).toList();
    var next = 0, unsaved = 0;
    // A few photos at once (each analyzed in its own isolate), saving every
    // so often so an interrupted pass doesn't start over.
    Future<void> worker() async {
      while (next < pending.length) {
        final it = pending[next++];
        if (await _detect(it) && ++unsaved >= 10) {
          unsaved = 0;
          await _persist();
        }
      }
    }

    await Future.wait([for (var i = 0; i < _detectWorkers; i++) worker()]);
    if (unsaved > 0) await _persist();
  }

  static const _detectWorkers = 3;

  /// Sets [it]'s colors from its photo if it has none yet; true if it did.
  /// [it] may sit in another wardrobe, or be moved/deleted meanwhile — it's
  /// the same object either way, so setting the field is still right.
  Future<bool> _detect(ClothingItem it) async {
    final path = it.imagePath;
    if (path == null || it.colors != null || !_detectingColors.add(it.id)) return false;
    try {
      final colors = await detectGarmentColors(path);
      // The user may have picked colors by hand meanwhile — theirs win.
      if (it.colors != null) return false;
      it.colors = colors;
      if (identical(itemById(it.id), it)) notifyListeners();
      return true;
    } finally {
      _detectingColors.remove(it.id);
    }
  }

  /// The user's correction of an item's colors (1–3).
  void setItemColors(String id, List<int> colors) {
    final it = itemById(id);
    if (it == null) return;
    it.colors = List.unmodifiable(colors);
    notifyListeners();
    _persist();
  }

  /// Throws away the item's colors and detects them again from the photo.
  Future<void> redetectColors(String id) async {
    final it = itemById(id);
    if (it == null || it.imagePath == null) return;
    it.colors = null;
    notifyListeners();
    if (await _detect(it)) await _persist();
  }

  void togglePinned(String id) {
    items = items
        .map((i) => i.id == id ? (i..pinned = !i.pinned) : i)
        .toList();
    notifyListeners();
    _persist();
  }

  Future<void> deleteItem(ClothingItem it) async {
    items = items.where((x) => x.id != it.id).toList();
    _fillEmptySlots();
    notifyListeners();
    await _persist();
    await _deleteImageFile(it.imagePath);
  }

  // ---------------------------------------------------------------------
  // Outfit canvas

  /// Adds a card of [kindId] — at [x], [y] if given, otherwise wherever
  /// there's the most room — showing [itemId] or, by default, a random
  /// item of that kind not on the canvas yet. Returns the new slot, or null
  /// if the canvas already has [CanvasSlot.maxCount] cards.
  CanvasSlot? addSlot(String kindId, {String? itemId, double? x, double? y, double scale = 1}) {
    if (canvasFull) return null;
    final spot = x != null && y != null ? (x: x, y: y) : _freeSpot();
    final slot = CanvasSlot(id: _newId('s'), kindId: kindId, x: spot.x, y: spot.y, scale: scale);
    canvas = [...canvas, slot];
    if (itemId != null) {
      _wearIn(slot, itemId);
    } else {
      _fillEmptySlots();
    }
    notifyListeners();
    _persist();
    return slot;
  }

  /// The point on the canvas farthest from every card's center, out of a
  /// grid of candidates — where a new card overlaps the least.
  ({double x, double y}) _freeSpot() {
    final taken = visibleSlots;
    if (taken.isEmpty) return (x: 0.5, y: 0.45);
    var best = (x: 0.5, y: 0.5);
    var bestDistance = -1.0;
    for (var gy = 0; gy < 5; gy++) {
      for (var gx = 0; gx < 4; gx++) {
        final c = (x: 0.2 + gx * 0.2, y: 0.14 + gy * 0.18);
        final d = taken
            .map((s) => pow(s.x - c.x, 2) + pow((s.y - c.y) * 0.8, 2))
            .reduce(min)
            .toDouble();
        if (d > bestDistance) {
          bestDistance = d;
          best = c;
        }
      }
    }
    return best;
  }

  void removeSlot(String slotId) {
    canvas = canvas.where((s) => s.id != slotId).toList();
    _worn.remove(slotId);
    _unpinUnworn();
    notifyListeners();
    _persist();
  }

  /// Drags a card: its center to [x], [y] (fractions of the canvas).
  void moveSlot(String slotId, double x, double y) {
    final slot = slotById(slotId);
    if (slot == null) return;
    slot.x = x.clamp(0.0, 1.0);
    slot.y = y.clamp(0.0, 1.0);
    // Brought to the front, like picking up a photo from a pile.
    canvas = [...canvas.where((s) => s.id != slotId), slot];
    notifyListeners();
    _persistSoon();
  }

  void scaleSlot(String slotId, double scale) {
    final slot = slotById(slotId);
    if (slot == null) return;
    slot.scale = scale.clamp(CanvasSlot.minScale, CanvasSlot.maxScale);
    canvas = [...canvas];
    notifyListeners();
    _persistSoon();
  }

  /// Puts [itemId] on [slotId]'s card. If it's already on another card,
  /// the two cards swap — a garment can't be worn twice.
  void setSlotItem(String slotId, String itemId) {
    final slot = slotById(slotId);
    // Only an item of the card's kind (e.g. one added from the card's pick
    // sheet, but then filed under another kind, doesn't go on it).
    if (slot == null || itemById(itemId)?.cat != slot.kindId) return;
    final pinMoved = _wearIn(slot, itemId);
    notifyListeners();
    if (pinMoved) _persist();
  }

  bool _wearIn(CanvasSlot slot, String itemId) {
    final current = itemInSlot(slot.id);
    final other = slotWearing(itemId);
    if (other != null && other.id != slot.id) {
      if (current != null) {
        _worn[other.id] = current.id;
      } else {
        _worn.remove(other.id);
      }
    }
    _worn[slot.id] = itemId;
    if (other != null) return false;
    return _transferPin(current, itemById(itemId));
  }

  /// A pin keeps an item on its card through Shuffle — so one that's no
  /// longer on any card (its card removed, another outfit loaded, the item
  /// moved to another kind) loses it, rather than turning up locked on some
  /// card later.
  void _unpinUnworn() {
    final worn = {for (final s in visibleSlots) ?itemInSlot(s.id)?.id};
    if (!items.any((i) => i.pinned && !worn.contains(i.id))) return;
    items = [for (final i in items) i.pinned && !worn.contains(i.id) ? (i..pinned = false) : i];
  }

  /// If [oldItem] was pinned, moves the pin onto [newItem] instead of
  /// leaving it stuck on an item that's no longer shown there. Manually
  /// swapping what's on a pinned card should keep the card "locked" to
  /// whatever you just picked — not drop the lock, and not leave the old
  /// item pinned somewhere it might resurface later and unexpectedly resist
  /// shuffling. Returns whether anything actually changed (so callers know
  /// whether they need to persist).
  bool _transferPin(ClothingItem? oldItem, ClothingItem? newItem) {
    if (oldItem == null || !oldItem.pinned || oldItem.id == newItem?.id) {
      return false;
    }
    items = items.map((i) {
      if (i.id == oldItem.id) return i..pinned = false;
      if (newItem != null && i.id == newItem.id) return i..pinned = true;
      return i;
    }).toList();
    return true;
  }

  /// Randomizes every card — except any whose item is [ClothingItem.pinned],
  /// which is left exactly as it is. No garment ends up on two cards.
  void shuffle() {
    _shuffleSelection();
    notifyListeners();
  }

  void _shuffleSelection() {
    final rng = Random();
    final slots = visibleSlots;
    final used = <String>{};
    final keep = <String>{};
    for (final s in slots) {
      final it = itemInSlot(s.id);
      if (it != null && it.pinned && used.add(it.id)) keep.add(s.id);
    }
    for (final s in slots) {
      if (keep.contains(s.id)) continue;
      final pool = itemsOfKind(s.kindId).where((i) => !used.contains(i.id)).toList();
      if (pool.isEmpty) {
        _worn.remove(s.id);
        continue;
      }
      final picked = pool[rng.nextInt(pool.length)];
      used.add(picked.id);
      _worn[s.id] = picked.id;
    }
  }

  /// Gives every empty card (or one showing an item that's gone or changed
  /// kind) a random item of its kind that isn't on another card.
  void _fillEmptySlots() {
    final rng = Random();
    final slots = visibleSlots;
    final used = {for (final s in slots) ?itemInSlot(s.id)?.id};
    for (final s in slots) {
      if (itemInSlot(s.id) != null) continue;
      final pool = itemsOfKind(s.kindId).where((i) => !used.contains(i.id)).toList();
      if (pool.isEmpty) {
        _worn.remove(s.id);
        continue;
      }
      final picked = pool[rng.nextInt(pool.length)];
      used.add(picked.id);
      _worn[s.id] = picked.id;
    }
  }

  // ---------------------------------------------------------------------
  // Saved outfits

  Future<void> _deleteImageFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort cleanup — a stray photo file left behind is harmless.
    }
  }

  /// Moves the outfit at [oldIndex] to [newIndex], counted as the
  /// collection shows them: newest first.
  void reorderOutfits(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= outfits.length) return;
    final shown = outfits.reversed.toList();
    shown.insert(newIndex.clamp(0, shown.length - 1), shown.removeAt(oldIndex));
    outfits = shown.reversed.toList();
    notifyListeners();
    _persist();
  }

  void toggleFavorite(String outfitId) {
    for (final o in outfits) {
      if (o.id == outfitId) o.favorite = !o.favorite;
    }
    outfits = [...outfits];
    notifyListeners();
    _persist();
  }

  Future<void> deleteOutfit(String outfitId) async {
    outfits = outfits.where((o) => o.id != outfitId).toList();
    notifyListeners();
    await _persist();
  }

  /// The days [o] was worn: those the diary has exactly its items (layout
  /// aside), in any entry.
  Set<DateTime> outfitWearDays(SavedOutfit o) {
    final key = _itemsKey(o.itemIds);
    return {for (final e in diary) if (_itemsKey(e.itemIds) == key) e.day};
  }

  /// For every saved outfit worn at least once — on a day the diary has
  /// exactly its items (layout aside) — on how many days, and the last one.
  Map<String, ({int count, DateTime last})> get outfitWearStats {
    final byItems = <String, Set<DateTime>>{};
    for (final e in diary) {
      (byItems[_itemsKey(e.itemIds)] ??= {}).add(e.day);
    }
    return {
      for (final o in outfits)
        if (byItems[_itemsKey(o.itemIds)] case final days?)
          o.id: (count: days.length, last: days.reduce((a, b) => a.isAfter(b) ? a : b)),
    };
  }

  static String _itemsKey(Iterable<String> ids) => (ids.toSet().toList()..sort()).join('|');

  /// What the canvas shows, top to bottom — what [saveOutfit] stores.
  List<ClothingItem> get currentOutfitItems {
    final slots = visibleSlots..sort((a, b) => a.y.compareTo(b.y));
    return [for (final s in slots) ?itemInSlot(s.id)];
  }

  /// A saved outfit made of exactly the current outfit's items (layout
  /// aside), looked for in the active wardrobe first, then the others: an
  /// item moved between wardrobes keeps its id, so the same combination can
  /// be saved elsewhere too.
  ({String wardrobe, bool here})? findSavedCopyOfCurrentOutfit() {
    final ids = currentOutfitItems.map((i) => i.id).toSet();
    if (ids.isEmpty) return null;
    final ordered = [
      ...wardrobes.where((w) => w.id == activeWardrobeId),
      ...wardrobes.where((w) => w.id != activeWardrobeId),
    ];
    for (final w in ordered) {
      final content = w.id == activeWardrobeId ? _liveContent : _stash[w.id];
      if (content == null) continue;
      for (final o in content.outfits) {
        final other = o.itemIds.toSet();
        if (other.length == ids.length && other.containsAll(ids)) {
          return (wardrobe: w.name, here: w.id == activeWardrobeId);
        }
      }
    }
    return null;
  }

  /// The outfit in this wardrobe that's the same combination as the canvas
  /// shows now, if it's been saved.
  SavedOutfit? get savedCanvasOutfit {
    final ids = currentOutfitItems.map((i) => i.id).toSet();
    if (ids.isEmpty) return null;
    for (final o in outfits) {
      final other = o.itemIds.toSet();
      if (other.length == ids.length && other.containsAll(ids)) return o;
    }
    return null;
  }

  /// Saves the current outfit, canvas layout included — unless the canvas
  /// shows no clothes; returns whether it saved.
  Future<bool> saveOutfit() async {
    final parts = currentOutfitItems;
    if (parts.isEmpty) return false;
    outfits = [
      ...outfits,
      SavedOutfit(
        id: _newId('o'),
        catKeys: parts.map((i) => i.cat).toList(),
        itemIds: parts.map((i) => i.id).toList(),
        slots: _canvasSnapshot(),
      ),
    ];
    notifyListeners();
    await _persist();
    maybeAskForReview();
    return true;
  }

  /// The canvas as it is now, for saving or the diary.
  List<SavedSlot> _canvasSnapshot() => [
    for (final s in visibleSlots)
      SavedSlot(id: s.id, kindId: s.kindId, x: s.x, y: s.y, scale: s.scale, itemId: itemInSlot(s.id)?.id),
  ];

  /// Puts a saved outfit on the canvas, laid out as it was saved.
  void loadOutfit(SavedOutfit o) => _loadSlots(o.slots);

  /// Puts an outfit from the diary on the canvas, laid out as it was.
  void loadDiaryEntry(DiaryEntry e) => _loadSlots(e.slots);

  void _loadSlots(List<SavedSlot> slots) {
    _worn = {};
    final restored = <CanvasSlot>[];
    for (final ss in slots) {
      if (kindById(ss.kindId) == null) continue;
      final slot = CanvasSlot(
        // Its own id again (unless taken), so it's tilted as it was.
        id: restored.any((r) => r.id == ss.id) ? _newId('s') : ss.id,
        kindId: ss.kindId,
        x: ss.x.clamp(0.0, 1.0),
        y: ss.y.clamp(0.0, 1.0),
        scale: ss.scale.clamp(CanvasSlot.minScale, CanvasSlot.maxScale),
      );
      restored.add(slot);
      if (ss.itemId != null) _worn[slot.id] = ss.itemId!;
    }
    canvas = restored;
    _fillEmptySlots();
    _unpinUnworn();
    screen = WardrobeTabKind.outfit;
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------
  // Diary

  /// The outfits written down for [day], in the order they were.
  List<DiaryEntry> diaryOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return diary.where((e) => e.day == d).toList();
  }

  /// Writes down what's on the canvas now as worn on [day]. Returns false
  /// (and writes nothing) when the canvas shows no clothes.
  bool logCanvas(DateTime day) {
    final slots = _canvasSnapshot();
    if (!slots.any((s) => s.itemId != null)) return false;
    _addDiaryEntry(day, slots);
    return true;
  }

  /// Writes down a saved outfit as worn on [day] — unless none of its
  /// clothes are left; returns whether it did.
  bool logSavedOutfit(DateTime day, SavedOutfit o) {
    if (!o.itemIds.any((id) => itemById(id) != null)) return false;
    _addDiaryEntry(day, o.slots);
    return true;
  }

  void _addDiaryEntry(DateTime day, List<SavedSlot> slots) {
    final entry = DiaryEntry(id: _newId('d'), day: day, loggedAt: DateTime.now(), slots: slots);
    diary = [...diary, entry]..sort(DiaryEntry.byDay);
    notifyListeners();
    _persist();
    maybeAskForReview();
  }

  // ---------------------------------------------------------------------
  // Store rating

  /// Outfits saved and written down, in every wardrobe, before the app asks
  /// for a rating — someone who got this far has something to rate.
  static const reviewAfterMoments = 5;
  static const reviewAfterDays = 3;

  /// Asked again at most this often (the platform caps it further).
  static const reviewEvery = Duration(days: 120);

  /// Outfits saved plus diary entries, across wardrobes.
  int get reviewMoments => wardrobeSummaries.fold(0, (n, w) => n + w.outfits + w.diary);

  /// Whether this is a good moment to ask for a rating: right after saving
  /// or logging an outfit, once the app has been in use a few days and a
  /// few outfits in, the tour is over, and it hasn't asked lately (or been
  /// rated already).
  bool get shouldAskForReview {
    final now = DateTime.now();
    final first = firstUsedAt;
    final asked = reviewAskedAt;
    return !reviewRated &&
        onboardingDone &&
        tourStep == null &&
        first != null &&
        now.difference(first) >= const Duration(days: reviewAfterDays) &&
        reviewMoments >= reviewAfterMoments &&
        (asked == null || now.difference(asked) >= reviewEvery);
  }

  /// Asks for the system's rating popup if [shouldAskForReview] — a moment
  /// later, once the sheet that saved the outfit has closed.
  void maybeAskForReview() {
    if (!shouldAskForReview) return;
    reviewAskedAt = DateTime.now();
    _persist();
    Timer(const Duration(milliseconds: 1200), ReviewPrompt.request);
  }

  /// Went to the store to rate the app — no more asking.
  void markRated() {
    reviewRated = true;
    _persist();
  }

  /// Forgets that it asked (and any rating), so it can ask again (debug
  /// screen).
  void resetReviewPrompt() {
    reviewAskedAt = null;
    reviewRated = false;
    notifyListeners();
    _persist();
  }

  void deleteDiaryEntry(String id) {
    diary = diary.where((e) => e.id != id).toList();
    notifyListeners();
    _persist();
  }

  /// How many days of [month] (any day in it) have something written down.
  int daysLoggedIn(DateTime month) =>
      diary.where((e) => e.day.year == month.year && e.day.month == month.month).map((e) => e.day).toSet().length;

  /// Ids of the items worn at least once in [month].
  Set<String> itemsWornIn(DateTime month) => {
    for (final e in diary)
      if (e.day.year == month.year && e.day.month == month.month) ...e.itemIds,
  };

  /// Which items were worn on each day of [month] (each item once a day).
  Map<DateTime, Set<String>> _wornByDay(DateTime month) {
    final days = <DateTime, Set<String>>{};
    for (final e in diary) {
      if (e.day.year == month.year && e.day.month == month.month) (days[e.day] ??= {}).addAll(e.itemIds);
    }
    return days;
  }

  /// How many items of the active wardrobe are of each color (their main
  /// detected color); items without colors aren't counted.
  Map<ColorFamily, int> get wardrobeColors {
    final counts = <ColorFamily, int>{};
    for (final it in items) {
      final c = it.colors;
      if (c != null && c.isNotEmpty) counts.update(ColorFamily.of(c.first), (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  /// How often each color was worn in [month]: every day an item was worn
  /// counts once, for its main color.
  Map<ColorFamily, int> wornColorsIn(DateTime month) {
    final counts = <ColorFamily, int>{};
    for (final ids in _wornByDay(month).values) {
      for (final id in ids) {
        final c = itemById(id)?.colors;
        if (c != null && c.isNotEmpty) counts.update(ColorFamily.of(c.first), (n) => n + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }

  /// Up to three colors worn the most on [day], by the main color of each
  /// item (top to bottom, so ties go to what was higher up).
  List<ColorFamily> dayColors(DateTime day) => topColors([for (final e in diaryOn(day)) e.slots]);

  /// Up to three colors most common across [canvases] (an outfit, or a
  /// day's), by the main color of each item; ties go to what's higher up.
  List<ColorFamily> topColors(Iterable<List<SavedSlot>> canvases) {
    final counts = <ColorFamily, int>{};
    for (final canvas in canvases) {
      final slots = [...canvas]..sort((a, b) => a.y.compareTo(b.y));
      for (final s in slots) {
        final c = s.itemId == null ? null : itemById(s.itemId!)?.colors;
        if (c == null || c.isEmpty) continue;
        counts.update(ColorFamily.of(c.first), (n) => n + 1, ifAbsent: () => 1);
      }
    }
    // Ties go to the color that showed up first (map keys keep that order).
    final order = counts.keys.toList();
    final ranked = [...order]
      ..sort((a, b) => counts[b] != counts[a] ? counts[b]!.compareTo(counts[a]!) : order.indexOf(a).compareTo(order.indexOf(b)));
    return ranked.take(3).toList();
  }

  /// The days of [month] (day numbers) [itemId] was worn on.
  Set<int> daysWornIn(String itemId, DateTime month) => {
    for (final e in diary)
      if (e.day.year == month.year && e.day.month == month.month && e.itemIds.contains(itemId)) e.day.day,
  };

  /// For every item worn at least once: on how many days, and the last one.
  /// Two outfits with the same item on one day count as one wear.
  Map<String, ({int count, DateTime last})> get wearStats {
    final days = <String, Set<DateTime>>{};
    for (final e in diary) {
      for (final id in e.itemIds) {
        (days[id] ??= {}).add(e.day);
      }
    }
    return {
      for (final MapEntry(:key, :value) in days.entries)
        key: (count: value.length, last: value.reduce((a, b) => a.isAfter(b) ? a : b)),
    };
  }

  // ---------------------------------------------------------------------
  // Debug tools (the hidden debug screen)

  /// Where the state file, photos and backups live.
  Future<Directory> dataDirectory() => getApplicationDocumentsDirectory();

  /// Item, saved-outfit and diary counts of every wardrobe.
  List<({String name, bool active, int items, int outfits, int diary})> get wardrobeSummaries => [
    for (final w in wardrobes)
      if (w.id == activeWardrobeId ? _liveContent : _stash[w.id] case final c?)
        (name: w.name, active: w.id == activeWardrobeId, items: c.items.length, outfits: c.outfits.length, diary: c.diary.length),
  ];

  /// Items (in any wardrobe) whose photo file is gone.
  Future<int> missingPhotoCount() async {
    var n = 0;
    for (final it in _allItems) {
      final path = it.imagePath;
      if (path != null && !await File(path).exists()) n++;
    }
    return n;
  }

  /// Files in the photos folder no item (in any wardrobe) points to.
  Future<List<File>> orphanPhotos() async {
    final dir = Directory(p.join((await dataDirectory()).path, 'satnik_images'));
    if (!await dir.exists()) return [];
    final used = {for (final it in _allItems) ?it.imagePath};
    return [
      await for (final f in dir.list())
        if (f is File && !used.contains(f.path)) f,
    ];
  }

  /// Deletes [orphanPhotos]; how many it deleted.
  Future<int> deleteOrphanPhotos() async {
    var n = 0;
    for (final f in await orphanPhotos()) {
      try {
        await f.delete();
        n++;
      } catch (_) {}
    }
    return n;
  }

  /// Forgets every item's colors (corrected ones too) and detects them all
  /// again.
  Future<void> redetectAllColors() async {
    for (final it in _allItems) {
      it.colors = null;
    }
    items = [...items];
    notifyListeners();
    await detectMissingColors();
  }

  /// Empties the active wardrobe's diary.
  void clearDiary() {
    diary = [];
    notifyListeners();
    _persist();
  }

  /// Shows onboarding again on the next frame (the data stays).
  void resetOnboarding() {
    onboardingDone = false;
    tourStep = null;
    notifyListeners();
    _persist();
  }

  /// Old-format copies kept by migrations, next to the state file.
  Future<List<File>> migrationBackups() async {
    final dir = await dataDirectory();
    return [
      await for (final f in dir.list())
        if (f is File && p.basename(f.path).startsWith('satnik_v1.') && p.basename(f.path) != _fileName && f.path.endsWith('.json')) f,
    ];
  }

  /// Deletes everything — state file, photos, backups — and starts over as
  /// a fresh install (onboarding included).
  Future<void> eraseEverything() async {
    // No more saves: the one queued would bring the file back.
    loaded = false;
    await _saving;
    final dir = await dataDirectory();
    for (final name in [_fileName, '$_fileName.tmp']) {
      try {
        await File(p.join(dir.path, name)).delete();
      } catch (_) {}
    }
    for (final f in await migrationBackups()) {
      try {
        await f.delete();
      } catch (_) {}
    }
    try {
      await Directory(p.join(dir.path, 'satnik_images')).delete(recursive: true);
    } catch (_) {}
    _forgetAll();
    await load();
  }

  /// Back to the in-memory state of a fresh install, before [load] reads
  /// the state file (whatever it now holds) again.
  void _forgetAll() {
    wardrobes = [];
    _stash.clear();
    // The live wardrobe's content too: load() looks at every item (e.g. for
    // kinds they need) before it activates a wardrobe of its own.
    items = [];
    outfits = [];
    diary = [];
    localeCode = null;
    themeModeCode = null;
    reminderEnabled = false;
    reminderMinutes = defaultReminderMinutes;
    onboardingDone = false;
    tourStep = null;
    firstUsedAt = null;
    reviewAskedAt = null;
    reviewRated = false;
    screen = WardrobeTabKind.outfit;
  }

  // ---------------------------------------------------------------------
  // Export and import

  static const _imagesDir = 'satnik_images';

  /// Everything — the state and every photo an item uses — as one zip in
  /// the temp folder, ready to share. Inside: `satnik_v1.json` and
  /// `satnik_images/…`, laid out as in the app's own folder.
  Future<File> exportArchive() async {
    final tmp = await getTemporaryDirectory();
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final zip = File(p.join(tmp.path, 'Outfits ${now.year}-${two(now.month)}-${two(now.day)}.zip'));
    final state = File(p.join(tmp.path, _fileName));
    await state.writeAsString(jsonEncode(stateJson));
    final encoder = ZipFileEncoder()..create(zip.path);
    try {
      await encoder.addFile(state, _fileName);
      for (final path in {for (final it in _allItems) ?it.imagePath}) {
        final photo = File(path);
        if (await photo.exists()) await encoder.addFile(photo, '$_imagesDir/${p.basename(path)}');
      }
    } finally {
      await encoder.close();
      try {
        await state.delete();
      } catch (_) {}
    }
    return zip;
  }

  /// Reads the zip at [zipPath] (made by [exportArchive], here or on
  /// another device) and checks it's a backup this version can import —
  /// without changing anything yet. Either a [Backup] or why not.
  static Future<(Backup?, ImportResult)> openArchive(String zipPath) async {
    try {
      final archive = ZipDecoder().decodeStream(InputFileStream(zipPath));
      final state = archive.findFile(_fileName);
      if (state == null) return (null, ImportResult.notABackup);
      final data = jsonDecode(utf8.decode(state.content)) as Map<String, dynamic>;
      if (data['wardrobes'] is! List) return (null, ImportResult.notABackup);
      if (((data['version'] as num?) ?? 0) > _stateVersion) return (null, ImportResult.newerVersion);
      return (Backup._(archive, data), ImportResult.done);
    } catch (_) {
      return (null, ImportResult.notABackup);
    }
  }

  /// Replaces everything in the app with [backup]. Unpacked beside the
  /// current data first and only then swapped in, so a failure leaves the
  /// app as it was.
  Future<ImportResult> importArchive(Backup backup) async {
    final archive = backup._archive;
    final data = backup._data;

    final dir = await dataDirectory();
    final staging = Directory(p.join(dir.path, 'import.tmp'));
    final images = Directory(p.join(dir.path, _imagesDir));
    final oldImages = Directory(p.join(dir.path, '$_imagesDir.old'));
    final state = File(p.join(dir.path, _fileName));
    final oldState = File('${state.path}.old');
    Future<void> remove(FileSystemEntity e) async {
      try {
        if (await e.exists()) await e.delete(recursive: true);
      } catch (_) {}
    }

    try {
      await remove(staging);
      await Directory(p.join(staging.path, _imagesDir)).create(recursive: true);
      for (final f in archive.files) {
        if (!f.isFile) continue;
        // Only photos straight inside the photos folder — nothing that
        // could land outside it.
        final parts = p.posix.split(f.name);
        if (parts.length != 2 || parts[0] != _imagesDir || parts[1].startsWith('.')) continue;
        await File(p.join(staging.path, _imagesDir, parts[1])).writeAsBytes(f.content);
      }
      await File(p.join(staging.path, _fileName)).writeAsString(jsonEncode(data));
    } catch (_) {
      await remove(staging);
      return ImportResult.failed;
    }

    // Whatever was waiting to be saved goes to disk now (the old data is
    // what comes back if the import fails); then no more saves, which would
    // land on top of the imported file.
    _canvasPersistTimer?.cancel();
    _persistTimer?.cancel();
    await _persist();
    loaded = false;
    await _saving;
    // Each step's undo, in order — only for the steps that happened.
    final undo = <Future<void> Function()>[];
    Future<void> rollBack() async {
      for (final step in undo.reversed) {
        try {
          await step();
        } catch (_) {}
      }
      await remove(staging);
    }

    try {
      await remove(oldImages);
      await remove(oldState);
      if (await oldImages.exists() || await oldState.exists()) throw const FileSystemException('leftover backup');
      if (await images.exists()) {
        await images.rename(oldImages.path);
        undo.add(() => oldImages.rename(images.path));
      }
      if (await state.exists()) {
        await state.rename(oldState.path);
        undo.add(() => oldState.rename(state.path));
      }
      await Directory(p.join(staging.path, _imagesDir)).rename(images.path);
      undo.add(() => remove(images));
      await File(p.join(staging.path, _fileName)).rename(state.path);
      undo.add(() => remove(state));
      // Only a backup that actually loads replaces the old data; one that
      // doesn't (damaged or hand-edited) brings the old data back.
      _forgetAll();
      await load();
    } catch (_) {
      await rollBack();
      _forgetAll();
      await load();
      return ImportResult.failed;
    }
    await remove(staging);
    await remove(oldImages);
    await remove(oldState);
    detectMissingColors();
    return ImportResult.done;
  }

  // ---------------------------------------------------------------------
  // Settings and wardrobes

  void setLocale(String? code) {
    final before = _l10n;
    localeCode = code;
    // Still setting up a fresh install: the default kinds, types and
    // wardrobe name were made in the phone's language — remake them in the
    // one just picked.
    if (!onboardingDone && _allItems.isEmpty && before.localeName != _l10n.localeName) {
      kinds = _defaultKinds();
      canvas = _defaultCanvas();
      _worn = {};
      for (final w in wardrobes) {
        if (w.name == before.defaultWardrobeName) w.name = _l10n.defaultWardrobeName;
      }
    }
    notifyListeners();
    _persist();
  }

  void setReminder({bool? enabled, int? minutes}) {
    if (enabled != null) reminderEnabled = enabled;
    if (minutes != null) reminderMinutes = minutes.clamp(0, 24 * 60 - 1);
    notifyListeners();
    _persist();
  }

  /// Whether anything is written down for today, in any wardrobe's diary
  /// — the reminder is about the person, not the wardrobe.
  bool get loggedToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [...diary, for (final c in _stash.values) ...c.diary].any((e) => e.day == today);
  }

  void setThemeMode(String? code) {
    themeModeCode = code;
    notifyListeners();
    _persist();
  }

  /// [wardrobeName] names the (so far only) wardrobe; blank keeps the
  /// default name it was created with.
  /// Starts the tour of the app on its first step's tab.
  void completeOnboarding({String? wardrobeName}) {
    final name = wardrobeName?.trim() ?? '';
    if (name.isNotEmpty) activeWardrobe.name = name;
    onboardingDone = true;
    _goToTourStep(0);
    notifyListeners();
    _persist();
  }

  /// The tab each tour step is about.
  static const _tourTabs = [
    WardrobeTabKind.wardrobe,
    WardrobeTabKind.outfit,
    WardrobeTabKind.outfits,
    WardrobeTabKind.diary,
    // Settings: on whichever tab, it's the gear up top.
    WardrobeTabKind.diary,
  ];

  /// Moves the tour on — or ends it after the last step.
  void nextTourStep() {
    final step = tourStep;
    if (step == null) return;
    if (step + 1 >= tourSteps) {
      endTour();
      return;
    }
    _goToTourStep(step + 1);
    notifyListeners();
    _persist();
  }

  void endTour() {
    tourStep = null;
    notifyListeners();
    _persist();
  }

  /// Ends the tour from its last step (settings): back to the canvas, to
  /// start dressing.
  void finishTour() {
    tourStep = null;
    screen = WardrobeTabKind.outfit;
    notifyListeners();
    _persist();
  }

  void _goToTourStep(int step) {
    tourStep = step;
    screen = _tourTabs[step];
  }

  /// Keeps only these of the kinds (onboarding): the rest are deleted —
  /// unless something is already filed under them.
  void keepOnlyKinds(Set<String> kindIds) {
    for (final k in [...kinds]) {
      if (!kindIds.contains(k.id)) deleteKind(k.id);
    }
  }

  bool _isFreeWardrobeName(String name, {String? except}) =>
      name.isNotEmpty && !wardrobeNameTaken(name, except: except);

  /// Whether another wardrobe (not [except]) is already called [name].
  bool wardrobeNameTaken(String name, {String? except}) =>
      wardrobes.any((w) => w.id != except && w.name == name.trim());

  /// Creates a new, empty wardrobe and switches to it (a no-op for a blank
  /// or already-taken name).
  Future<void> addWardrobe(String rawName) async {
    final name = rawName.trim();
    if (!_isFreeWardrobeName(name)) return;
    final w = Wardrobe(id: _newWardrobeId(), name: name);
    _stash[activeWardrobeId] = _liveContent;
    wardrobes = [...wardrobes, w];
    _activate(w.id);
    notifyListeners();
    await _persist();
  }

  Future<void> switchWardrobe(String id) async {
    if (id == activeWardrobeId || !wardrobes.any((w) => w.id == id)) return;
    _stash[activeWardrobeId] = _liveContent;
    // Stays on the tab it's on, even for an empty wardrobe.
    _activate(id);
    notifyListeners();
    await _persist();
  }

  Future<void> renameWardrobe(String id, String rawName) async {
    final name = rawName.trim();
    if (!_isFreeWardrobeName(name, except: id)) return;
    for (final w in wardrobes) {
      if (w.id == id) w.name = name;
    }
    wardrobes = [...wardrobes];
    notifyListeners();
    await _persist();
  }

  /// Moves an item from the active wardrobe into another one, photo, kind,
  /// type and details included (kinds and types are shared by every
  /// wardrobe). The pin doesn't come along: it belonged to this wardrobe's
  /// outfit. Outfits saved here simply stop showing it (as with a deleted
  /// item); its id is unchanged, so they pick it back up if it's ever moved
  /// back.
  Future<void> moveItemToWardrobe(String itemId, String targetWardrobeId) async {
    if (targetWardrobeId == activeWardrobeId || !wardrobes.any((w) => w.id == targetWardrobeId)) return;
    final it = itemById(itemId);
    if (it == null) return;

    items = items.where((x) => x.id != itemId).toList();
    it.pinned = false;
    final target = _stash[targetWardrobeId] ?? _WardrobeContent.empty();
    target.items = [...target.items, it];
    _stash[targetWardrobeId] = target;
    _fillEmptySlots();

    notifyListeners();
    await _persist();
  }

  /// Deletes a wardrobe with all of its content, photos included. The last
  /// remaining wardrobe can't be deleted; deleting the active one switches
  /// to another first.
  Future<void> deleteWardrobe(String id) async {
    if (wardrobes.length <= 1 || !wardrobes.any((w) => w.id == id)) return;
    if (id == activeWardrobeId) {
      _stash[id] = _liveContent;
      _activate(wardrobes.firstWhere((w) => w.id != id).id);
    }
    final removed = _stash.remove(id);
    wardrobes = wardrobes.where((w) => w.id != id).toList();
    notifyListeners();
    await _persist();
    for (final it in removed?.items ?? const <ClothingItem>[]) {
      await _deleteImageFile(it.imagePath);
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _persistTimer?.cancel();
    _canvasPersistTimer?.cancel();
    super.dispose();
  }
}

/// iOS reassigns the app's sandbox container (and thus the documents
/// directory's absolute path) on every update, so a path saved on a
/// previous install can point nowhere after the app updates — showing up
/// as every photo turning into the missing-image placeholder. Re-anchor
/// whatever was stored to the *current* documents dir by keeping only the
/// part from `satnik_images/` onward.
String _resolveImagePath(String stored, String docsPath) {
  const marker = 'satnik_images';
  final i = stored.indexOf(marker);
  if (i == -1) return stored;
  return p.join(docsPath, stored.substring(i));
}

/// Everything that belongs to one wardrobe, as stored in the state file.
class _WardrobeContent {
  List<ClothingItem> items;
  List<SavedOutfit> outfits;
  List<DiaryEntry> diary;

  _WardrobeContent({
    required this.items,
    required this.outfits,
    required this.diary,
  });

  _WardrobeContent.empty() : outfits = [], items = [], diary = [];

  /// Each section is parsed independently, and each entry within a section
  /// is parsed independently too, so a single corrupt item/outfit can't
  /// wipe out the rest of the wardrobe.
  factory _WardrobeContent.fromJson(Map<String, dynamic> data, String? docsPath, {required String Function() newId}) {
    final c = _WardrobeContent.empty();

    try {
      for (final e in data['items'] as List<dynamic>? ?? []) {
        try {
          final item = ClothingItem.fromJson(e as Map<String, dynamic>);
          if (item.imagePath != null && docsPath != null) {
            item.imagePath = _resolveImagePath(item.imagePath!, docsPath);
          }
          c.items.add(item);
        } catch (_) {}
      }
    } catch (_) {}

    // Outfits used to be filed in named collections: they become one list,
    // collection by collection in the order they were arranged.
    final rawOutfits = <dynamic>[];
    try {
      if (data['outfits'] case final List<dynamic> list) {
        rawOutfits.addAll(list);
      } else if (data['saved'] case final Map<String, dynamic> byCol) {
        final order = [
          for (final c in data['cols'] as List<dynamic>? ?? const [])
            if (c is String && byCol.containsKey(c)) c,
          ...byCol.keys.where((k) => !(data['cols'] as List<dynamic>? ?? const []).contains(k)),
        ];
        for (final col in order) {
          rawOutfits.addAll(byCol[col] as List<dynamic>? ?? const []);
        }
      }
    } catch (_) {}
    for (final e in rawOutfits) {
      try {
        c.outfits.add(SavedOutfit.fromJson(e as Map<String, dynamic>, newId: newId));
      } catch (_) {}
    }

    try {
      for (final e in data['diary'] as List<dynamic>? ?? const []) {
        try {
          c.diary.add(DiaryEntry.fromJson(e as Map<String, dynamic>));
        } catch (_) {}
      }
      c.diary.sort(DiaryEntry.byDay);
    } catch (_) {}

    return c;
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'outfits': outfits.map((e) => e.toJson()).toList(),
    'diary': diary.map((e) => e.toJson()).toList(),
  };
}

/// How [WardrobeStore.importArchive] went.
enum ImportResult { done, notABackup, newerVersion, failed }

/// A backup zip, read and checked by [WardrobeStore.openArchive], ready to
/// import.
class Backup {
  final Archive _archive;
  final Map<String, dynamic> _data;
  Backup._(this._archive, this._data);

  List<Map<dynamic, dynamic>> get _wardrobes => [
    for (final w in _data['wardrobes'] as List) if (w is Map) w,
  ];

  int get wardrobeCount => _wardrobes.length;

  int _count(String key) => _wardrobes.fold(0, (n, w) => n + ((w[key] as List?)?.length ?? 0));
  int get itemCount => _count('items');
  int get outfitCount => _count('outfits');
}
