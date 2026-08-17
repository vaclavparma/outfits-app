import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Holds the entire wardrobe/outfit state and mirrors the `Component` logic
/// class from the Šatník mockup (Satnik.dc.html): seeded items, the current
/// outfit selection per zone, layers, collections of saved outfits, and
/// persistence to disk.
class WardrobeStore extends ChangeNotifier {
  static const _fileName = 'satnik_v1.json';
  static const kMaxLayers = 2;

  WardrobeTabKind screen = WardrobeTabKind.outfit;
  List<ClothingItem> items = [];
  Map<WardrobeZone, int> idx = {
    WardrobeZone.top: 0,
    WardrobeZone.bottom: 0,
    WardrobeZone.shoes: 0,
  };
  List<String> layers = [];
  List<String> cols = [];
  Map<String, List<SavedOutfit>> saved = {};
  String? tagFilter;

  /// All tags known to the app, managed explicitly via the "manage tags"
  /// sheet — independent of which items currently carry them, so a tag
  /// stays filterable/assignable even if no item happens to have it right
  /// now (and doesn't vanish just because the last item wearing it was
  /// deleted).
  List<String> knownTags = [];

  /// `null` follows the system/device locale; otherwise an explicit locale
  /// code like `'cs'` or `'en'` picked in settings.
  String? localeCode;

  /// Whether the "dresses" category shows up in the wardrobe and when
  /// adding clothes. Turning it off doesn't apply retroactively — dresses
  /// already in the wardrobe stay put and still work in the outfit builder.
  bool showDresses = true;

  /// Same as [showDresses], for the "skirts" category.
  bool showSkirts = true;

  /// [kCategories], minus any category turned off in settings.
  List<ClothingCategory> get visibleCategories => kCategories.where((c) {
    if (c.key == 'saty') return showDresses;
    if (c.key == 'sukne') return showSkirts;
    return true;
  }).toList();

  String _toast = '';
  Timer? _toastTimer;
  String get toast => _toast;

