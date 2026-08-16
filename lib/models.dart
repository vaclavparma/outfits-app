/// A single garment category, mirroring CATS from the mockup.
class ClothingCategory {
  final String key;
  final String label;

  const ClothingCategory(this.key, this.label);
}

const List<ClothingCategory> kCategories = [
  ClothingCategory('tricka', 'Trička / topy'),
  ClothingCategory('saty', 'Šaty'),
  ClothingCategory('bundy', 'Bundy / vrstvy'),
  ClothingCategory('kalhoty', 'Kalhoty'),
  ClothingCategory('sukne', 'Sukně'),
  ClothingCategory('boty', 'Boty'),
];

const List<String> kQuickTags = ['práce', 'volno', 'léto', 'večer', 'zima', 'basic'];

String categoryLabel(String key) {
  for (final c in kCategories) {
    if (c.key == key) return c.label;
  }
  return key;
}

/// Short single-word form of [categoryLabel], used where a full item name
/// would otherwise be shown (item names carry no real information — items
/// are identified by their photo and tags instead).
String shortCategoryLabel(String key) => categoryLabel(key).split(' ').first;

/// One piece of clothing in the wardrobe.
class ClothingItem {
  final String id;
  final String cat;
  List<String> tags;
  String? imagePath;

  ClothingItem({
    required this.id,
    required this.cat,
    List<String>? tags,
    this.imagePath,
  }) : tags = tags ?? [];

  String get tagsLabel => tags.isEmpty ? '' : tags.join(' · ');

  Map<String, dynamic> toJson() => {
        'id': id,
        'cat': cat,
        'tags': tags,
        'imagePath': imagePath,
      };

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        id: json['id'] as String,
        cat: json['cat'] as String,
        tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        imagePath: json['imagePath'] as String?,
      );
}

/// A saved combination of items, filed under a collection.
class SavedOutfit {
  final String name;
  final String meta;
  final List<String> itemIds;

  SavedOutfit({required this.name, required this.meta, required this.itemIds});

  Map<String, dynamic> toJson() => {
        'name': name,
        'meta': meta,
        'itemIds': itemIds,
      };

  factory SavedOutfit.fromJson(Map<String, dynamic> json) => SavedOutfit(
        name: json['name'] as String,
        meta: json['meta'] as String,
        itemIds: (json['itemIds'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );
}

enum WardrobeTabKind { outfit, wardrobe, collections }

enum WardrobeZone { top, bottom, shoes }
