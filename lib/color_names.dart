import 'dart:ui' show Color;

/// A named family of colors, for adding detected garment colors up into
/// something readable ("you wear a lot of brown"). [swatch] is how the
/// family is drawn where it stands for itself (legend, share bars).
enum ColorFamily {
  white(Color(0xFFF2F0EB)),
  beige(Color(0xFFD9C3A0)),
  yellow(Color(0xFFE2B93B)),
  orange(Color(0xFFE08A3C)),
  red(Color(0xFFC0392B)),
  pink(Color(0xFFE59AB0)),
  purple(Color(0xFF8E6BB0)),
  blue(Color(0xFF3F5F94)),
  green(Color(0xFF5E7F4A)),
  brown(Color(0xFF7B5135)),
  grey(Color(0xFF9A9893)),
  black(Color(0xFF222222));

  final Color swatch;
  const ColorFamily(this.swatch);

  /// The family [argb] belongs to, judged by hue, saturation and lightness
  /// the way people name clothes: dark warm colors are brown, pale warm
  /// ones beige, washed-out ones grey.
  static ColorFamily of(int argb) {
    final r = (argb >> 16 & 0xFF) / 255, g = (argb >> 8 & 0xFF) / 255, b = (argb & 0xFF) / 255;
    final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final l = (mx + mn) / 2;
    final chroma = mx - mn;
    // HSL saturation: how colorful relative to how light — photographed
    // fabric comes out muted, so this, not raw chroma, decides grey.
    final s = chroma == 0 ? 0.0 : chroma / (1 - (2 * l - 1).abs());
    var h = 0.0;
    if (chroma > 0) {
      if (mx == r) {
        h = 60 * (((g - b) / chroma) % 6);
      } else if (mx == g) {
        h = 60 * ((b - r) / chroma + 2);
      } else {
        h = 60 * ((r - g) / chroma + 4);
      }
      if (h < 0) h += 360;
    }

    if (l < 0.1) return black;
    if (s < 0.07 || chroma < 0.035) {
      if (l > 0.82) return white;
      if (l < 0.2) return black;
      return grey;
    }
    if (h >= 15 && h < 65) {
      if (l > 0.9 && s < 0.5) return white;
      if (l < 0.45) return brown;
      if (s < 0.35 || (l > 0.6 && s < 0.5)) return beige;
      return h < 40 ? orange : yellow;
    }
    if (h < 15 || h >= 345) {
      if (h < 15 && s < 0.45 && l < 0.5) return brown; // terracotta, rust
      if (l > 0.7 || (s < 0.4 && l > 0.5)) return pink;
      return red;
    }
    if (h < 170) return green;
    if (h < 255) return blue;
    if (h < 290) return purple;
    return l > 0.55 || s < 0.4 ? pink : purple;
  }
}
