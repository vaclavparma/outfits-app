import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    return SizedBox.expand(child: CustomPaint(painter: _StripePainter()));
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.05)
      ..strokeWidth = 6;
    const spacing = 11.0;
    final diag = size.width + size.height;
    for (double x = -diag; x < diag; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      builder: (context, constraints) => Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round()
            : null,
        errorBuilder: (context, error, stackTrace) => const DiagonalStripes(),
      ),
    );
  }
}

/// A garment "card": rounded, textured or photo-filled tile with a small
/// uppercase mono slot label and a name/tags caption, as used across the
/// outfit builder, wardrobe grid and pick sheets.
class GarmentCard extends StatelessWidget {
  final double width;
  final double height;
  final double rotationDeg;
  final String? slotLabel;
  final String? name;
  final String tags;
  final String? imagePath;
  final VoidCallback? onTap;
  final void Function(int direction)? onSwipe;
  final Color borderColor;
  final List<BoxShadow>? shadow;
  final Alignment captionAlign;

  const GarmentCard({
    super.key,
    required this.width,
    required this.height,
    this.rotationDeg = 0,
    this.slotLabel,
    this.name,
    this.tags = '',
    this.imagePath,
    this.onTap,
    this.onSwipe,
    this.borderColor = AppColors.cardBorder,
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
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasImage)
            Positioned.fill(child: GarmentImage(imagePath!))
          else
            const DiagonalStripes(),
          if (hasImage)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
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
                  color: hasImage
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.mutedLabel,
                ),
              ),
            ),
          if ((name != null && name!.isNotEmpty) || tags.isNotEmpty)
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
                      style: AppText.sans(
                        size: 13,
                        color: hasImage ? Colors.white : AppColors.inkSoft,
                      ),
                    ),
                  if (tags.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: name != null && name!.isNotEmpty ? 3 : 0,
                      ),
                      child: Text(
                        tags,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(
                          size: 8.5,
                          letterSpacing: 0.6,
                          color: hasImage
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.mutedTag,
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

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragEnd: onSwipe == null
          ? null
          : (details) {
              final v = details.primaryVelocity ?? 0;
              if (v.abs() > 120) onSwipe!(v < 0 ? 1 : -1);
            },
      child: card,
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
    final bg = active ? AppColors.ink : Colors.white;
    final border = active ? AppColors.ink : AppColors.chipBorderIdle;
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

/// Small round icon-only button (the "+" add button, the "x" remove button).
class RoundIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color background;
  final Color? borderColor;

  const RoundIconButton({
    super.key,
    required this.child,
    this.onTap,
    this.size = 40,
    this.background = AppColors.ink,
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
          color: background,
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
/// add a new item — a garment, a layer, a collection...
class AddTile extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const AddTile({super.key, required this.onTap, this.label = 'přidat'});

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
              style: AppText.sans(
                size: 22,
                weight: FontWeight.w300,
                color: AppColors.mutedSoft,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.mono(
                size: 9,
                letterSpacing: 0.6,
                color: AppColors.mutedSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header used above wardrobe grids and collection lists.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.sans(size: 13, color: AppColors.ink)),
          if (trailing != null)
            Text(
              trailing!,
              style: AppText.mono(
                size: 9,
                letterSpacing: 1,
                color: AppColors.mutedSoft,
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared "are you sure" dialog for destructive actions (deleting a
/// collection, tag, item, outfit...). Returns true only if the user
/// confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Smazat',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text(title, style: AppText.sans(size: 16, color: AppColors.ink)),
      content: Text(
        message,
        style: AppText.sans(size: 13, color: AppColors.label, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Zrušit',
            style: AppText.sans(size: 13, color: AppColors.muted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: AppText.sans(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Shared text-entry dialog (used for both renaming and creating) — a
/// titled text field pre-filled with [initialValue], returning the edited
/// text or null if cancelled.
Future<String?> promptTextDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  String? hintText,
  String confirmLabel = 'Uložit',
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _TextPromptDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String? hintText;
  final String confirmLabel;
  const _TextPromptDialog({
    required this.title,
    required this.initialValue,
    this.hintText,
    this.confirmLabel = 'Uložit',
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.title,
        style: AppText.sans(size: 16, color: AppColors.ink),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: AppText.sans(size: 14, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppText.sans(size: 14, color: AppColors.mutedTag),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Zrušit',
            style: AppText.sans(size: 13, color: AppColors.muted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(
            widget.confirmLabel,
            style: AppText.sans(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact collage of an outfit's item photos, so it reads at a glance —
/// one big tile for a single item, a big-plus-stacked split for 2-3, and a
/// full 2x2 grid for 4. Used both for an outfit's own card and as a
/// collection's cover preview (its most recent outfit).
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
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: _tile(shown[0]),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              for (var i = 1; i < shown.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: i > 1 ? 1 : 0,
                      bottom: i < shown.length - 1 ? 1 : 0,
                    ),
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
    return Container(
      color: AppColors.cardFill,
      child: path == null ? const DiagonalStripes() : GarmentImage(path),
    );
  }
}
