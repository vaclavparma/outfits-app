import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// The garment's main colors (1–3, most prominent first) as ARGB ints, or an
/// empty list if the photo couldn't be read. Runs fully on-device: the photo
/// is shrunk, the background is taken to be whatever matches the photo's
/// edges and is connected to them, and the rest is grouped into colors.
Future<List<int>> detectGarmentColors(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final landscape = descriptor.width >= descriptor.height;
    final codec = await descriptor.instantiateCodec(
      targetWidth: landscape ? _side : null,
      targetHeight: landscape ? null : _side,
    );
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final w = image.width, h = image.height;
    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    if (data == null) return const [];
    return await compute(analyzeGarmentColors, (rgba: data.buffer.asUint8List(), width: w, height: h));
  } catch (_) {
    return const [];
  }
}

/// Long edge, in pixels, photos are analyzed at. Stored photos are 1600 px,
/// so thin stripes (2–3 px there) still span a whole pixel at this size;
/// at 256 px they blurred away entirely.
const _side = 800;

/// Grouping into colors works on an even sample of at most this many
/// garment pixels — plenty for the colors, and keeps 800 px fast.
const _maxClusterSamples = 20000;

/// Colors closer than this (ΔE, CIE76) are reported as one.
const _mergeThreshold = 15.0;

/// Light and shadow on the same fabric: about the same hue and chroma
/// (a*/b* within this) at a lightness difference up to [_shadeMaxL].
const _shadeMaxAb = 10.0;
const _shadeMaxL = 25.0;

/// A color must cover at least this share of the garment to be reported.
const _minShare = 0.07;

const _maxColors = 3;

/// Pure analysis of raw RGBA pixels — see [detectGarmentColors].
@visibleForTesting
List<int> analyzeGarmentColors(({Uint8List rgba, int width, int height}) input) {
  final (:rgba, :width, :height) = input;
  final n = width * height;
  final lab = Float32List(n * 3);
  final opaque = Uint8List(n);
  for (var i = 0; i < n; i++) {
    final c = _toLab(rgba[i * 4], rgba[i * 4 + 1], rgba[i * 4 + 2]);
    lab[i * 3] = c.$1;
    lab[i * 3 + 1] = c.$2;
    lab[i * 3 + 2] = c.$3;
    opaque[i] = rgba[i * 4 + 3] >= 128 ? 1 : 0;
  }

  // Background colors: what dominates a ring along the photo's edges.
  final border = <int>[
    for (var y = 0; y < height; y++)
      for (var x = 0; x < width; x++)
        if ((x < 2 || y < 2 || x >= width - 2 || y >= height - 2) && opaque[y * width + x] == 1) y * width + x,
  ];
  final bg = _greedyClusters(lab, border, 12)
      .where((c) => c.count >= border.length * 0.15)
      .map((c) => c.center)
      .toList();

  // How far a pixel may be from the background color and still count as
  // background: tight for a clean studio white (so a cream shirt stays a
  // shirt), looser for textured floors or a bed with uneven light.
  final spread = [for (final i in border) bg.isEmpty ? 0.0 : bg.map((c) => _dist(lab, i, c)).reduce(math.min)]..sort();
  final p90 = spread.isEmpty ? 0.0 : spread[(spread.length * 0.9).floor().clamp(0, spread.length - 1)];
  final bgThreshold = (p90 * 1.6 + 4).clamp(6.0, 18.0);

  double bgDistance(int i) {
    var best = double.infinity;
    for (final c in bg) {
      best = math.min(best, _dist(lab, i, c));
    }
    return best;
  }

  // Flood from the edges through background-colored pixels, so the same
  // color *inside* the garment (a white collar on a white backdrop) stays.
  final isBg = Uint8List(n);
  final queue = Queue<int>();
  for (final i in border) {
    if (bgDistance(i) < bgThreshold) {
      isBg[i] = 1;
      queue.add(i);
    }
  }
  for (var i = 0; i < n; i++) {
    if (opaque[i] == 0) isBg[i] = 1;
  }
  while (queue.isNotEmpty) {
    final i = queue.removeFirst();
    final x = i % width, y = i ~/ width;
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
      final j = ny * width + nx;
      if (isBg[j] == 0 && bgDistance(j) < bgThreshold) {
        isBg[j] = 1;
        queue.add(j);
      }
    }
  }

  final fg = [for (var i = 0; i < n; i++) if (isBg[i] == 0) i];
  if (fg.length < n * 0.04) {
    // Nothing stands out from the background: most likely a garment the
    // same color as its backdrop (a white shirt on white).
    return bg.isEmpty ? const [] : [_toArgb(bg.first)];
  }

  final step = math.max(1, fg.length ~/ _maxClusterSamples);
  final sample = [for (var k = 0; k < fg.length; k += step) fg[k]];
  final clusters = _merge(_kMeans(lab, sample, 5), _mergeThreshold)
    ..sort((a, b) => b.count.compareTo(a.count));
  final colors = [
    for (final c in clusters.take(_maxColors))
      if (c.count >= sample.length * _minShare) c.center,
  ];

  // Stripes, checks, prints: thin enough that hardly any pixel is purely
  // the pattern color, so clustering blends them into the base fabric.
  for (final pattern in _patternColors(lab, isBg, width, height)) {
    if (colors.length >= _maxColors) break;
    // Plain ΔE here, not [_sameColor]: a pattern is by definition a detail
    // that stands out locally, never light/shadow on the same fabric.
    if (!colors.any((c) => _labDist(c, pattern) < _mergeThreshold)) colors.add(pattern);
  }
  return [for (final c in colors) _toArgb(c)];
}

