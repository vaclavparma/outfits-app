import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// How many fingers are on canvas cards right now. Swiping between tabs
/// pauses while two are (a pinch), so resizing a card never turns the page
/// instead. (Holding a card to move it can't turn it either: the hold wins
/// before the finger moves.)
final ValueNotifier<int> canvasTouches = ValueNotifier(0);

/// Counts a finger landing on a card until it lifts — followed through the
/// pointer router rather than the card's own [Listener], since the card may
/// be gone by then (dropped on the bin).
void _trackCardTouch(PointerDownEvent down) {
  canvasTouches.value++;
  void route(PointerEvent e) {
    if (e is PointerUpEvent || e is PointerCancelEvent) {
      GestureBinding.instance.pointerRouter.removeRoute(down.pointer, route);
      canvasTouches.value = math.max(0, canvasTouches.value - 1);
    }
  }

  GestureBinding.instance.pointerRouter.addRoute(down.pointer, route);
}

/// The outfit canvas: a card per [CanvasSlot], wherever the user put it.
/// Tap a card to pick what it shows, pin it to keep it through Shuffle. Hold a card to drag it somewhere else (or onto
/// the bin that appears below, to remove it), pinch it to resize. The chips
/// below add a card of any kind.
class OutfitTab extends StatefulWidget {
  final void Function(String slotId) onPick;
  final VoidCallback onOpenSave;

  const OutfitTab({super.key, required this.onPick, required this.onOpenSave});

  @override
  State<OutfitTab> createState() => _OutfitTabState();
}

class _OutfitTabState extends State<OutfitTab> {
  /// How long a card is held before it lifts to be moved — short, since a
  /// tap is over well before it.
  static const _holdToMove = Duration(milliseconds: 125);

  /// The card being moved or resized, and where it is so far — committed to
  /// the store when the gesture ends, not on every frame.
  String? _active;
  Offset _drag = Offset.zero;

  /// How far a held card has been dragged. Kept apart from [_drag] and
  /// listened to by that card alone: following the finger only moves its
  /// already-painted layer, rather than rebuilding the whole canvas (all
  /// the photos and shadows) on every touch event — which left it a frame
  /// or two behind the finger.
  final _moveDrag = ValueNotifier(Offset.zero);
  double _startScale = 1;
  double _liveScale = 1;

  /// Held and being dragged (as opposed to pinched).
  bool _moving = false;
  bool _overBin = false;

  /// The most fingers seen in the current gesture on [_active] — only two
  /// (a pinch) move and resize the card.
  int _maxPointers = 0;

  /// A fresh key for each lift: the bin from the last one may still be
  /// fading out for a moment, and two can't share one key.
  GlobalKey _binKey = GlobalKey();

  /// The card a two-finger gesture belongs to, if one is under way. One
  /// card at a time is moved or resized: a second card held meanwhile is
  /// ignored rather than sharing (and corrupting) the gesture state.
  String? _scaleOwner;
  Size _size = Size.zero;
  double _unit = 1;

  /// Where [s]'s card sits, kept inside the canvas. (While held and
  /// dragged, that's where it started: [_moveDrag] moves it from there —
  /// freely, so it can follow the finger down to the bin.)
  Rect _boxFor(CanvasSlot s) {
    final active = s.id == _active;
    final r = CanvasGeometry.cardRect(
      width: _size.width,
      height: _size.height,
      unit: _unit,
      x: s.x,
      y: s.y,
      scale: active ? _liveScale : s.scale,
      dx: active ? _drag.dx : 0,
      dy: active ? _drag.dy : 0,
      // Where it's shown at rest, so lifting it doesn't make it jump.
      free: false,
    );
    return Rect.fromLTWH(r.left, r.top, r.width, r.height);
  }

  bool _isOverBin(Offset global) {
    final box = _binKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return (box.localToGlobal(Offset.zero) & box.size).inflate(12).contains(global);
  }

  @override
  void dispose() {
    _moveDrag.dispose();
    super.dispose();
  }

  void _begin(CanvasSlot s) {
    _active = s.id;
    _drag = Offset.zero;
    _moveDrag.value = Offset.zero;
    _maxPointers = 0;
    _startScale = _liveScale = s.scale;
  }

  /// Saves where the active card ended up (kept inside the canvas).
  void _commit(WardrobeStore store, CanvasSlot s) {
    if (_moving) _drag = _moveDrag.value;
    _moving = false;
    final box = _boxFor(s);
    store.moveSlot(s.id, box.center.dx / _size.width, box.center.dy / _size.height);
    store.scaleSlot(s.id, _liveScale);
    setState(() => _active = null);
  }

