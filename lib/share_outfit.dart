import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// The platform's share glyph: the box with an arrow on iOS, the three
/// connected dots elsewhere.
IconData shareIcon(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => Icons.ios_share,
  _ => Icons.share_outlined,
};

/// The share sheet's content: a preview of the image an outfit is shared
/// as ([OutfitShareCard]) and the button that makes it and hands it to the
/// system share sheet. The image is made on the device, from the preview
/// itself, and goes only where the user sends it.
class ShareOutfitPanel extends StatefulWidget {
  /// The layout to share — the canvas, or a saved outfit's. Cards with
  /// nothing on them are left out.
  final List<SavedSlot> slots;

  const ShareOutfitPanel({super.key, required this.slots});

  /// How much of the screen the sheet may take — the preview is sized to
  /// fit in it.
  static const sheetHeightFactor = 0.9;

  @override
  State<ShareOutfitPanel> createState() => _ShareOutfitPanelState();
}

class _ShareOutfitPanelState extends State<ShareOutfitPanel> {
  /// The width the image is exported at; its height follows the card's
  /// 9:16 (a phone story).
  static const _exportWidth = 1080.0;

  /// Photos are decoded at most this wide: about the largest a single
  /// card, made as big as it goes, ends up in the exported image.
  static const _photoWidth = 900;

  final _cardKey = GlobalKey();
  final _buttonKey = GlobalKey();

  late final List<SavedSlot> _slots;

  /// Decoded up front rather than left to [Image.file], which loads
  /// asynchronously — the image is taken from what's on screen, and a photo
  /// still loading would be missing from it. `null` until all are ready.
  Map<String, ui.Image>? _photos;
  ui.Image? _logo;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<WardrobeStore>();
    _slots = [
      for (final s in widget.slots)
        if (s.itemId != null && store.itemById(s.itemId!) != null) s,
    ];
    _load(store);
  }

  Future<void> _load(WardrobeStore store) async {
    final paths = {
      for (final s in _slots)
        if (store.itemById(s.itemId!)?.imagePath case final path?) s.itemId!: path,
    };
    final decoded = await Future.wait([
      for (final MapEntry(:key, :value) in paths.entries) _decodeFile(value).then((image) => (id: key, image: image)),
    ]);
    final logo = await _decodeAsset('assets/icon/app_icon_small.png');
    final photos = {
      for (final d in decoded)
        if (d.image case final image?) d.id: image,
    };
    if (!mounted) {
      for (final image in photos.values) {
        image.dispose();
      }
      logo?.dispose();
      return;
    }
    setState(() {
      _photos = photos;
      _logo = logo;
    });
  }

  /// `null` for a photo that's gone missing or won't decode — its card
  /// shows the same stripes as everywhere else then.
  static Future<ui.Image?> _decodeFile(String path) async {
    try {
      return await _decode(await File(path).readAsBytes(), width: _photoWidth);
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> _decodeAsset(String key) async {
    try {
      final data = await rootBundle.load(key);
      return await _decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image> _decode(Uint8List bytes, {int? width}) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: width, allowUpscaling: false);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void dispose() {
    for (final image in _photos?.values ?? const <ui.Image>[]) {
      image.dispose();
    }
    _logo?.dispose();
    super.dispose();
  }

  /// The preview, as a PNG in a folder of its own in the temp directory
  /// (emptied each time, so old images don't pile up).
  Future<File> _render() async {
    final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _exportWidth / OutfitShareCard.size.width);
    final ByteData? png;
    try {
      png = await image.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      image.dispose();
    }
    if (png == null) throw StateError('PNG encoding failed');
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'shared-outfit'));
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'outfit-${DateTime.now().millisecondsSinceEpoch}.png'));
    await file.writeAsBytes(png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes));
    return file;
  }

  Future<void> _share() async {
    if (_sharing || _photos == null) return;
    final l10n = AppLocalizations.of(context)!;
    // Where the share popover points from on iPad.
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      final file = await _render();
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        ),
      );
      // Sent (or saved) — done here. Dismissed, it stays open to try again.
      if (result.status == ShareResultStatus.success && mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) await infoDialog(context, title: l10n.shareOutfit, message: l10n.shareFailed);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final photos = _photos;
    final ready = photos != null && !_sharing;
    // As tall as the sheet leaves room for, above the button.
    final maxHeight = (MediaQuery.sizeOf(context).height * ShareOutfitPanel.sheetHeightFactor - 190).clamp(
      220.0,
      620.0,
    );
    final card = OutfitShareCard.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < maxHeight * card.aspectRatio
                ? constraints.maxWidth
                : maxHeight * card.aspectRatio;
            return Center(
              child: Container(
                width: width,
                height: width / card.aspectRatio,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.rowBorder),
                ),
                child: photos == null
                    ? Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentText),
                        ),
                      )
                    // Laid out at the card's own size and only scaled down
                    // to show here: the image is taken at that size, not
                    // the preview's.
                    : FittedBox(
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: OutfitShareCard(
                            slots: _slots,
                            itemById: store.itemById,
                            nameOf: store.displayName,
                            photos: photos,
                            logo: _logo,
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          enabled: ready,
          child: GestureDetector(
            key: _buttonKey,
            onTap: ready ? _share : null,
            child: AnimatedOpacity(
              opacity: ready ? 1 : 0.5,
              duration: motion(const Duration(milliseconds: 160)),
              child: Container(
                height: 46,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(23)),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(shareIcon(context), size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.share,
                      style: AppText.sans(size: 13, weight: FontWeight.w500, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The image an outfit is shared as: its cards laid out as on the canvas,
/// on the app's background, with a small app logo and its web address in
/// the bottom left corner.
/// Always [size] (9:16, a phone story) whatever the screen, and the text
/// isn't scaled by the system text size — it's a picture, not UI.
class OutfitShareCard extends StatelessWidget {
  static const size = Size(360, 640);

  final List<SavedSlot> slots;
  final ClothingItem? Function(String id) itemById;
  final String Function(ClothingItem item) nameOf;

  /// Decoded photos by item id (see [OutfitPreview.photoOf]).
  final Map<String, ui.Image> photos;
  final ui.Image? logo;

  const OutfitShareCard({
    super.key,
    required this.slots,
    required this.itemById,
    required this.nameOf,
    required this.photos,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling, boldText: false),
      child: ExcludeSemantics(
        child: SizedBox.fromSize(
          size: size,
          child: ColoredBox(
            color: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 18),
              child: Column(
                children: [
                  Expanded(
                    child: OutfitPreview(
                      slots: slots,
                      itemById: itemById,
                      nameOf: nameOf,
                      photoOf: (item) => switch (photos[item.id]) {
                        // White behind a photo that doesn't fill the card,
                        // as in [GarmentImage].
                        final image? => ColoredBox(
                          color: Colors.white,
                          child: RawImage(image: image, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                        ),
                        null => null,
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Small and to the side, like a signature — the outfit is
                  // what the image is about. The address says where the
                  // app is to be had, which the name alone wouldn't.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (logo case final logo?) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: RawImage(image: logo, width: 16, height: 16, filterQuality: FilterQuality.medium),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'theoutfits.app',
                          style: AppText.mono(size: 12, letterSpacing: 0.3, color: AppColors.label),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
