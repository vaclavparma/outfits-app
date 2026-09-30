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
  ClothingCategory('horni'),
  ClothingCategory('saty'),
  ClothingCategory('dolni'),
  ClothingCategory('boty'),
];

/// Maps a category key from before the "horní/dolní díl" merge to its
/// current equivalent, so old items and saved outfits (which stored the old
/// keys) keep working after this migration. Anything not in the old set —
/// including already-current keys — passes through unchanged.
String _migrateCatKey(String key) => switch (key) {
  'tricka' || 'bundy' => 'horni',
  'kalhoty' || 'sukne' => 'dolni',
  _ => key,
};

String categoryLabel(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  return switch (key) {
    'horni' => l10n.categoryHorni,
    'saty' => l10n.categorySaty,
    'dolni' => l10n.categoryDolni,
    'boty' => l10n.categoryBoty,
    _ => key,
  };
}

/// Short single-word form of [categoryLabel], used where a full item name
/// would otherwise be shown (item names carry no real information — items
/// are identified by their photo and folder instead).
String shortCategoryLabel(BuildContext context, String key) =>
    categoryLabel(context, key).split(' ').first;

/// One piece of clothing in the wardrobe.
class ClothingItem {
  final String id;
  final String cat;

  /// The folder this item is filed under, within its own category (e.g.
  /// `'košile'` under `'horni'`) — or `null` if it hasn't been filed yet.
  String? folder;

  String? imagePath;

  /// When true and this item is the one currently showing in its outfit
  /// zone (or as a layer), [WardrobeStore.shuffle] leaves that slot alone.
  bool pinned;

  /// Optional free-text details, each `null` when not filled in. Price is
  /// free text too (e.g. "890 Kč") rather than a number, so any currency or
  /// format works.
  String? name;
  String? seller;
  String? size;
  String? price;
  String? note;

  ClothingItem({
    required this.id,
    required this.cat,
    this.folder,
    this.imagePath,
    this.pinned = false,
    this.name,
    this.seller,
    this.size,
    this.price,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cat': cat,
    'folder': folder,
    'imagePath': imagePath,
    'pinned': pinned,
    'name': name,
    'seller': seller,
    'size': size,
    'price': price,
    'note': note,
  };

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
    id: json['id'] as String,
    cat: _migrateCatKey(json['cat'] as String),
    // Tags (this item's old, freeform, multi-select organization) were
    // dropped in favor of a single folder per item — deliberately not
    // migrated, so `folder` starts unset even for pre-existing items.
    folder: json['folder'] as String?,
    imagePath: json['imagePath'] as String?,
    pinned: json['pinned'] as bool? ?? false,
    name: json['name'] as String?,
    seller: json['seller'] as String?,
    size: json['size'] as String?,
    price: json['price'] as String?,
    note: json['note'] as String?,
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
            ?.map((e) => _migrateCatKey(e as String))
            .toList() ??
        const [],
    itemIds: (json['itemIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    legacyMeta: json['catKeys'] == null ? json['meta'] as String? : null,
  );
}

/// One of the user's separate wardrobes (e.g. home vs. the cottage) — its
/// own items, folders, collections and saved outfits. Only the identity
/// lives here; the content itself is held by [WardrobeStore].
class Wardrobe {
  final String id;
  String name;

  Wardrobe({required this.id, required this.name});
}

enum WardrobeTabKind { outfit, wardrobe, collections }

enum WardrobeZone { top, bottom, shoes }

/// Which builder zone a category occupies. Every category maps to one —
/// "horní díl" items also double as [WardrobeStore.layers] candidates, but
/// that's an additional role, not a separate category.
WardrobeZone? zoneForCategory(String cat) => switch (cat) {
  'horni' || 'saty' => WardrobeZone.top,
  'dolni' => WardrobeZone.bottom,
  'boty' => WardrobeZone.shoes,
  _ => null,
};