/// Pattern pixels differ in lightness from their close surroundings (a few
/// pixels) by more than this; shading changes too slowly to.
const _patternContrast = 10.0;

/// A pattern must cover at least this share of the garment's inner area —
/// low enough for sparse pinstripes (2 px every 40 px is 5%), above the
/// ~1–2% buttons, seams or a small logo come to.
const _minPatternShare = 0.04;

/// Colors of a fine pattern on the garment — dark details (dark stripes on
/// a light shirt) and/or light ones (white stripes on navy). Each is taken
/// from its most pronounced pixels, the ones least blended with the base.
List<_Lab> _patternColors(Float32List lab, Uint8List isBg, int width, int height) {
  const r = 3; // window 7×7
  final w1 = width + 1;
  final sumL = Float64List(w1 * (height + 1));
  final cntFg = Int32List(w1 * (height + 1));
  final cntBg = Int32List(w1 * (height + 1));
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = y * width + x, o = (y + 1) * w1 + x + 1;
      final bg = isBg[i] == 1;
      sumL[o] = (bg ? 0 : lab[i * 3]) + sumL[o - 1] + sumL[o - w1] - sumL[o - w1 - 1];
      cntFg[o] = (bg ? 0 : 1) + cntFg[o - 1] + cntFg[o - w1] - cntFg[o - w1 - 1];
      cntBg[o] = (bg ? 1 : 0) + cntBg[o - 1] + cntBg[o - w1] - cntBg[o - w1 - 1];
    }
  }
  T box<T extends num>(List<T> a, int x0, int y0, int x1, int y1) =>
      (a[y1 * w1 + x1] - a[y0 * w1 + x1] - a[y1 * w1 + x0] + a[y0 * w1 + x0]) as T;

  final dark = <int>[], light = <int>[];
  var inner = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = y * width + x;
      if (isBg[i] == 1) continue;
      final x0 = math.max(0, x - r), y0 = math.max(0, y - r);
      final x1 = math.min(width, x + r + 1), y1 = math.min(height, y + r + 1);
      // Skip the garment's outline — next to the background every pixel
      // looks like a "detail".
      if (box(cntBg, x0, y0, x1, y1) > 0) continue;
      inner++;
      final d = lab[i * 3] - box(sumL, x0, y0, x1, y1) / box(cntFg, x0, y0, x1, y1);
      if (d < -_patternContrast) dark.add(i);
      if (d > _patternContrast) light.add(i);
    }
  }
  if (inner == 0) return const [];

  _Lab extreme(List<int> px, {required bool darkest}) {
    px.sort((a, b) => darkest ? lab[a * 3].compareTo(lab[b * 3]) : lab[b * 3].compareTo(lab[a * 3]));
    final top = px.take(math.max(1, (px.length * 0.2).round())).toList();
    var l = 0.0, a = 0.0, b = 0.0;
    for (final i in top) {
      l += lab[i * 3];
      a += lab[i * 3 + 1];
      b += lab[i * 3 + 2];
    }
    return (l / top.length, a / top.length, b / top.length);
  }

  return [
    if (dark.length >= inner * _minPatternShare) extreme(dark, darkest: true),
    if (light.length >= inner * _minPatternShare) extreme(light, darkest: false),
  ];
}