  Future<void> load() async {
    Map<String, dynamic> data;
    try {
      final file = await _localFile();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Missing or unreadable state file — start from the empty defaults.
      return;
    }

    // Each section is parsed independently, and each entry within a section
    // is parsed independently too, so a single corrupt item/outfit can't
    // wipe out the rest of the wardrobe.
    try {
      final rawItems = data['items'] as List<dynamic>? ?? [];
      final parsedItems = <ClothingItem>[];
      for (final e in rawItems) {
        try {
          parsedItems.add(ClothingItem.fromJson(e as Map<String, dynamic>));
        } catch (_) {}
      }
      items = parsedItems;
    } catch (_) {}

    try {
      cols = (data['cols'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList();
    } catch (_) {}

    try {
      final rawSaved = data['saved'] as Map<String, dynamic>? ?? {};
      final parsedSaved = <String, List<SavedOutfit>>{};
      rawSaved.forEach((key, value) {
        final outfits = <SavedOutfit>[];
        for (final e in (value as List<dynamic>? ?? [])) {
          try {
            outfits.add(SavedOutfit.fromJson(e as Map<String, dynamic>));
          } catch (_) {}
        }
        parsedSaved[key] = outfits;
      });
      saved = parsedSaved;
    } catch (_) {}

    try {
      final rawKnownTags = data['knownTags'] as List<dynamic>?;
      knownTags = rawKnownTags == null
          // Migrating from before `knownTags` existed: seed it from
          // whatever tags are already in use, so they stay manageable
          // instead of quietly disappearing from the tag list.
          ? distinctTags(items)
          : rawKnownTags.map((e) => e as String).toList();
    } catch (_) {}

    try {
      localeCode = data['localeCode'] as String?;
    } catch (_) {}

    try {
      showDresses = data['showDresses'] as bool? ?? true;
    } catch (_) {}

    try {
      showSkirts = data['showSkirts'] as bool? ?? true;
    } catch (_) {}

    notifyListeners();
  }

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<void> _persist() async {
    try {
      final file = await _localFile();
      final data = {
        'items': items.map((e) => e.toJson()).toList(),
        'cols': cols,
        'saved': saved.map(
          (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
        ),
        'knownTags': knownTags,
        'localeCode': localeCode,
        'showDresses': showDresses,
        'showSkirts': showSkirts,
      };
      // Write to a temp file and rename over the real one, so a crash or
      // kill mid-write can never leave a half-written/corrupt state file.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(data));
      await tmp.rename(file.path);
    } catch (_) {
      // Best-effort persistence; nothing the UI can do about a write failure.
    }
  }

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

  ClothingItem? itemById(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  List<ClothingItem> byCat(String cat) =>
      items.where((i) => i.cat == cat).toList();
  List<ClothingItem> get topList => [...byCat('tricka'), ...byCat('saty')];
  List<ClothingItem> get botList => [...byCat('kalhoty'), ...byCat('sukne')];
  List<ClothingItem> get shoeList => byCat('boty');

  List<ClothingItem> zoneList(WardrobeZone z) {
    switch (z) {
      case WardrobeZone.top:
        return topList;
      case WardrobeZone.bottom:
        return botList;
      case WardrobeZone.shoes:
        return shoeList;
    }
  }

  ClothingItem? at(List<ClothingItem> list, WardrobeZone zone) {
    if (list.isEmpty) return null;
    final i = ((idx[zone]! % list.length) + list.length) % list.length;
    return list[i];
  }

  void step(WardrobeZone zone, int dir) {
    idx = {...idx, zone: idx[zone]! + dir};
    notifyListeners();
  }

  void selectIndex(WardrobeZone zone, int i) {
    idx = {...idx, zone: i};
    notifyListeners();
  }

  void shuffle() {
    final rng = Random();
    idx = {
      WardrobeZone.top: rng.nextInt(99),
      WardrobeZone.bottom: rng.nextInt(99),
      WardrobeZone.shoes: rng.nextInt(99),
    };
    if (layers.isNotEmpty) {
      final pool = byCat('bundy')..shuffle(rng);
      layers = pool.take(layers.length).map((i) => i.id).toList();
    }
    notifyListeners();
  }

  void addLayer(String itemId) {
    if (layers.contains(itemId) || layers.length >= kMaxLayers) return;
    layers = [...layers, itemId];
    screen = WardrobeTabKind.outfit;
    notifyListeners();
  }

  void removeLayer(int index) {
    layers = [
      for (var j = 0; j < layers.length; j++)
        if (j != index) layers[j],
    ];
    notifyListeners();
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

  /// Adds one new item per path in [sourceImagePaths] (all sharing [cat] and
  /// [tags]) — e.g. picking several photos at once to add a handful of
  /// t-shirts in one go instead of repeating the whole form per item. A
  /// photo that fails to copy just leaves that one item photo-less rather
  /// than failing the whole batch; the count of such failures is reported
  /// back rather than flashed here, since composing user-facing text needs
  /// a [BuildContext] this store doesn't have.
  Future<({List<ClothingItem> items, int photoFailures})> addItems(
    String cat,
    List<String> tags, {
    required List<String> sourceImagePaths,
  }) async {
    final newItems = <ClothingItem>[];
    var photoFailures = 0;
    for (final sourcePath in sourceImagePaths) {
      String? imagePath;
      try {
        imagePath = await _newImageCopy(sourcePath);
      } catch (_) {
        // Keep the item usable (category + tags) even if the photo couldn't
        // be saved — losing the whole item over a storage hiccup is worse.
        photoFailures++;
      }
      newItems.add(
        ClothingItem(
          id: '$cat-new-${DateTime.now().microsecondsSinceEpoch}-${newItems.length}',
          cat: cat,
          tags: [...tags],
          imagePath: imagePath,
        ),
      );
    }
    items = [...items, ...newItems];
    notifyListeners();
    await _persist();
    return (items: newItems, photoFailures: photoFailures);
  }

  void setTags(String id, List<String> tags) {
    items = items.map((i) => i.id == id ? (i..tags = tags) : i).toList();
    notifyListeners();
    _persist();
  }

  /// Adds a brand-new known tag (a no-op if it already exists) — the only
  /// place new tags get created; assigning a tag to an item can only pick
  /// from this list, never coin a new one on the fly.
  Future<void> addKnownTag(String rawTag) async {
    final tag = rawTag.trim().toLowerCase();
    if (tag.isEmpty || knownTags.contains(tag)) return;
    knownTags = [...knownTags, tag];
    notifyListeners();
    await _persist();
  }

  Future<void> renameTag(String oldTag, String rawNewTag) async {
    final newTag = rawNewTag.trim().toLowerCase();
    if (newTag.isEmpty || newTag == oldTag) return;
    items = items.map((i) {
      if (!i.tags.contains(oldTag)) return i;
      final tags = i.tags.where((t) => t != oldTag).toList();
      if (!tags.contains(newTag)) tags.add(newTag);
      return i..tags = tags;
    }).toList();
    // Merge into `newTag` if it's already a known tag, rather than ending
    // up with two list entries for what's now the same word.
    final mergedTags = <String>[];
    for (final t in knownTags) {
      final mapped = t == oldTag ? newTag : t;
      if (!mergedTags.contains(mapped)) mergedTags.add(mapped);
    }
    knownTags = mergedTags;
    if (tagFilter == oldTag) tagFilter = newTag;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteTag(String tag) async {
    items = items
        .map((i) => i..tags = i.tags.where((t) => t != tag).toList())
        .toList();
    knownTags = knownTags.where((t) => t != tag).toList();
    if (tagFilter == tag) tagFilter = null;
    notifyListeners();
    await _persist();
  }

  void useItem(ClothingItem it) {
    final zone = zoneForCategory(it.cat);
    if (zone != null) {
      final i = zoneList(zone).indexWhere((x) => x.id == it.id);
      if (i >= 0) idx = {...idx, zone: i};
    } else if (!layers.contains(it.id) && layers.length < kMaxLayers) {
      layers = [...layers, it.id];
    }
    screen = WardrobeTabKind.outfit;
    notifyListeners();
  }

  Future<void> deleteItem(ClothingItem it) async {
    items = items.where((x) => x.id != it.id).toList();
    layers = layers.where((id) => id != it.id).toList();
    notifyListeners();
    await _persist();
    if (it.imagePath != null) {
      try {
        final file = File(it.imagePath!);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best-effort cleanup — a stray photo file left behind is harmless.
      }
    }
  }

  Future<void> addCollection(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty || cols.contains(name)) return;
    cols = [...cols, name];
    saved = {...saved, name: []};
    notifyListeners();
    await _persist();
  }

  /// Renames a collection, returning the name that ended up in effect (the
  /// new name on success, or the unchanged [oldName] if the rename was
  /// rejected — empty, unchanged, a duplicate, or the collection is gone).
  Future<String> renameCollection(String oldName, String rawNewName) async {
    final newName = rawNewName.trim();
    if (newName.isEmpty || newName == oldName || cols.contains(newName)) {
      return oldName;
    }
    if (!cols.contains(oldName)) return oldName;
    cols = [for (final c in cols) c == oldName ? newName : c];
    final list = saved[oldName] ?? [];
    final newSaved = {...saved}..remove(oldName);
    newSaved[newName] = list;
    saved = newSaved;
    notifyListeners();
    await _persist();
    return newName;
  }

  Future<void> deleteCollection(String name) async {
    cols = cols.where((c) => c != name).toList();
    saved = {...saved}..remove(name);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteOutfit(String colName, int index) async {
    final list = saved[colName] ?? [];
    saved = {
      ...saved,
      colName: [
        for (var j = 0; j < list.length; j++)
          if (j != index) list[j],
      ],
    };
    notifyListeners();
    await _persist();
  }

  /// Saves the current outfit selection into [targetCol] (or the first
  /// collection, if empty), returning the collection/name it landed under —
  /// or null if there's no collection to save into. [defaultName] supplies
  /// the auto-generated name ("Outfit N") when [rawName] is blank, since
  /// that text needs a [BuildContext] this store doesn't have.
  Future<({String col, String name})?> saveOutfit({
    required String rawName,
    required String targetCol,
    required String Function(int n) defaultName,
  }) async {
    if (cols.isEmpty) return null;
    final top = at(topList, WardrobeZone.top);
    final bot = at(botList, WardrobeZone.bottom);
    final shoe = at(shoeList, WardrobeZone.shoes);
    final isDress = top != null && top.cat == 'saty';

    final parts = <ClothingItem>[
      if (top != null) top,
      for (final id in layers)
        if (itemById(id) case final item?) item,
      if (!isDress && bot != null) bot,
      if (shoe != null) shoe,
    ];

    final total = cols.fold<int>(0, (a, k) => a + (saved[k]?.length ?? 0));
    final name = rawName.trim().isNotEmpty
        ? rawName.trim()
        : defaultName(total + 1);
    final col = targetCol.isNotEmpty ? targetCol : cols.first;

    final entry = SavedOutfit(
      name: name,
      catKeys: parts.map((i) => i.cat).toList(),
      itemIds: parts.map((i) => i.id).toList(),
    );
    saved = {
      ...saved,
      col: [...(saved[col] ?? []), entry],
    };
    notifyListeners();
    await _persist();
    return (col: col, name: name);
  }

  void loadOutfit(SavedOutfit o) {
    final newIdx = {...idx};
    final newLayers = <String>[];
    for (final id in o.itemIds) {
      final it = itemById(id);
      if (it == null) continue;
      final zone = zoneForCategory(it.cat);
      if (zone != null) {
        newIdx[zone] = zoneList(zone).indexWhere((x) => x.id == id);
      } else {
        newLayers.add(id);
      }
    }
    idx = newIdx;
    layers = newLayers;
    screen = WardrobeTabKind.outfit;
    notifyListeners();
  }

  void toggleTagFilter(String tag) {
    tagFilter = tagFilter == tag ? null : tag;
    notifyListeners();
  }

  void setLocale(String? code) {
    localeCode = code;
    notifyListeners();
    _persist();
  }

  void setShowDresses(bool value) {
    showDresses = value;
    notifyListeners();
    _persist();
  }

  void setShowSkirts(bool value) {
    showSkirts = value;
    notifyListeners();
    _persist();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