  void _endMove(WardrobeStore store, CanvasSlot s) {
    if (_overBin) {
      HapticFeedback.mediumImpact();
      store.removeSlot(s.id);
      setState(() {
        _active = null;
        _moving = false;
        _overBin = false;
      });
    } else {
      _commit(store, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(child: _canvas(context, store, l10n)),
        SizedBox(
          height: 52,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _moving ? _bin(l10n) : _addChips(store, l10n),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            children: [
              _ShuffleButton(label: l10n.shuffleButton, onTap: store.shuffle),
              const SizedBox(width: 10),
              Expanded(child: _SaveButton(onSave: widget.onOpenSave)),
            ],
          ),
        ),
      ],
    );
  }

  /// A chip per kind, to add a card of it.
  Widget _addChips(WardrobeStore store, AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const ValueKey('chips'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          for (final k in store.kinds)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: SelectChip(
                label: '+ ${k.name}',
                active: false,
                mono: false,
                height: 34,
                onTap: () {
                  if (store.canvasFull) {
                    store.flash(l10n.canvasFull(CanvasSlot.maxCount));
                    return;
                  }
                  HapticFeedback.selectionClick();
                  store.addSlot(k.id);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Where a held card can be dropped to take it off the canvas — a plain
  /// opaque bar that turns red once the card is over it.
  Widget _bin(AppLocalizations l10n) {
    final color = _overBin ? Colors.white : AppColors.label;
    return Padding(
      key: const ValueKey('bin'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: AnimatedScale(
        scale: _overBin && !reduceMotion ? 1.04 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          key: _binKey,
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _overBin ? AppColors.danger : AppColors.cardFill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _overBin ? AppColors.danger : AppColors.cardBorder),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 18, color: color),
              const SizedBox(width: 6),
              Text(l10n.dropToRemove, style: AppText.sans(size: 13, weight: FontWeight.w500, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas(BuildContext context, WardrobeStore store, AppLocalizations l10n) {
    final slots = store.visibleSlots;
    if (slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checkroom_outlined, size: 34, color: AppColors.mutedSoft),
              const SizedBox(height: 10),
              Text(
                l10n.canvasEmpty,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 13, color: AppColors.mutedTag, height: 1.45),
              ),
            ],
          ),
        ),
      );
    }
    // The card being handled paints on top.
    final ordered = [...slots.where((s) => s.id != _active), ...slots.where((s) => s.id == _active)];

    // The cards keep clear of the edges by [_inset], but the Stack spans
    // the whole area: a pin overhanging a card at the edge still gets taps
    // (they only reach what's inside the Stack).
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = _inset.deflateSize(constraints.biggest);
        _unit = CanvasGeometry.unitFor(_size.width, _size.height);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final s in ordered) _card(store, s, _boxFor(s).shift(Offset(_inset.left, _inset.top))),
          ],
        );
      },
    );
  }

  Widget _card(WardrobeStore store, CanvasSlot s, Rect box) {
    final item = store.itemInSlot(s.id);
    final lifted = s.id == _active && _moving;
    final card = GarmentCard(
      width: box.width,
      height: box.height,
      rotationDeg: CanvasGeometry.tilt(s.id),
      name: item == null ? '+ ${store.kindName(s.kindId)}' : null,
      imagePath: item?.imagePath,
      borderColor: lifted ? AppColors.accent : null,
      shadow: [
        BoxShadow(
          color: Color(lifted ? 0x33000000 : 0x14000000),
          blurRadius: lifted ? 18 : 6,
          offset: Offset(0, lifted ? 8 : 2),
        ),
      ],
    );

    void onScaleUpdate(ScaleUpdateDetails d) {
      if (_scaleOwner != s.id) return;
      setState(() {
        _maxPointers = math.max(_maxPointers, d.pointerCount);
        if (_maxPointers > 1) {
          _drag += d.focalPointDelta;
          if (d.pointerCount > 1) {
            _liveScale = (_startScale * d.scale).clamp(CanvasSlot.minScale, CanvasSlot.maxScale);
          }
        }
      });
    }

    void onScaleEnd(ScaleEndDetails d) {
      if (_scaleOwner != s.id) return;
      _scaleOwner = null;
      if (_maxPointers > 1) {
        _commit(store, s);
        return;
      }
      // A one-finger drag does nothing: what a card shows is picked by
      // tapping it.
      setState(() => _active = null);
    }

    final gestures = RawGestureDetector(
      gestures: {
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          TapGestureRecognizer.new,
          (r) => r.onTap = () => widget.onPick(s.id),
        ),
        // A short hold, then drag: move the card (or drop it on the bin).
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: _holdToMove),
          (r) => r
            ..onLongPressStart = (_) {
              // Another card is already being moved or resized.
              if (_active != null) return;
              HapticFeedback.mediumImpact();
              setState(() {
                _begin(s);
                _moving = true;
                _overBin = false;
                _binKey = GlobalKey();
              });
            }
            ..onLongPressMoveUpdate = (d) {
              if (!_moving || _active != s.id) return;
              _moveDrag.value = d.offsetFromOrigin;
              final over = _isOverBin(d.globalPosition);
              if (over == _overBin) return;
              if (over) HapticFeedback.selectionClick();
              setState(() => _overBin = over);
            }
            ..onLongPressEnd = (_) {
              if (_moving && _active == s.id) _endMove(store, s);
            }
            // Interrupted (a system gesture, a call): it stays where it was
            // taken to — never deleted, even if that's over the bin.
            ..onLongPressCancel = () {
              if (!_moving || _active != s.id) return;
              _overBin = false;
              _endMove(store, s);
            },
        ),
        // Two fingers resize (and move) the card.
        ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
          ScaleGestureRecognizer.new,
          (r) => r
            ..onStart = (_) {
              // Already being moved (a second finger landing on a held
              // card), or another card is in hand.
              if (_active != null) return;
              _scaleOwner = s.id;
              setState(() => _begin(s));
            }
            ..onUpdate = onScaleUpdate
            ..onEnd = onScaleEnd,
        ),
      },
      child: card,
    );

    // Laid out with a margin around the card: the pin overhangs its corner,
    // and taps only reach what's inside the box the card is given. The
    // margin itself lets taps through to whatever is below.
    const m = _pinMargin;
    final content = RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: m,
            top: m,
            width: box.width,
            height: box.height,
            child: Listener(onPointerDown: _trackCardTouch, child: gestures),
          ),
          if (item != null && !lifted)
            Positioned(
              top: m - 8,
              left: m - 8,
              child: _PinButton(pinned: item.pinned, onTap: () => store.togglePinned(item.id)),
            ),
        ],
      ),
    );
    // The same widgets whether lifted or not: swapping them out when the
    // hold kicks in would drop the gesture that's under way.
    return Positioned.fromRect(
      key: ValueKey(s.id),
      rect: box.inflate(m),
      child: ValueListenableBuilder(
        valueListenable: _moveDrag,
        builder: (context, offset, child) => Transform.translate(offset: lifted ? offset : Offset.zero, child: child),
        child: content,
      ),
    );
  }

  /// The canvas's margin, which cards are kept inside of.
  static const _inset = EdgeInsets.fromLTRB(16, 14, 16, 8);

  /// Room around a card for its pin's full tap area (see [TapArea]).
  static const _pinMargin = 18.0;
}