typedef _Lab = (double, double, double);

class _Cluster {
  _Lab center;
  int count;
  _Cluster(this.center, this.count);
}

double _dist(Float32List lab, int i, _Lab c) {
  final dl = lab[i * 3] - c.$1, da = lab[i * 3 + 1] - c.$2, db = lab[i * 3 + 2] - c.$3;
  return math.sqrt(dl * dl + da * da + db * db);
}

double _labDist(_Lab a, _Lab b) {
  final dl = a.$1 - b.$1, da = a.$2 - b.$2, db = a.$3 - b.$3;
  return math.sqrt(dl * dl + da * da + db * db);
}

/// One pass: each pixel joins the first cluster within [radius], else
/// starts its own. Cheap and good enough for the few edge colors.
List<_Cluster> _greedyClusters(Float32List lab, List<int> pixels, double radius) {
  final clusters = <_Cluster>[];
  final sums = <List<double>>[];
  for (final i in pixels) {
    var k = clusters.indexWhere((c) => _dist(lab, i, c.center) < radius);
    if (k < 0) {
      clusters.add(_Cluster((lab[i * 3], lab[i * 3 + 1], lab[i * 3 + 2]), 0));
      sums.add([0, 0, 0]);
      k = clusters.length - 1;
    }
    final s = sums[k];
    s[0] += lab[i * 3];
    s[1] += lab[i * 3 + 1];
    s[2] += lab[i * 3 + 2];
    final c = clusters[k]..count += 1;
    c.center = (s[0] / c.count, s[1] / c.count, s[2] / c.count);
  }
  return clusters;
}

