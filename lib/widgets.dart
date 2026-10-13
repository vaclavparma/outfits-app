import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'theme.dart';

/// Diagonal hatch pattern used as a placeholder for garments without a photo,
/// matching the `repeating-linear-gradient(135deg, ...)` texture in the
/// mockup. Fills whatever box it's given — safe to use directly as a
/// `Container.child` or as a plain (non-`Positioned`) `Stack` child.
class DiagonalStripes extends StatelessWidget {
  const DiagonalStripes({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: CustomPaint(painter: _StripePainter(AppColors.ink.withValues(alpha: 0.05))));
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  _StripePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6;
    const spacing = 11.0;
    final diag = size.width + size.height;
    for (double x = -diag; x < diag; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  // Repaints on a light/dark switch; otherwise the stripes never change.
  @override
  bool shouldRepaint(_StripePainter oldDelegate) => oldDelegate.color != color;
}

/// A garment photo, decoded at roughly the size it's actually displayed at
/// (rather than full camera resolution) and falling back to
/// [DiagonalStripes] if the file is missing or unreadable — so callers don't
/// need to stat the file on every build just to pick a placeholder.
class GarmentImage extends StatelessWidget {
  final String path;
  const GarmentImage(this.path, {super.key});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        // Letterbox fill for an oddly-shaped photo (very tall/wide) that
        // BoxFit.contain leaves bars around, rather than cropping it.
        color: Colors.white,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          cacheWidth: constraints.maxWidth.isFinite ? (constraints.maxWidth * dpr).round() : null,
          errorBuilder: (context, error, stackTrace) => const DiagonalStripes(),
        ),
      ),
    );
  }
}

/// A garment "card": rounded, textured or photo-filled tile with a small
/// uppercase mono slot label and a name/type caption, as used across the
/// outfit canvas, wardrobe and pick sheets.
class GarmentCard extends StatelessWidget {
  final double width;
  final double height;
  final double rotationDeg;
  final String? slotLabel;
  final String? name;
  final String caption;
  final String? imagePath;
  final VoidCallback? onTap;
  final void Function(int direction)? onSwipe;

  /// A short hold opens the photo full screen (see [openPhotoViewer]).
  final bool zoomable;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final Alignment captionAlign;

  const GarmentCard({
    super.key,
    required this.width,
    required this.height,
    this.rotationDeg = 0,
    this.slotLabel,
    this.name,
    this.caption = '',
    this.imagePath,
    this.onTap,
    this.onSwipe,
    this.zoomable = false,
    this.borderColor,
    this.shadow,
    this.captionAlign = Alignment.bottomLeft,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
        boxShadow: shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasImage) Positioned.fill(child: GarmentImage(imagePath!)) else const DiagonalStripes(),
          // Only darken the bottom of the photo when there's actually a
          // caption sitting on top of it — otherwise this was just dimming
          // the photo itself for no reason (e.g. every card on the outfit
          // screen, which never shows a caption over its photo).
          if (hasImage && ((name != null && name!.isNotEmpty) || caption.isNotEmpty))
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                    stops: const [0.55, 1],
                  ),
                ),
              ),
            ),
          if (slotLabel != null)
            Positioned(
              top: 11,
              left: 12,
              child: Text(
                slotLabel!,
                style: AppText.mono(
                  size: 8,
                  letterSpacing: 1.1,
                  color: hasImage ? Colors.white.withValues(alpha: 0.85) : AppColors.mutedLabel,
                ),
              ),
            ),
          if ((name != null && name!.isNotEmpty) || caption.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name != null && name!.isNotEmpty)
                    Text(
                      name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(size: 13, color: hasImage ? Colors.white : AppColors.inkSoft),
                    ),
                  if (caption.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: name != null && name!.isNotEmpty ? 3 : 0),
                      child: Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(
                          size: 8.5,
                          letterSpacing: 0.6,
                          color: hasImage ? Colors.white.withValues(alpha: 0.75) : AppColors.mutedTag,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    if (rotationDeg != 0) {
      card = Transform.rotate(angle: rotationDeg * math.pi / 180, child: card);
    }

    final gestures = GestureDetector(
      onTap: onTap,
      onHorizontalDragEnd: onSwipe == null
          ? null
          : (details) {
              final v = details.primaryVelocity ?? 0;
              if (v.abs() > 120) onSwipe!(v < 0 ? 1 : -1);
            },
      child: card,
    );
    final path = imagePath;
    if (!zoomable || path == null) return gestures;
    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: photoHoldDuration),
          (r) => r.onLongPress = () {
            HapticFeedback.mediumImpact();
            openPhotoViewer(context, path);
          },
        ),
      },
      child: gestures,
    );
  }
}

