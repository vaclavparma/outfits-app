/// A name for a piece of clothing nobody has named: its main color and its
/// type — "Zelená košile", "Hnědé kalhoty", "Green shirt". Type names are
/// whatever the user typed, usually plural ("Trička", "T-shirts"), so the
/// noun is guessed into shape from its ending; a type that's an adjective
/// or the catch-all ("Letní", "Ostatní") gives way to the kind ("Šaty").
///
/// [colorName] is the color family's name as shown in the app — for Czech
/// the feminine form ("Zelená"), which is bent to fit; `null` without one.
String autoItemName({
  required String languageCode,
  required String typeName,
  required String kindName,
  required String otherTypeName,
  String? colorName,
}) {
  final cs = languageCode == 'cs';
  var noun = typeName.trim();
  if (noun.isEmpty || noun == otherTypeName || (cs && _isCzechAdjective(noun))) noun = kindName.trim();
  if (cs) return _czech(noun, colorName);
  return _english(noun, colorName);
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Letní", "Společenské", "Pracovní" — not something to put a color on.
bool _isCzechAdjective(String word) {
  final w = word.toLowerCase();
  return w.endsWith('í') || w.endsWith('ské') || w.endsWith('cké') || w.endsWith('né');
}

String _czech(String noun, String? colorName) {
  // A multi-word kind ("Horní díl") agrees through its last word.
  final words = noun.split(' ');
  var last = words.last.toLowerCase();
  // Adjective ending to put on the color's stem ("zelen-").
  String ending;
  if (last.endsWith('a')) {
    // Neuter plural ("trička", "saka") → singular ("tričko").
    last = '${last.substring(0, last.length - 1)}o';
    ending = 'é';
  } else if (last.endsWith('o')) {
    ending = 'é';
  } else if (last.endsWith('e') || last.endsWith('ě')) {
    ending = 'á'; // košile, sukně
  } else if (last.endsWith('y') || last.endsWith('i')) {
    ending = 'é'; // kalhoty, tenisky, džíny — said in the plural
  } else {
    ending = 'ý'; // svetr, kabát
  }
  words[words.length - 1] = last;
  final phrase = [for (final (i, w) in words.indexed) i == 0 ? w.toLowerCase() : w].join(' ');
  if (colorName == null || !colorName.endsWith('á')) return _capitalize(phrase);
  final adjective = colorName.substring(0, colorName.length - 1).toLowerCase() + ending;
  return _capitalize('$adjective $phrase');
}

/// Said in the plural even for one.
const _englishPluralOnly = {
  'jeans', 'trousers', 'pants', 'shorts', 'leggings', 'tights', 'sneakers', 'shoes', 'boots', 'sandals',
  'loafers', 'trainers', 'heels', 'flats', 'slippers', 'glasses', 'sunglasses', 'gloves', 'socks',
};

String _english(String noun, String? colorName) {
  final words = noun.toLowerCase().split(' ');
  var last = words.last;
  if (!_englishPluralOnly.contains(last)) {
    if (last.endsWith('sses')) {
      last = last.substring(0, last.length - 2); // dresses → dress
    } else if (last.endsWith('s') && !last.endsWith('ss')) {
      last = last.substring(0, last.length - 1);
    }
  }
  words[words.length - 1] = last;
  final phrase = words.join(' ');
  return _capitalize(colorName == null ? phrase : '${colorName.toLowerCase()} $phrase');
}