/// k-means with k-means++ seeding (fixed seed, so results are stable).
List<_Cluster> _kMeans(Float32List lab, List<int> pixels, int k) {
  final rng = math.Random(7);
  final centers = <_Lab>[];
  final first = pixels[rng.nextInt(pixels.length)];
  centers.add((lab[first * 3], lab[first * 3 + 1], lab[first * 3 + 2]));
  final d2 = Float64List(pixels.length);
  while (centers.length < k) {
    var total = 0.0;
    for (var p = 0; p < pixels.length; p++) {
      var best = double.infinity;
      for (final c in centers) {
        final d = _dist(lab, pixels[p], c);
        best = math.min(best, d * d);
      }
      d2[p] = best;
      total += best;
    }
    if (total == 0) break;
    var r = rng.nextDouble() * total;
    var pick = 0;
    while (pick < pixels.length - 1 && (r -= d2[pick]) > 0) {
      pick++;
    }
    final i = pixels[pick];
    centers.add((lab[i * 3], lab[i * 3 + 1], lab[i * 3 + 2]));
  }

  var counts = List.filled(centers.length, 0);
  for (var iter = 0; iter < 12; iter++) {
    final sums = List.generate(centers.length, (_) => [0.0, 0.0, 0.0]);
    counts = List.filled(centers.length, 0);
    for (final i in pixels) {
      var best = 0;
      var bestD = double.infinity;
      for (var c = 0; c < centers.length; c++) {
        final d = _dist(lab, i, centers[c]);
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      sums[best][0] += lab[i * 3];
      sums[best][1] += lab[i * 3 + 1];
      sums[best][2] += lab[i * 3 + 2];
      counts[best]++;
    }
    for (var c = 0; c < centers.length; c++) {
      if (counts[c] > 0) {
        centers[c] = (sums[c][0] / counts[c], sums[c][1] / counts[c], sums[c][2] / counts[c]);
      }
    }
  }
  return [
    for (var c = 0; c < centers.length; c++)
      if (counts[c] > 0) _Cluster(centers[c], counts[c]),
  ];
}

bool _sameColor(_Lab a, _Lab b, double radius) {
  if (_labDist(a, b) < radius) return true;
  final dab = math.sqrt(math.pow(a.$2 - b.$2, 2) + math.pow(a.$3 - b.$3, 2));
  return dab < _shadeMaxAb && (a.$1 - b.$1).abs() < _shadeMaxL;
}

/// Repeatedly joins the two closest clusters that are the same color (see
/// [_sameColor]) — including light and shadow on one fabric.
List<_Cluster> _merge(List<_Cluster> clusters, double radius) {
  final out = [...clusters];
  while (true) {
    var bi = -1, bj = -1;
    var best = double.infinity;
    for (var i = 0; i < out.length; i++) {
      for (var j = i + 1; j < out.length; j++) {
        if (!_sameColor(out[i].center, out[j].center, radius)) continue;
        final d = _labDist(out[i].center, out[j].center);
        if (d < best) {
          best = d;
          bi = i;
          bj = j;
        }
      }
    }
    if (bi < 0) return out;
    final a = out[bi], b = out[bj];
    final t = a.count + b.count;
    a.center = (
      (a.center.$1 * a.count + b.center.$1 * b.count) / t,
      (a.center.$2 * a.count + b.center.$2 * b.count) / t,
      (a.center.$3 * a.count + b.center.$3 * b.count) / t,
    );
    a.count = t;
    out.removeAt(bj);
  }
}

final _linearTable = Float64List.fromList([
  for (var v = 0; v < 256; v++)
    v / 255 <= 0.04045 ? v / 255 / 12.92 : math.pow((v / 255 + 0.055) / 1.055, 2.4).toDouble(),
]);

double _linear(int v) => _linearTable[v];

int _gamma(double c) {
  final v = c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
  return (v * 255).round().clamp(0, 255);
}

const _xn = 0.95047, _yn = 1.0, _zn = 1.08883;

double _f(double t) => t > 216 / 24389 ? math.pow(t, 1 / 3).toDouble() : (24389 / 27 * t + 16) / 116;

double _fInv(double t) => t * t * t > 216 / 24389 ? t * t * t : (116 * t - 16) / (24389 / 27);

_Lab _toLab(int r8, int g8, int b8) {
  final r = _linear(r8), g = _linear(g8), b = _linear(b8);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / _xn;
  final y = (0.2126 * r + 0.7152 * g + 0.0722 * b) / _yn;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / _zn;
  final fx = _f(x), fy = _f(y), fz = _f(z);
  return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
}

int _toArgb(_Lab c) {
  final fy = (c.$1 + 16) / 116;
  final fx = fy + c.$2 / 500;
  final fz = fy - c.$3 / 200;
  final x = _fInv(fx) * _xn, y = _fInv(fy) * _yn, z = _fInv(fz) * _zn;
  final r = 3.2406 * x - 1.5372 * y - 0.4986 * z;
  final g = -0.9689 * x + 1.8758 * y + 0.0415 * z;
  final b = 0.0557 * x - 0.2040 * y + 1.0570 * z;
  return 0xFF000000 | _gamma(r) << 16 | _gamma(g) << 8 | _gamma(b);
}
