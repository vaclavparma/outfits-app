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

  Future<ClothingItem> addItem(
    String cat,
    List<String> tags, {
    String? sourceImagePath,
  }) async {
    String? imagePath;
    var photoFailed = false;
    if (sourceImagePath != null) {
      try {
        imagePath = await _newImageCopy(sourceImagePath);
      } catch (_) {
        // Keep the item usable (category + tags) even if the photo couldn't
        // be saved — losing the whole item over a storage hiccup is worse.
        photoFailed = true;
      }
    }
    final item = ClothingItem(
      id: '$cat-new-${DateTime.now().microsecondsSinceEpoch}',
      cat: cat,
      tags: [...tags],
      imagePath: imagePath,
    );
    items = [...items, item];
    notifyListeners();
    await _persist();
    if (photoFailed) {
      flash('Uloženo do „${categoryLabel(cat)}“ · fotku se nepodařilo uložit');
    } else {
      flash(
        'Uloženo do „${categoryLabel(cat)}“${imagePath != null ? ' · fotka v souborech apky' : ''}',
      );
    }
    return item;
  }

  void setTags(String id, List<String> tags) {
    items = items.map((i) => i.id == id ? (i..tags = tags) : i).toList();
    notifyListeners();
    _persist();
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
    if (tagFilter == oldTag) tagFilter = newTag;
    notifyListeners();
    await _persist();
    flash('Tag „$oldTag“ přejmenován na „$newTag“');
  }

  Future<void> deleteTag(String tag) async {
    items = items
        .map((i) => i..tags = i.tags.where((t) => t != tag).toList())
        .toList();
    if (tagFilter == tag) tagFilter = null;
    notifyListeners();
    await _persist();
    flash('Tag „$tag“ smazán');
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
    flash('Smazáno: ${shortCategoryLabel(it.cat)}');
  }

  Future<void> addCollection(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty || cols.contains(name)) return;
    cols = [...cols, name];
    saved = {...saved, name: []};
    notifyListeners();
    await _persist();
    flash('Kolekce „$name“ přidána');
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
    flash('Kolekce přejmenována na „$newName“');
    return newName;
  }

  Future<void> deleteCollection(String name) async {
    cols = cols.where((c) => c != name).toList();
    saved = {...saved}..remove(name);
    notifyListeners();
    await _persist();
    flash('Kolekce „$name“ smazána');
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
    flash('Outfit smazán');
  }

  Future<void> saveOutfit({
    required String rawName,
    required String targetCol,
  }) async {
    if (cols.isEmpty) {
      flash('Nejdřív přidej kolekci');
      return;
    }
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
        : 'Outfit ${total + 1}';
    final col = targetCol.isNotEmpty ? targetCol : cols.first;

    final entry = SavedOutfit(
      name: name,
      meta: parts.map((i) => shortCategoryLabel(i.cat)).join(' · '),
      itemIds: parts.map((i) => i.id).toList(),
    );
    saved = {
      ...saved,
      col: [...(saved[col] ?? []), entry],
    };
    notifyListeners();
    await _persist();
    flash('„$name“ uloženo do kolekce $col');
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
    flash('Načteno: ${o.name}');
  }

  void toggleTagFilter(String tag) {
    tagFilter = tagFilter == tag ? null : tag;
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
