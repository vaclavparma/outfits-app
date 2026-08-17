import 'package:flutter/widgets.dart';

import 'l10n/app_localizations.dart';

/// A single garment category, mirroring CATS from the mockup. [key] is a
/// stable internal identifier (used for persistence and category matching)
/// — it never changes with locale. The display label is looked up
/// separately via [categoryLabel], since it depends on [BuildContext].
class ClothingCategory {
  final String key;

  const ClothingCategory(this.key);
}

const List<ClothingCategory> kCategories = [
  ClothingCategory('tricka'),
  ClothingCategory('saty'),
  ClothingCategory('bundy'),
  ClothingCategory('kalhoty'),
  ClothingCategory('sukne'),
  ClothingCategory('boty'),
];

/// Localized quick-tag suggestions offered when adding/tagging an item.
/// These are plain suggested words, not a fixed taxonomy — tags themselves
/// are freeform strings, so switching locale only changes which words get
/// suggested, not any tag already stored on an item.
List<String> kQuickTags(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    l10n.tagWork,
    l10n.tagCasual,
    l10n.tagSummer,
    l10n.tagEvening,
    l10n.tagWinter,
    l10n.tagBasic,
  ];
}

String categoryLabel(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  return switch (key) {
    'tricka' => l10n.categoryTricka,
    'saty' => l10n.categorySaty,
    'bundy' => l10n.categoryBundy,
    'kalhoty' => l10n.categoryKalhoty,
    'sukne' => l10n.categorySukne,
    'boty' => l10n.categoryBoty,
    _ => key,
  };
}

/// Short single-word form of [categoryLabel], used where a full item name
/// would otherwise be shown (item names carry no real information — items
/// are identified by their photo and tags instead).
String shortCategoryLabel(BuildContext context, String key) =>
    categoryLabel(context, key).split(' ').first;

/// Distinct tags used across [items], in first-seen order.
List<String> distinctTags(Iterable<ClothingItem> items) {
  final tags = <String>[];
  for (final i in items) {
    for (final t in i.tags) {
      if (!tags.contains(t)) tags.add(t);
    }
  }
  return tags;
}

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
    tags: (json['tags'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    imagePath: json['imagePath'] as String?,
  );
}

/// A saved combination of items, filed under a collection. [catKeys] mirrors
/// the category of each item in [itemIds] at save time, so a resilient
/// summary caption can still be shown (localized, at display time) even if
/// an item was later deleted from the wardrobe.
class SavedOutfit {
  final String name;
  final List<String> catKeys;
  final List<String> itemIds;

  /// A pre-formatted summary string from before [catKeys] existed. Only
  /// ever set when loading old saved data that predates this field; new
  /// outfits always carry [catKeys] instead and leave this null.
  final String? legacyMeta;

  SavedOutfit({
    required this.name,
    required this.catKeys,
    required this.itemIds,
    this.legacyMeta,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'catKeys': catKeys,
    'itemIds': itemIds,
  };

  factory SavedOutfit.fromJson(Map<String, dynamic> json) => SavedOutfit(
    name: json['name'] as String,
    catKeys: (json['catKeys'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    itemIds: (json['itemIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    legacyMeta: json['catKeys'] == null ? json['meta'] as String? : null,
  );
}

enum WardrobeTabKind { outfit, wardrobe, collections }

enum WardrobeZone { top, bottom, shoes }

/// Which builder zone a category occupies, or null for layer-only
/// categories (outerwear) that go into [WardrobeStore.layers] instead.
WardrobeZone? zoneForCategory(String cat) => switch (cat) {
  'tricka' || 'saty' => WardrobeZone.top,
  'kalhoty' || 'sukne' => WardrobeZone.bottom,
  'boty' => WardrobeZone.shoes,
  _ => null,
};
