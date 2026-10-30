import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// How many fingers are on the canvas right now. Swiping between tabs
/// pauses while two are (a pinch), so resizing a card never turns the page
/// instead. (Holding a card to move it can't turn it either: the hold wins
/// before the finger moves.)
final ValueNotifier<int> canvasTouches = ValueNotifier(0);

/// The outfit canvas: a card per [CanvasSlot], wherever the user put it.
/// Tap a card to pick what it shows, pin it to keep it through Shuffle. Drag a card (or hold it) to move it somewhere else (or onto
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

  /// How far a finger moves on a card before it's a drag of the card (the
  /// pan slop is twice this, 16 px): just under the 18 px it takes the
  /// pager to claim a swipe between tabs, and still past a shaky tap.
  static const _dragSlop = 8.0;

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

  /// A fresh key for each lift: the bin from the last one may still be
  /// fading out for a moment, and two can't share one key.
  GlobalKey _binKey = GlobalKey();

  /// Fingers on the canvas and where they are now (canvas coordinates).
  /// A pinch is read from these directly rather than through a gesture
  /// recognizer on the card: that one had to beat the short hold to win —
  /// both fingers on the card, spread far enough within 125 ms — and often
  /// didn't, so the card lifted to be moved instead.
  final Map<int, Offset> _fingers = {};

  /// A two-finger pinch is resizing (and moving) [_active].
  bool _pinching = false;
  bool _atScaleLimit = false;
  double _pinchStartDistance = 1;
  Offset _pinchStartFocal = Offset.zero;
  Offset _pinchStartDrag = Offset.zero;

  /// Set by a pinch until the next touch: the finger lifted last mustn't
  /// then count as a tap (opening the picker) or a hold.
  bool _afterPinch = false;
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
    _startScale = _liveScale = s.scale;
  }

  /// The topmost card at [p] (canvas coordinates), if any.
  CanvasSlot? _cardAt(Offset p, WardrobeStore store) {
    final slots = store.visibleSlots;
    final ordered = [...slots.where((s) => s.id != _active), ...slots.where((s) => s.id == _active)];
    for (final s in ordered.reversed) {
      if (_boxFor(s).shift(Offset(_inset.left, _inset.top)).inflate(8).contains(p)) return s;
    }
    return null;
  }

  /// A finger landing on the canvas, followed until it lifts through the
  /// pointer router rather than the canvas's own [Listener] — the canvas
  /// may be gone by then (its last card dropped on the bin).
  void _onFingerDown(PointerDownEvent down) {
    if (_fingers.isEmpty) _afterPinch = false;
    canvasTouches.value++;
    _fingers[down.pointer] = down.localPosition;
    final toLocal = down.localPosition - down.position;
    void route(PointerEvent e) {
      if (e is PointerMoveEvent) {
        _onFingerMove(e.pointer, e.position + toLocal);
      } else if (e is PointerUpEvent || e is PointerCancelEvent) {
        GestureBinding.instance.pointerRouter.removeRoute(e.pointer, route);
        _onFingerUp(e.pointer);
      }
    }

    GestureBinding.instance.pointerRouter.addRoute(down.pointer, route);
    if (_fingers.length == 2 && !_pinching) _startPinch();
  }

  void _onFingerMove(int pointer, Offset at) {
    if (!_fingers.containsKey(pointer)) return;
    _fingers[pointer] = at;
    if (_pinching && mounted) _updatePinch();
  }

  void _onFingerUp(int pointer) {
    if (_fingers.remove(pointer) == null) return;
    canvasTouches.value = math.max(0, canvasTouches.value - 1);
    if (_pinching && _fingers.length < 2) {
      _pinching = false;
      if (mounted) _endPinch();
    }
  }

  /// A second finger is down: pinch the card being held, or else the one
  /// under the first finger (or the second, or between them).
  void _startPinch() {
    final store = context.read<WardrobeStore>();
    final [a, b, ...] = _fingers.values.toList();
    final focal = (a + b) / 2;
    final CanvasSlot? s;
    if (_active != null) {
      s = store.slotById(_active!);
      if (s == null) return;
      // Lifted and being moved (already picked up): from here the two
      // fingers move it.
      if (_moving) {
        _drag = _moveDrag.value;
        _moveDrag.value = Offset.zero;
        _moving = false;
        _overBin = false;
      }
    } else {
      s = _cardAt(a, store) ?? _cardAt(b, store) ?? _cardAt(focal, store);
      if (s == null) return;
      _begin(s);
      Haptics.pickUp();
    }
    _pinching = true;
    _afterPinch = true;
    _atScaleLimit = false;
    _pinchStartDistance = math.max((a - b).distance, 1);
    _pinchStartFocal = focal;
    _pinchStartDrag = _drag;
    _startScale = _liveScale;
    setState(() {});
  }

  void _updatePinch() {
    final [a, b, ...] = _fingers.values.toList();
    final wanted = _startScale * (a - b).distance / _pinchStartDistance;
    final scale = wanted.clamp(CanvasSlot.minScale, CanvasSlot.maxScale);
    // A tick on reaching the smallest or biggest size.
    final atLimit = scale != wanted;
    if (atLimit && !_atScaleLimit) Haptics.tick();
    _atScaleLimit = atLimit;
    setState(() {
      _liveScale = scale;
      _drag = _pinchStartDrag + ((a + b) / 2 - _pinchStartFocal);
    });
  }

  void _endPinch() {
    final store = context.read<WardrobeStore>();
    final s = _active == null ? null : store.slotById(_active!);
    if (s == null) {
      setState(() => _active = null);
    } else {
      _commit(store, s);
    }
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

  /// Picks [s] up to be moved — by a hold, or by dragging it straight away.
  void _lift(CanvasSlot s) {
    // Another card is already being moved or resized, or this is (the
    // start of) a pinch rather than a move.
    if (_active != null || _afterPinch || _fingers.length > 1) return;
    Haptics.pickUp();
    setState(() {
      _begin(s);
      _moving = true;
      _overBin = false;
      _binKey = GlobalKey();
    });
  }

  void _dragTo(CanvasSlot s, Offset offset, Offset global) {
    if (!_moving || _active != s.id) return;
    _moveDrag.value = offset;
    final over = _isOverBin(global);
    if (over == _overBin) return;
    if (over) Haptics.tick();
    setState(() => _overBin = over);
  }

  /// Lets go of [s]. If the gesture was [interrupted] (a system gesture, a
  /// call), it stays where it was taken to — never deleted, even if that's
  /// over the bin.
  void _drop(WardrobeStore store, CanvasSlot s, {bool interrupted = false}) {
    if (!_moving || _active != s.id) return;
    if (interrupted) _overBin = false;
    _endMove(store, s);
  }

  void _endMove(WardrobeStore store, CanvasSlot s) {
    if (_overBin) {
      Haptics.remove();
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
              _ShuffleButton(
                label: l10n.shuffleButton,
                onTap: () {
                  Haptics.tick();
                  store.shuffle();
                },
              ),
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
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onFingerDown,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final s in ordered) _card(store, s, _boxFor(s).shift(Offset(_inset.left, _inset.top))),
            ],
          ),
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

    final gestures = RawGestureDetector(
      gestures: {
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          TapGestureRecognizer.new,
          (r) => r.onTap = () {
            if (!_afterPinch) widget.onPick(s.id);
          },
        ),
        // A short hold, then drag: move the card (or drop it on the bin).
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: _holdToMove),
          (r) => r
            ..onLongPressStart = (_) {
              _lift(s);
            }
            ..onLongPressMoveUpdate = (d) {
              _dragTo(s, d.offsetFromOrigin, d.globalPosition);
            }
            ..onLongPressEnd = (_) {
              _drop(store, s);
            }
            ..onLongPressCancel = () {
              _drop(store, s, interrupted: true);
            },
        ),
        // Or just drag it, without holding first: the card claims the drag
        // after a short way — sooner than swiping between tabs would — so
        // moving a card sideways never turns the page instead.
        PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          PanGestureRecognizer.new,
          (r) => r
            ..gestureSettings = const DeviceGestureSettings(touchSlop: _dragSlop)
            ..onStart = (_) {
              _lift(s);
            }
            ..onUpdate = (d) {
              _dragTo(s, _moveDrag.value + d.delta, d.globalPosition);
            }
            ..onEnd = (_) {
              _drop(store, s);
            }
            ..onCancel = () {
              _drop(store, s, interrupted: true);
            },
        ),
        // Two fingers resizing it are read off the whole canvas (see
        // [_fingers]).
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
            child: gestures,
          ),
          // Stays on the card while it's moved, rather than blinking out.
          if (item != null)
            Positioned(
              top: m - 8,
              left: m - 8,
              child: _PinButton(
                pinned: item.pinned,
                onTap: () {
                  Haptics.tick();
                  store.togglePinned(item.id);
                },
              ),
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