/// Small pill-shaped chip used for tags and categories, toggling between an
/// idle outline state and a filled "active" state.
class SelectChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final double height;
  final bool mono;

  const SelectChip({
    super.key,
    required this.label,
    required this.active,
    this.onTap,
    this.height = 30,
    this.mono = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.accentDark : AppColors.surface;
    final border = active ? AppColors.accentDark : AppColors.chipBorderIdle;
    final color = active ? Colors.white : AppColors.chipTextIdle;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: border),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: mono
                ? AppText.mono(size: 11, letterSpacing: 0.5, color: color)
                : AppText.sans(size: 12, color: color),
          ),
        ),
      ),
    );
  }
}

/// Back arrow for pushed screens (a type, settings, an item). Opaque and sized to
/// a full 48×48 target — a plain GestureDetector only reacts to taps on the
/// icon's own pixels, which made it easy to miss.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
      ),
    );
  }
}

/// Small round icon-only button (the "+" add button, the "x" remove button).
class RoundIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? borderColor;

  const RoundIconButton({
    super.key,
    required this.child,
    this.onTap,
    this.size = 40,
    this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? AppColors.ink,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Dashed-border "+" tile used as the trailing cell in a grid (or list) to
/// add a new item — a garment, a type...
class AddTile extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const AddTile({super.key, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dashedBorder),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+',
              style: AppText.sans(size: 22, weight: FontWeight.w300, color: AppColors.mutedSoft),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppText.mono(size: 9, letterSpacing: 0.6, color: AppColors.mutedSoft)),
          ],
        ),
      ),
    );
  }
}

/// Search input above the wardrobe and the outfit pickers — reports every
/// change via [onChanged], with a clear button once something's typed.
class SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final Color? fillColor;

  /// Defaults to "search clothes".
  final String? hint;

  const SearchField({super.key, required this.onChanged, this.fillColor, this.hint});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.cardBorder),
    );
    return TextField(
      controller: _controller,
      onChanged: _changed,
      textInputAction: TextInputAction.search,
      style: AppText.sans(size: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: widget.hint ?? AppLocalizations.of(context)!.searchHint,
        hintStyle: AppText.sans(size: 14, color: AppColors.mutedTag),
        prefixIcon: Icon(Icons.search, size: 19, color: AppColors.mutedSoft),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 17, color: AppColors.mutedSoft),
                onPressed: () {
                  _controller.clear();
                  _changed('');
                },
              ),
        filled: true,
        fillColor: widget.fillColor ?? AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        border: border,
        enabledBorder: border,
      ),
    );
  }
}

/// Shared "are you sure" dialog for destructive actions (deleting a
/// type, item, outfit...). Returns true only if the user
/// confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: AppText.sans(size: 16, color: AppColors.ink)),
      content: Text(message, style: AppText.sans(size: 13, color: AppColors.label, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            AppLocalizations.of(dialogContext)!.cancel,
            style: AppText.sans(size: 13, color: AppColors.muted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.accent),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// A message with a single "OK" — for telling why something can't be done.
Future<void> infoDialog(BuildContext context, {required String title, required String message}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: AppText.sans(size: 16, color: AppColors.ink)),
      content: Text(message, style: AppText.sans(size: 13, color: AppColors.label, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            AppLocalizations.of(dialogContext)!.ok,
            style: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.accent),
          ),
        ),
      ],
    ),
  );
}

