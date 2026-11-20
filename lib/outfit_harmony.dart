import 'package:flutter/painting.dart' show Color, HSLColor;

/// How well the colors of an outfit go together, from about 0 (they clash)
/// to 1 (a classic): a few rules of thumb people dress by. Each entry is
/// one garment's detected colors, main one first; a garment whose colors
/// aren't known counts as neutral.
///
/// - Neutrals (black, white, grey, beige, camel, navy, denim, anything
///   muted or very dark or light) go with everything.
/// - One colorful piece among neutrals is best; all neutrals is safe.
/// - Two colors work when they're close (tones of one) or opposite
///   (complementary); halfway apart they clash.
/// - Three or more colors only work as tones of one.
double colorHarmony(Iterable<List<int>?> garments) {
  final hues = [
    for (final colors in garments)
      if (colors != null && colors.isNotEmpty)
        if (HSLColor.fromColor(Color(colors.first)) case final c when !_isNeutral(c)) c.hue,
  ];
  if (hues.isEmpty) return 0.85;
  if (hues.length == 1) return 1;
  var widest = 0.0;
  for (var i = 0; i < hues.length; i++) {
    for (var j = i + 1; j < hues.length; j++) {
      final d = _hueDistance(hues[i], hues[j]);
      if (d > widest) widest = d;
    }
  }
  if (hues.length > 2) return widest <= 40 ? 0.75 : 0.2;
  if (widest <= 30) return 0.9;
  if (widest <= 60) return 0.65;
  if (widest >= 130) return 0.75;
  return 0.3;
}

bool _isNeutral(HSLColor c) =>
    c.saturation < 0.25 ||
    c.lightness < 0.22 ||
    c.lightness > 0.9 ||
    // Navy and denim: a muted, darkish blue.
    (c.hue >= 195 && c.hue <= 245 && c.lightness < 0.5 && c.saturation < 0.6) ||
    // Camel, khaki, tan: a muted warm.
    (c.hue >= 20 && c.hue <= 50 && c.saturation < 0.45);

/// How far apart two hues are around the color wheel, 0–180°.
double _hueDistance(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}
