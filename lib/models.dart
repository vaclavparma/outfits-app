const _diacritics = {
  'á': 'a', 'ä': 'a', 'à': 'a', 'â': 'a', 'ą': 'a', 'č': 'c', 'ć': 'c', 'ç': 'c',
  'ď': 'd', 'é': 'e', 'ě': 'e', 'ë': 'e', 'è': 'e', 'ê': 'e', 'ę': 'e', 'í': 'i',
  'î': 'i', 'ľ': 'l', 'ĺ': 'l', 'ł': 'l', 'ň': 'n', 'ń': 'n', 'ñ': 'n', 'ó': 'o',
  'ö': 'o', 'ô': 'o', 'ő': 'o', 'ř': 'r', 'ŕ': 'r', 'š': 's', 'ś': 's', 'ß': 'ss',
  'ť': 't', 'ú': 'u', 'ů': 'u', 'ü': 'u', 'ù': 'u', 'û': 'u', 'ű': 'u', 'ý': 'y',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
};

String _foldForSearch(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(_diacritics[ch] ?? ch);
  }
  return b.toString();
}

/// Whether every word of [query] appears somewhere in [texts], ignoring
/// case and diacritics. A blank query matches everything.
bool textsMatchSearch(Iterable<String?> texts, String query) {
  final words = _foldForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = _foldForSearch(texts.whereType<String>().join(' '));
  return words.every(haystack.contains);
}

/// A kind of clothing (top, shoes, a hat…) — what the outfit canvas has
/// cards for. Shared by every wardrobe and managed in settings. The
/// built-in kinds keep the ids the old fixed categories had
/// (`horni`, `saty`, `dolni`, `boty`), so older data still points at them.
class ClothingKind {
  final String id;
  String name;

  /// Its types (t-shirt, shirt…), in display order — always at least one,
  /// since every item has a type.
  List<ClothingType> types;

  ClothingKind({required this.id, required this.name, List<ClothingType>? types})
    : types = types ?? [];

  ClothingType? typeById(String? id) {
    for (final t in types) {
      if (t.id == id) return t;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'types': types.map((t) => t.toJson()).toList(),
  };

  factory ClothingKind.fromJson(Map<String, dynamic> json) => ClothingKind(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    types: [
      for (final t in json['types'] as List<dynamic>? ?? const [])
        if (t is Map<String, dynamic> && t['id'] is String) ClothingType.fromJson(t),
    ],
  );
}

/// A type within a [ClothingKind] (e.g. "shirts" under tops) — like a
/// folder an item can be filed in.
class ClothingType {
  final String id;
  String name;