/// Shared text-entry dialog (used for both renaming and creating) — a
/// titled text field pre-filled with [initialValue], returning the edited
/// text or null if cancelled.
Future<String?> promptTextDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  String? hintText,
  required String confirmLabel,
  bool Function(String name)? isTaken,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _TextPromptDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      confirmLabel: confirmLabel,
      isTaken: isTaken,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String? hintText;
  final String confirmLabel;

  /// Says a name is already used — shown as an error, and it can't be
  /// confirmed (neither can a blank one).
  final bool Function(String name)? isTaken;

  const _TextPromptDialog({
    required this.title,
    required this.initialValue,
    this.hintText,
    required this.confirmLabel,
    this.isTaken,
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _controller.text.trim();
    final taken = name.isNotEmpty && (widget.isTaken?.call(name) ?? false);
    final canConfirm = name.isNotEmpty && !taken;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.title, style: AppText.sans(size: 16, color: AppColors.ink)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (canConfirm) Navigator.of(context).pop(_controller.text);
        },
        style: AppText.sans(size: 14, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppText.sans(size: 14, color: AppColors.mutedTag),
          errorText: taken ? AppLocalizations.of(context)!.nameTaken : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel, style: AppText.sans(size: 13, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(_controller.text) : null,
          child: Text(
            widget.confirmLabel,
            style: AppText.sans(
              size: 13,
              weight: FontWeight.w500,
              color: canConfirm ? AppColors.accent : AppColors.mutedSoft,
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact collage of item photos, so a group reads at a glance — one
/// big tile for a single item, a big-plus-stacked split for 2-3, and a full
/// 2x2 grid for 4. Used for the type folders in the wardrobe.
class OutfitCollage extends StatelessWidget {
  final List<ClothingItem> items;
  const OutfitCollage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final shown = items.take(4).toList();
    if (shown.isEmpty) {
      return const DiagonalStripes();
    }
    if (shown.length == 1) {
      return _tile(shown[0]);
    }
    if (shown.length >= 4) {
      return GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: shown.take(4).map(_tile).toList(),
      );
    }
    // 2 or 3 items: one big tile on the left, the rest stacked on the right.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(padding: const EdgeInsets.only(right: 2), child: _tile(shown[0])),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              for (var i = 1; i < shown.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: i > 1 ? 1 : 0, bottom: i < shown.length - 1 ? 1 : 0),
                    child: _tile(shown[i]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(ClothingItem it) {
    final path = it.imagePath;
    return Container(color: AppColors.cardFill, child: path == null ? const DiagonalStripes() : GarmentImage(path));
  }
}

/// How long to hold a garment photo before it opens full screen — shorter
/// than the system long-press (500 ms) so it feels like a quick peek.
const photoHoldDuration = Duration(milliseconds: 300);

/// Opens [path] full screen over everything (sheets included): pinch or
/// double-tap to zoom, × / back / a downward flick to close.
void openPhotoViewer(BuildContext context, String path) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (_, _, _) => _PhotoViewer(path: path),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  final String path;
  const _PhotoViewer({required this.path});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> with SingleTickerProviderStateMixin {
  static const _doubleTapScale = 2.5;

  final _transform = TransformationController();
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => _transform.value = _zoomTween!.evaluate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOut)));
  Matrix4Tween? _zoomTween;
  Offset? _doubleTapAt;

  // Flick-down-to-close, only while not zoomed in (then a drag pans).
  Offset? _dragStart;
  Duration? _dragStartTime;
  int _pointers = 0;

  bool get _zoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  @override
  void dispose() {
    _zoomAnim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _zoomTween = Matrix4Tween(begin: _transform.value.clone(), end: target);
    _zoomAnim.forward(from: 0);
  }

  void _onDoubleTap() {
    if (_zoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    // Zoom in around the tapped point.
    final p = _doubleTapAt ?? Offset.zero;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(-p.dx * (_doubleTapScale - 1), -p.dy * (_doubleTapScale - 1), 0, 1)
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: (e) {
                  _pointers++;
                  _dragStart = _pointers == 1 && !_zoomed ? e.position : null;
                  _dragStartTime = e.timeStamp;
                },
                onPointerCancel: (_) {
                  _pointers = math.max(0, _pointers - 1);
                  _dragStart = null;
                },
                onPointerUp: (e) {
                  _pointers = math.max(0, _pointers - 1);
                  final start = _dragStart, t0 = _dragStartTime;
                  _dragStart = null;
                  if (start == null || t0 == null || _zoomed) return;
                  final d = e.position - start;
                  if (d.dy > 90 && d.dy > d.dx.abs() * 1.5 && e.timeStamp - t0 < const Duration(milliseconds: 500)) {
                    Navigator.of(context).pop();
                  }
                },
                child: GestureDetector(
                  onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
                  onDoubleTap: _onDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 5,
                    child: SizedBox.expand(
                      child: Image.file(
                        File(widget.path),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Semantics(
                    button: true,
                    label: l10n.close,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close, size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The widest the app's content gets. On a phone everything is narrower
/// than this; on an iPad the content sits in a centered column this wide,
/// with the background running edge to edge.
const kMaxContentWidth = 720.0;

/// Centers [child] in a column at most [maxWidth] wide (full width when
/// the screen is narrower), top-aligned.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentWidth({super.key, required this.child, this.maxWidth = kMaxContentWidth});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: math.min(constraints.maxWidth, maxWidth), child: child),
      ),
    );
  }
}

/// Grid columns for content laid out at [phone] columns on a phone — one
/// more once the content column is wide (iPad), so tiles don't balloon.
int gridColumns(BuildContext context, int phone) {
  final width = math.min(MediaQuery.sizeOf(context).width, kMaxContentWidth);
  return width >= 600 ? phone + 1 : phone;
}

/// A small rounded bar split into the garment's colors (1–3 equal parts) —
/// the item detail's color summary. [height] sets the size; the width
/// follows. Empty [colors] show as a neutral placeholder.
class ColorBar extends StatelessWidget {
  final List<int> colors;
  final double height;
  const ColorBar({super.key, required this.colors, this.height = 16});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height * 0.3);
    return Container(
      width: height * 2.6,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.cardBorder),
        color: AppColors.cardFill,
      ),
      child: ClipRRect(
        borderRadius: radius,
        // stretch: a ColoredBox without a child takes the smallest height
        // it's allowed — 0 in a Row that only loosely bounds the height.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in colors) Expanded(child: ColoredBox(color: Color(c))),
          ],
        ),
      ),
    );
  }
}


