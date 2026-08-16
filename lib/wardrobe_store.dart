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
    try {
      final file = await _localFile();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['items'] != null) {
        items = (data['items'] as List<dynamic>)
            .map((e) => ClothingItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['cols'] != null) {
        cols = (data['cols'] as List<dynamic>).map((e) => e as String).toList();
      }
      if (data['saved'] != null) {
        final savedJson = data['saved'] as Map<String, dynamic>;
        saved = savedJson.map((key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map((e) => SavedOutfit.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ));
      }
      notifyListeners();
    } catch (_) {
      // Corrupt or missing state — fall back to the seed data.
    }
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
        'saved': saved.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
      };
      await file.writeAsString(jsonEncode(data));
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

  List<ClothingItem> byCat(String cat) => items.where((i) => i.cat == cat).toList();
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
    layers = [for (var j = 0; j < layers.length; j++) if (j != index) layers[j]];
    notifyListeners();
  }

  Future<String> _newImageCopy(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'satnik_images'));
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
    final ext = p.extension(sourcePath);
    final dest = p.join(imagesDir.path, '${DateTime.now().microsecondsSinceEpoch}$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<ClothingItem> addItem(String cat, List<String> tags, {String? sourceImagePath}) async {
    String? imagePath;
    if (sourceImagePath != null) {
      imagePath = await _newImageCopy(sourceImagePath);
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
    flash('Uloženo do „${categoryLabel(cat)}“${imagePath != null ? ' · fotka v souborech apky' : ''}');
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
    items = items.map((i) => i..tags = i.tags.where((t) => t != tag).toList()).toList();
    if (tagFilter == tag) tagFilter = null;
    notifyListeners();
    await _persist();
    flash('Tag „$tag“ smazán');
  }

  void useItem(ClothingItem it) {
    int find(List<ClothingItem> list, String id) => list.indexWhere((x) => x.id == id);
    if (it.cat == 'tricka' || it.cat == 'saty') {
      final i = find(topList, it.id);
      if (i >= 0) {
        idx = {...idx, WardrobeZone.top: i};
        screen = WardrobeTabKind.outfit;
      }
    } else if (it.cat == 'kalhoty' || it.cat == 'sukne') {
      final i = find(botList, it.id);
      if (i >= 0) {
        idx = {...idx, WardrobeZone.bottom: i};
        screen = WardrobeTabKind.outfit;
      }
    } else if (it.cat == 'boty') {
      final i = find(shoeList, it.id);
      if (i >= 0) {
        idx = {...idx, WardrobeZone.shoes: i};
        screen = WardrobeTabKind.outfit;
      }
    } else {
      if (!layers.contains(it.id) && layers.length < kMaxLayers) layers = [...layers, it.id];
      screen = WardrobeTabKind.outfit;
    }
    notifyListeners();
  }

  Future<void> deleteItem(ClothingItem it) async {
    items = items.where((x) => x.id != it.id).toList();
    layers = layers.where((id) => id != it.id).toList();
    notifyListeners();
    await _persist();
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

  Future<void> renameCollection(String oldName, String rawNewName) async {
    final newName = rawNewName.trim();
    if (newName.isEmpty || newName == oldName || cols.contains(newName)) return;
    if (!cols.contains(oldName)) return;
    cols = [for (final c in cols) c == oldName ? newName : c];
    final list = saved[oldName] ?? [];
    final newSaved = {...saved}..remove(oldName);
    newSaved[newName] = list;
    saved = newSaved;
    notifyListeners();
    await _persist();
    flash('Kolekce přejmenována na „$newName“');
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
    saved = {...saved, colName: [for (var j = 0; j < list.length; j++) if (j != index) list[j]]};
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
        if (items.any((i) => i.id == id)) items.firstWhere((i) => i.id == id),
      if (!isDress && bot != null) bot,
      if (shoe != null) shoe,
    ];

    final total = cols.fold<int>(0, (a, k) => a + (saved[k]?.length ?? 0));
    final name = rawName.trim().isNotEmpty ? rawName.trim() : 'Outfit ${total + 1}';
    final col = targetCol.isNotEmpty ? targetCol : cols.first;

    final entry = SavedOutfit(
      name: name,
      meta: parts.map((i) => shortCategoryLabel(i.cat)).join(' · '),
      itemIds: parts.map((i) => i.id).toList(),
    );
    saved = {...saved, col: [...(saved[col] ?? []), entry]};
    notifyListeners();
    await _persist();
    flash('„$name“ uloženo do kolekce $col');
  }

  void loadOutfit(SavedOutfit o) {
    final newIdx = {...idx};
    final newLayers = <String>[];
    for (final id in o.itemIds) {
      ClothingItem? it;
      for (final i in items) {
        if (i.id == id) {
          it = i;
          break;
        }
      }
      if (it == null) continue;
      if (it.cat == 'tricka' || it.cat == 'saty') {
        newIdx[WardrobeZone.top] = topList.indexWhere((x) => x.id == id);
      } else if (it.cat == 'kalhoty' || it.cat == 'sukne') {
        newIdx[WardrobeZone.bottom] = botList.indexWhere((x) => x.id == id);
      } else if (it.cat == 'boty') {
        newIdx[WardrobeZone.shoes] = shoeList.indexWhere((x) => x.id == id);
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