/// "Save outfit" — or, once what's on the canvas is saved, "Saved" with a
/// check, which opens that outfit. Worked out from the data, so it goes
/// back to "Save outfit" as soon as anything on the canvas changes (and
/// says "Saved" for an outfit put back on the canvas from the collection).
class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;
  const _SaveButton({required this.onSave});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final saved = store.savedCanvasOutfit;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: saved == null ? onSave : () => openOutfitDetail(context, saved),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: saved == null ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: saved == null ? AppColors.accent : AppColors.accentText, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saved != null) ...[
                Icon(Icons.check_rounded, size: 18, color: AppColors.accentText),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  saved == null ? l10n.saveOutfitButton : l10n.outfitSaved,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 13,
                    weight: FontWeight.w500,
                    color: saved == null ? Colors.white : AppColors.accentText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shuffle, as an icon in a round outlined button — the same height as the
/// pills next to it; the word is its tooltip and what VoiceOver reads.
class _ShuffleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ShuffleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder)),
            alignment: Alignment.center,
            child: CustomPaint(size: const Size.square(22), painter: _ShuffleGlyph(AppColors.label)),
          ),
        ),
      ),
    );
  }
}

/// Two arrows that swap sides in smooth curves, one passing over the other
/// (the material shuffle icon's are straight). Drawn in a 24 × 24 box.
class _ShuffleGlyph extends CustomPainter {
  final Color color;
  _ShuffleGlyph(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Bottom left → top right, then top left → bottom right over it.
    final under = Path()
      ..moveTo(3, 17)
      ..lineTo(6, 17)
      ..cubicTo(11, 17, 13, 7, 18, 7)
      ..lineTo(20.5, 7);
    final over = Path()
      ..moveTo(3, 7)
      ..lineTo(6, 7)
      ..cubicTo(11, 7, 13, 17, 18, 17)
      ..lineTo(20.5, 17);
    Path head(double y) => Path()
      ..moveTo(18, y - 2.6)
      ..lineTo(20.6, y)
      ..lineTo(18, y + 2.6);
    canvas.saveLayer(Offset.zero & const Size(24, 24), Paint());
    canvas.drawPath(under, stroke);
    canvas.drawPath(head(7), stroke);
    // A gap in the lower arrow where the other crosses it.
    canvas.drawPath(
      over,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..blendMode = BlendMode.clear,
    );
    canvas.drawPath(over, stroke);
    canvas.drawPath(head(17), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShuffleGlyph old) => old.color != color;
}

/// Small round toggle — filled pin in the accent color once pinned, a
/// muted outline otherwise — marking a garment as exempt from
/// [WardrobeStore.shuffle].
class _PinButton extends StatelessWidget {
  final bool pinned;
  final VoidCallback onTap;

  const _PinButton({required this.pinned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RoundIconButton(
      size: 26,
      background: AppColors.surface,
      borderColor: AppColors.removeButtonBorder,
      onTap: onTap,
      child: Icon(
        pinned ? Icons.push_pin : Icons.push_pin_outlined,
        size: 14,
        color: pinned ? AppColors.accentText : AppColors.muted,
      ),
    );
  }
}