/// One tab of [TypeTabs]: [key] is a type id, or `null` for "all".
typedef TypeTab = ({String? key, String label, int count});

/// The type tabs for [items] (all of [kind]): "all", then every type that
/// has any of them. Empty when that would only repeat "all" — every item
/// of the same type.
List<TypeTab> typeTabsFor(ClothingKind? kind, List<ClothingItem> items, AppLocalizations l10n) {
  final tabs = <TypeTab>[
    for (final t in kind?.types ?? const <ClothingType>[])
      if (items.where((i) => i.typeId == t.id).length case final n when n > 0) (key: t.id, label: t.name, count: n),
  ];
  if (tabs.length < 2) return const [];
  return [(key: null, label: l10n.all, count: items.length), ...tabs];
}

/// Whether [item] belongs under the [TypeTab] with [key].
bool inTypeTab(ClothingItem item, String? key) => key == null || item.typeId == key;

/// A row of underlined tabs ("Vše 5  Košile 2  Mikiny 3"), scrolling
/// sideways when they don't fit.
class TypeTabs extends StatelessWidget {
  final List<TypeTab> tabs;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final EdgeInsetsGeometry? padding;

  const TypeTabs({super.key, required this.tabs, required this.selected, required this.onSelect, this.padding});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final t in tabs)
            Semantics(
              button: true,
              selected: t.key == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(t.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 18),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: t.key == selected ? AppColors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        t.label,
                        style: AppText.sans(
                          size: 13.5,
                          weight: t.key == selected ? FontWeight.w500 : FontWeight.w400,
                          color: t.key == selected ? AppColors.ink : AppColors.mutedTag,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${t.count}', style: AppText.mono(size: 10, color: AppColors.mutedSoft)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A saved outfit as it was laid out on the canvas, in miniature: the
/// cards placed as on a canvas of the reference size ([CanvasGeometry]),
/// cropped to the area they cover and scaled to fit. Photos are decoded for
/// the small size they're shown at, not the virtual one.
class OutfitPreview extends StatelessWidget {
  final List<SavedSlot> slots;
  final ClothingItem? Function(String id) itemById;

  /// What to call an item — shown on a card that has no photo.
  final String Function(ClothingItem item) nameOf;

  const OutfitPreview({super.key, required this.slots, required this.itemById, required this.nameOf});

  @override
  Widget build(BuildContext context) {
    const w = CanvasGeometry.refWidth, h = CanvasGeometry.refHeight;
    final cards = [
      for (final s in slots)
        (
          slot: s,
          rect: () {
            final r = CanvasGeometry.cardRect(width: w, height: h, unit: 1, x: s.x, y: s.y, scale: s.scale);
            return Rect.fromLTWH(r.left, r.top, r.width, r.height);
          }(),
        ),
    ];
    if (cards.isEmpty) return const SizedBox.expand();
    // Room around the cards for their tilt and shadow.
    final bounds = cards.map((c) => c.rect).reduce((a, b) => a.expandToInclude(b)).inflate(18);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(constraints.maxWidth / bounds.width, constraints.maxHeight / bounds.height);
        final media = MediaQuery.of(context);
        // Transparent: the card it sits in draws the background (and its
        // border, which a fill here would paint over).
        return ClipRect(
          child: Center(
            child: FittedBox(
              child: MediaQuery(
                data: media.copyWith(devicePixelRatio: media.devicePixelRatio * scale),
                child: SizedBox(
                  width: bounds.width,
                  height: bounds.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final c in cards)
                        Positioned.fromRect(
                          rect: c.rect.shift(-bounds.topLeft),
                          child: GarmentCard(
                            width: c.rect.width,
                            height: c.rect.height,
                            rotationDeg: CanvasGeometry.tilt(c.slot.id),
                            imagePath: c.slot.itemId == null ? null : itemById(c.slot.itemId!)?.imagePath,
                            // Without a photo, its name says what it is.
                            name: switch (c.slot.itemId == null ? null : itemById(c.slot.itemId!)) {
                              final it? when it.imagePath == null => nameOf(it),
                              _ => null,
                            },
                            shadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
