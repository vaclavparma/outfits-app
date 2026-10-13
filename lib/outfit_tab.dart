import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
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
  static const _holdToMove = Duration(milliseconds: 250);

  /// The card being moved or resized, and where it is so far — committed to
  /// the store when the gesture ends, not on every frame.
  String? _active;
  Offset _drag = Offset.zero;
  double _startScale = 1;
  double _liveScale = 1;

  /// Held and being dragged (as opposed to pinched).
  bool _moving = false;
  bool _overBin = false;

  /// The most fingers seen in the current gesture on [_active] — only two
  /// (a pinch) move and resize the card.
  int _maxPointers = 0;

  final _binKey = GlobalKey();
  Size _size = Size.zero;
  double _unit = 1;

  /// Where [s]'s card sits. Kept inside the canvas — except while it's
  /// being dragged, so it can follow the finger down to the bin.
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
      free: active && _moving,
    );
    return Rect.fromLTWH(r.left, r.top, r.width, r.height);
  }

  bool _isOverBin(Offset global) {
    final box = _binKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return (box.localToGlobal(Offset.zero) & box.size).inflate(12).contains(global);
  }

  void _begin(CanvasSlot s) {
    _active = s.id;
    _drag = Offset.zero;
    _maxPointers = 0;
    _startScale = _liveScale = s.scale;
  }

  /// Saves where the active card ended up (kept inside the canvas).
  void _commit(WardrobeStore store, CanvasSlot s) {
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: _canvas(context, store, l10n),
          ),
        ),
        SizedBox(
          height: 52,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _moving ? _bin(l10n) : _addChips(store),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            children: [
              _PillButton(label: l10n.shuffleButton, onTap: store.shuffle),
              const SizedBox(width: 10),
              Expanded(child: _PillButton(label: l10n.saveOutfitButton, filled: true, onTap: widget.onOpenSave)),
            ],
          ),
        ),
      ],
    );
  }

  /// A chip per kind, to add a card of it.
  Widget _addChips(WardrobeStore store) {
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
        scale: _overBin ? 1.04 : 1,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        _unit = CanvasGeometry.unitFor(_size.width, _size.height);
        return Stack(
          clipBehavior: Clip.none,
          children: [for (final s in ordered) _card(store, s, _boxFor(s))],
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

    void onScaleUpdate(ScaleUpdateDetails d) => setState(() {
      _maxPointers = math.max(_maxPointers, d.pointerCount);
      if (_maxPointers > 1) {
        _drag += d.focalPointDelta;
        if (d.pointerCount > 1) {
          _liveScale = (_startScale * d.scale).clamp(CanvasSlot.minScale, CanvasSlot.maxScale);
        }
      }
    });

    void onScaleEnd(ScaleEndDetails d) {
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
              HapticFeedback.mediumImpact();
              setState(() {
                _begin(s);
                _moving = true;
                _overBin = false;
              });
            }
            ..onLongPressMoveUpdate = (d) {
              setState(() {
                _drag = d.offsetFromOrigin;
                final over = _isOverBin(d.globalPosition);
                if (over && !_overBin) HapticFeedback.selectionClick();
                _overBin = over;
              });
            }
            ..onLongPressEnd = (_) {
              _endMove(store, s);
            }
            ..onLongPressCancel = () {
              if (_moving && _active == s.id) _endMove(store, s);
            },
        ),
        // Two fingers resize (and move) the card.
        ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
          ScaleGestureRecognizer.new,
          (r) => r
            ..onStart = (_) {
              setState(() => _begin(s));
            }
            ..onUpdate = onScaleUpdate
            ..onEnd = onScaleEnd,
        ),
      },
      child: card,
    );

    return Positioned.fromRect(
      key: ValueKey(s.id),
      rect: box,
      child: Listener(
        onPointerDown: _trackCardTouch,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            gestures,
            if (item != null && !lifted)
              Positioned(
                top: -8,
                left: -8,
                child: _PinButton(pinned: item.pinned, onTap: () => store.togglePinned(item.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _PillButton({required this.label, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : null,
            borderRadius: BorderRadius.circular(22),
            border: filled ? null : Border.all(color: AppColors.cardBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: filled
                ? AppText.sans(size: 13, weight: FontWeight.w500, color: Colors.white)
                : AppText.sans(size: 12.5, color: AppColors.label),
          ),
        ),
      ),
    );
  }
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
        color: pinned ? AppColors.accent : AppColors.muted,
      ),
    );
  }
}
