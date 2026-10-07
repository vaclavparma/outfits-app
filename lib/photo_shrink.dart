import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Longest edge, in pixels, a stored photo is scaled down to. New photos are
/// already capped to this when picked (see `_AddItemFormState._pick`); this
/// file shrinks the ones saved before that existed.
const int kMaxPhotoEdge = 1600;

const _doneKey = 'photos_shrunk_v1';

/// One-time pass that scales down every stored photo whose longest edge is
/// over [kMaxPhotoEdge], then records that in secure storage so it never
/// runs again. Safe to interrupt: each photo is replaced atomically, and
/// already-small photos are skipped, so a pass cut short just resumes on
/// the next launch. A photo that can't be decoded or wouldn't get smaller
/// is left exactly as it is.
Future<void> shrinkExistingPhotosOnce({
  FlutterSecureStorage storage = const FlutterSecureStorage(),
  Directory? imagesDir,
}) async {
  try {
    if (await storage.read(key: _doneKey) != null) return;
  } catch (_) {
    // Unreadable flag (e.g. a Keychain/Keystore hiccup) — just run the pass
    // again; it's a no-op for photos that are already small.
  }

  final dir = imagesDir ??
      Directory(p.join((await getApplicationDocumentsDirectory()).path, 'satnik_images'));
  var shrunk = 0;
  if (await dir.exists()) {
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      try {
        if (await shrinkPhoto(entity)) shrunk++;
      } catch (e) {
        if (kDebugMode) debugPrint('[photo_shrink] skipped ${entity.path}: $e');
      }
    }
  }
  if (kDebugMode) debugPrint('[photo_shrink] done, shrank $shrunk photo(s)');

  try {
    await storage.write(key: _doneKey, value: DateTime.now().toIso8601String());
  } catch (_) {
    // Next launch will just run it again.
  }
}

/// Scales [file] down in place so its longest edge is at most
/// [kMaxPhotoEdge]. Returns whether it was rewritten. JPEGs stay JPEG
/// (quality 85, same as newly picked photos) and PNGs stay PNG (they may
/// have transparency); anything else (GIF, real HEIC…) is left alone.
///
/// The format is read from the file's content, not its extension: on
/// Android, image_picker re-encodes a HEIC photo to JPEG but keeps the
/// `.heic` name, so stored photos can be JPEGs named `*.heic`. (Real HEIC
/// only gets through on Android < 9, which can't decode it at all.)
@visibleForTesting
Future<bool> shrinkPhoto(File file) async {
  final format = await _sniffFormat(file);
  if (format == null) return false;
  final isPng = format == _Format.png;

  final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final longEdge = descriptor.width > descriptor.height ? descriptor.width : descriptor.height;
  if (longEdge <= kMaxPhotoEdge) {
    descriptor.dispose();
    buffer.dispose();
    return false;
  }

  // Decoded natively, already downsampled — never holds the full 8K bitmap.
  // Only the width is given so the aspect ratio can't be distorted; any
  // overshoot (e.g. EXIF rotation swapping the edges) is trimmed below.
  final codec = await descriptor.instantiateCodec(
    targetWidth: (descriptor.width * kMaxPhotoEdge / longEdge).round(),
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final width = image.width;
  final height = image.height;
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  image.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  if (rgba == null) return false;

  final pixels = rgba.buffer.asUint8List();
  final encoded = await Isolate.run(() => _encode(pixels, width, height, isPng));

  // Only ever trade a photo for a smaller file.
  if (encoded.length >= await file.length()) return false;

  final tmp = File('${file.path}.shrink.tmp');
  await tmp.writeAsBytes(encoded, flush: true);
  if (!await file.exists()) {
    // Deleted (with its item) while this one was being processed.
    await tmp.delete();
    return false;
  }
  await tmp.rename(file.path);
  return true;
}

enum _Format { jpeg, png }

Future<_Format?> _sniffFormat(File file) async {
  final raf = await file.open();
  try {
    final head = await raf.read(4);
    if (head.length >= 3 && head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF) return _Format.jpeg;
    if (head.length == 4 && head[0] == 0x89 && head[1] == 0x50 && head[2] == 0x4E && head[3] == 0x47) {
      return _Format.png;
    }
    return null;
  } finally {
    await raf.close();
  }
}

Uint8List _encode(Uint8List rgba, int width, int height, bool png) {
  var im = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  if (width > kMaxPhotoEdge || height > kMaxPhotoEdge) {
    im = width >= height
        ? img.copyResize(im, width: kMaxPhotoEdge, interpolation: img.Interpolation.average)
        : img.copyResize(im, height: kMaxPhotoEdge, interpolation: img.Interpolation.average);
  }
  return png ? img.encodePng(im) : img.encodeJpg(im, quality: 85);
}