  ClothingType({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ClothingType.fromJson(Map<String, dynamic> json) =>
      ClothingType(id: json['id'] as String, name: json['name'] as String? ?? '');
}

/// How cards sit on the outfit canvas — shared by the canvas itself and the
/// saved outfits' previews, so a preview is the canvas in miniature.
abstract final class CanvasGeometry {
  /// A card's size at scale 1 on a canvas of [refWidth] × [refHeight]
  /// (about a phone's); a bigger canvas scales everything up ([unitFor]).
  static const cardWidth = 170.0;
  static const cardHeight = 190.0;
  static const refWidth = 370.0;
  static const refHeight = 560.0;

  static double unitFor(double width, double height) =>
      (width / refWidth < height / refHeight ? width / refWidth : height / refHeight).clamp(0.55, 2.0);

  /// Where a card centered at ([x], [y]) (fractions of [width] × [height])
  /// sits, nudged back inside the canvas unless [free].
  static ({double left, double top, double width, double height}) cardRect({
    required double width,
    required double height,
    required double unit,
    required double x,
    required double y,
    required double scale,
    double dx = 0,
    double dy = 0,
    bool free = false,
  }) {
    final w = cardWidth * unit * scale, h = cardHeight * unit * scale;
    var cx = x * width + dx, cy = y * height + dy;
    if (!free) {
      double place(double c, double extent, double max) =>
          max > extent ? c.clamp(extent / 2, max - extent / 2) : max / 2;
      cx = place(cx, w, width);
      cy = place(cy, h, height);
    }
    return (left: cx - w / 2, top: cy - h / 2, width: w, height: h);
  }

  /// A slight, stable tilt per card (in degrees), so the canvas looks laid
  /// out by hand.
  static double tilt(String slotId) => (slotId.codeUnits.fold(0, (a, c) => a + c) % 9 - 4) * 0.55;
}

/// One card on the outfit canvas: which kind it shows, where its center
/// sits ([x], [y] as fractions of the canvas, 0–1) and how big it is.
class CanvasSlot {
  static const minScale = 0.6;
  static const maxScale = 1.8;

  /// The most cards the canvas takes — more and they only bury each other.
  static const maxCount = 8;

  final String id;
  final String kindId;
  double x;
  double y;
  double scale;

  CanvasSlot({required this.id, required this.kindId, required this.x, required this.y, this.scale = 1});

  Map<String, dynamic> toJson() => {'id': id, 'kind': kindId, 'x': x, 'y': y, 'scale': scale};

  factory CanvasSlot.fromJson(Map<String, dynamic> json) => CanvasSlot(
    id: json['id'] as String,
    kindId: json['kind'] as String,
    x: (json['x'] as num).toDouble().clamp(0.0, 1.0),
    y: (json['y'] as num).toDouble().clamp(0.0, 1.0),
    scale: (json['scale'] as num? ?? 1).toDouble().clamp(minScale, maxScale),
  );
}

/// One piece of clothing in the wardrobe.
class ClothingItem {
  final String id;

  /// Id of the [ClothingKind] it belongs to (stored as `cat`, which is
  /// what it was called when kinds were fixed categories).
  String cat;

  /// Id of its [ClothingType] within that kind. Only `null` in data read
  /// from disk before it's been checked — the store gives every item a type.
  String? typeId;

  String? imagePath;

  /// When true and this item is showing on the outfit canvas,
  /// [WardrobeStore.shuffle] leaves its card alone.
  bool pinned;

  /// Optional free-text details, each `null` when not filled in. Price is
  /// free text too (e.g. "890 Kč") rather than a number, so any currency or
  /// format works.
  String? name;
  String? seller;
  String? size;
  String? price;
  String? note;

  /// The garment's main colors (1–3, most prominent first) as ARGB ints,
  /// detected from the photo — `null` until detected, empty if nothing
  /// could be read from it.
  List<int>? colors;

  ClothingItem({
    required this.id,
    required this.cat,
    this.typeId,
    this.imagePath,
    this.pinned = false,
    this.name,
    this.seller,
    this.size,
    this.price,
    this.note,
    this.colors,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cat': cat,
    'typeId': typeId,
    'imagePath': imagePath,
    'pinned': pinned,
    'name': name,
    'seller': seller,
    'size': size,
    'price': price,
    'note': note,
    'colors': colors,
  };

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
    id: json['id'] as String,
    cat: json['cat'] as String,
    typeId: json['typeId'] as String?,
    imagePath: json['imagePath'] as String?,
    pinned: json['pinned'] as bool? ?? false,
    name: json['name'] as String?,
    seller: json['seller'] as String?,
    size: json['size'] as String?,
    price: json['price'] as String?,
    note: json['note'] as String?,
    colors: (json['colors'] as List<dynamic>?)?.map((e) => e as int).toList(),
  );
}

/// A saved combination of items. [catKeys] mirrors the kind of each item in
/// [itemIds] at save time. [slots] is the canvas it was laid out on.
/// [favorite] is the heart on it in the outfits list.
class SavedOutfit {
  final String id;
  final List<String> catKeys;
  final List<String> itemIds;
  final List<SavedSlot> slots;
  bool favorite;

  SavedOutfit({
    required this.id,
    required this.catKeys,
    required this.itemIds,
    required this.slots,
    this.favorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'catKeys': catKeys,
    'itemIds': itemIds,
    'slots': slots.map((s) => s.toJson()).toList(),
    if (favorite) 'favorite': true,
  };

  /// Outfits saved before they had ids (in named collections) get [newId].
  factory SavedOutfit.fromJson(Map<String, dynamic> json, {required String Function() newId}) {
    final catKeys = (json['catKeys'] as List<dynamic>? ?? []).map((e) => e as String).toList();
    final itemIds = (json['itemIds'] as List<dynamic>? ?? []).map((e) => e as String).toList();
    final rawSlots = json['slots'] as List<dynamic>?;
    return SavedOutfit(
      id: json['id'] as String? ?? newId(),
      catKeys: catKeys,
      itemIds: itemIds,
      slots: rawSlots == null
          ? legacyLayout(catKeys, itemIds)
          : rawSlots.whereType<Map<String, dynamic>>().map(SavedSlot.fromJson).toList(),
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  /// A canvas for an outfit saved before there was one, laid out like the
  /// old fixed outfit screen: the top upper left, any layers (further tops)
  /// smaller beside it, the bottom below and to the right, shoes at the
  /// bottom — or a dress, tall, in place of top and bottom. Those outfits
  /// always listed the top first, then layers, bottom and shoes.
  static List<SavedSlot> legacyLayout(List<String> catKeys, List<String> itemIds) {
    final hasLayers = catKeys.where((k) => k == 'horni' || k == 'saty').length > 1;
    var tops = 0;
    final slots = <SavedSlot>[];
    for (var i = 0; i < itemIds.length && i < catKeys.length; i++) {
      final kind = catKeys[i];
      // 0 for the top itself, then 1, 2… for the layers over it.
      final layer = kind == 'horni' || kind == 'saty' ? tops++ : 0;
      final (x, y, scale) = layer > 0
          ? (0.70 + layer * 0.06, 0.14 + layer * 0.08, 0.72)
          : switch (kind) {
              'saty' => (hasLayers ? 0.38 : 0.45, 0.42, 1.55),
              'horni' => (hasLayers ? 0.36 : 0.42, 0.22, hasLayers ? 0.88 : 1.0),
              'dolni' => (0.56, 0.53, 1.0),
              'boty' => (0.40, 0.83, 0.8),
              _ => (0.5, 0.5, 0.9),
            };
      slots.add(SavedSlot(id: 'legacy-$i', kindId: kind, x: x, y: y, scale: scale, itemId: itemIds[i]));
    }
    return slots;
  }
}

/// One card of a [SavedOutfit]'s canvas: its place and size, and the item
/// that was in it (`null` for an empty card). [id] is the card's own, so it
/// comes back exactly as it was — tilt included (see [CanvasGeometry.tilt]).
class SavedSlot {
  final String id;
  final String kindId;
  final double x;
  final double y;
  final double scale;
  final String? itemId;

  const SavedSlot({
    required this.id,
    required this.kindId,
    required this.x,
    required this.y,
    required this.scale,
    this.itemId,
  });

  Map<String, dynamic> toJson() => {'id': id, 'kind': kindId, 'x': x, 'y': y, 'scale': scale, 'item': itemId};

  factory SavedSlot.fromJson(Map<String, dynamic> json) => SavedSlot(
    id: json['id'] as String? ?? '${json['kind']}-${json['x']}-${json['y']}',
    kindId: json['kind'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    scale: (json['scale'] as num? ?? 1).toDouble(),
    itemId: json['item'] as String?,
  );
}

/// One of the user's separate wardrobes (e.g. home vs. the cottage) — its
/// own items, saved outfits and diary. Only the identity
/// lives here; the content itself is held by [WardrobeStore].
class Wardrobe {
  final String id;
  String name;

  Wardrobe({required this.id, required this.name});
}

/// An outfit written into the diary as worn on [day] (midnight, local
/// time): the canvas it was laid out on, like a [SavedOutfit]'s, and when
/// it was written down.
class DiaryEntry {
  final String id;
  final DateTime day;
  final DateTime loggedAt;
  final List<SavedSlot> slots;

  DiaryEntry({required this.id, required DateTime day, required this.loggedAt, required this.slots})
    : day = DateTime(day.year, day.month, day.day);

  /// The items worn, each once.
  Iterable<String> get itemIds => {for (final s in slots) ?s.itemId};

  /// Day by day, and within a day in the order written down. (Sorting by
  /// day alone isn't enough: Dart's sort isn't stable past 32 entries.)
  static int byDay(DiaryEntry a, DiaryEntry b) {
    final byDay = a.day.compareTo(b.day);
    return byDay != 0 ? byDay : a.loggedAt.compareTo(b.loggedAt);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': '${day.year}-${_two(day.month)}-${_two(day.day)}',
    'loggedAt': loggedAt.millisecondsSinceEpoch,
    'slots': slots.map((s) => s.toJson()).toList(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final parts = (json['day'] as String).split('-').map(int.parse).toList();
    return DiaryEntry(
      id: json['id'] as String,
      day: DateTime(parts[0], parts[1], parts[2]),
      loggedAt: DateTime.fromMillisecondsSinceEpoch(json['loggedAt'] as int),
      slots: [
        for (final e in json['slots'] as List<dynamic>? ?? const [])
          if (e is Map<String, dynamic>) SavedSlot.fromJson(e),
      ],
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// Whole calendar days from [from] to [to], times of day ignored. Counted
/// on UTC dates, so a daylight-saving change in between can't make a day
/// 23 or 25 hours long and the count come out one short.
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Midnight [days] calendar days after [day] (before, if negative) — not
/// `day ± 24 h`, which lands on the wrong date across a clock change.
DateTime addDays(DateTime day, int days) => DateTime(day.year, day.month, day.day + days);

/// The tabs, in the order they sit in the bottom bar (and swipe between).
enum WardrobeTabKind { outfit, outfits, diary, wardrobe }
