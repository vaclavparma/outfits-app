import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Callbacks the tab needs from the surrounding [HomeScreen] to open bottom
/// sheets, since the sheet content depends on shared modal-presentation
/// state that lives above the tabs.
class OutfitTab extends StatelessWidget {
  final void Function(WardrobeZone zone) onPick;
  final void Function({int? replaceIndex}) onOpenLayers;
  final VoidCallback onOpenSave;

  const OutfitTab({super.key, required this.onPick, required this.onOpenLayers, required this.onOpenSave});

  @override
  Widget build(BuildContext context) {
    return Consumer<WardrobeStore>(
      builder: (context, store, _) {
        final l10n = AppLocalizations.of(context)!;
        final top = store.at(store.topList, WardrobeZone.top);
        final bot = store.at(store.botList, WardrobeZone.bottom);
        final shoe = store.at(store.shoeList, WardrobeZone.shoes);
        final isDress = top != null && top.cat == 'saty';
        // With one or more layers next to it, the top card gives up a bit of
        // its own size so the layer cards beside it have room to breathe.
        final topScale = store.layers.isEmpty ? 1.0 : 0.74;
        final topCardWidth = (isDress ? 190.0 : 176.0) * topScale;
        final topCardHeight = (isDress ? 310.0 : 172.0) * topScale;
        final topCard = _withPinToggle(
          top,
          store,
          GarmentCard(
            width: topCardWidth,
            height: topCardHeight,
            rotationDeg: -1.6,
            name: top == null ? l10n.addTopPlaceholder : null,
            imagePath: top?.imagePath,
            onTap: () => onPick(WardrobeZone.top),
            onSwipe: (dir) => store.step(WardrobeZone.top, dir),
            shadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
          ),
        );
        // No layers yet: the "+" tile is just an affordance, not a real
        // garment, so it tucks in behind the top card instead of taking a
        // full lane beside it. Once there's a real layer, it pulls onto the
        // top card instead so it reads as worn over it.
        final topWithLayers = store.layers.isEmpty
            ? _PeekingStack(
                frontWidth: topCardWidth,
                frontHeight: topCardHeight,
                front: topCard,
                backWidth: 74,
                backHeight: 136,
                back: _AddLayerTile(onTap: () => onOpenLayers()),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  topCard,
                  const SizedBox(width: 6),
                  Transform.translate(
                    offset: const Offset(-22, 0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: _LayersCluster(layers: store.layers, onOpenLayers: onOpenLayers),
                    ),
                  ),
                ],
              );

        return Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(padding: const EdgeInsets.only(right: 8), child: topWithLayers),
                      if (!isDress)
                        Transform.translate(
                          offset: const Offset(14, -12),
                          child: _withPinToggle(
                            bot,
                            store,
                            GarmentCard(
                              width: store.layers.isEmpty ? 190 : 158,
                              height: store.layers.isEmpty ? 208 : 174,
                              rotationDeg: 1.4,
                              name: bot == null ? l10n.addBottomPlaceholder : null,
                              imagePath: bot?.imagePath,
                              onTap: () => onPick(WardrobeZone.bottom),
                              onSwipe: (dir) => store.step(WardrobeZone.bottom, dir),
                              shadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
                            ),
                          ),
                        ),
                      Transform.translate(
                        offset: const Offset(-22, -10),
                        child: _withPinToggle(
                          shoe,
                          store,
                          GarmentCard(
                            width: 158,
                            height: 110,
                            rotationDeg: -2.2,
                            name: shoe == null ? l10n.addShoesPlaceholder : null,
                            imagePath: shoe?.imagePath,
                            onTap: () => onPick(WardrobeZone.shoes),
                            onSwipe: (dir) => store.step(WardrobeZone.shoes, dir),
                            shadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: store.shuffle,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(l10n.shuffleButton, style: AppText.sans(size: 12.5, color: AppColors.label)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: onOpenSave,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(22)),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.saveOutfitButton,
                          style: AppText.sans(size: 13, weight: FontWeight.w500, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Extra layers next to the top card. Kept as a fixed-size, non-scrolling
/// cluster: with 2 layers (the max) they're shown fanned/overlapping rather
/// than side by side, so the row never has 3 full-size cards crammed next
/// to each other, and each card's remove button stays clear of its neighbor.
class _LayersCluster extends StatelessWidget {
  final List<String> layers;
  final void Function({int? replaceIndex}) onOpenLayers;

  const _LayersCluster({required this.layers, required this.onOpenLayers});

  @override
  Widget build(BuildContext context) {
    if (layers.isEmpty) {
      return _AddLayerTile(onTap: () => onOpenLayers());
    }
    if (layers.length == 1) {
      // The "+" for a possible 2nd layer is, again, just an affordance —
      // tuck it in behind the real layer card instead of giving it its own
      // full-width slot next to it.
      return _PeekingStack(
        frontWidth: 110,
        frontHeight: 136,
        // Same rotation as the "front" slot in the 2-layer fan below, so
        // this card doesn't visibly shift when a second layer is added.
        front: _LayerCard(itemId: layers[0], index: 0, onOpenLayers: onOpenLayers, rotationDeg: 1.5),
        backWidth: 74,
        backHeight: 136,
        back: _AddLayerTile(onTap: () => onOpenLayers()),
      );
    }
    // Two layers: fan them so both cards — and both remove buttons — stay
    // fully visible and tappable without any horizontal scrolling. The
    // first-added layer always stays in the same slot/rotation it had when
    // it was the only one — otherwise adding a second layer makes it look
    // like the two swapped places. But the second (most recently added)
    // layer renders on top, like an outer garment worn over the first — kept
    // to a modest overlap so the first layer stays clearly visible too.
    return SizedBox(
      width: 196,
      height: 154,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _LayerCard(itemId: layers[0], index: 0, onOpenLayers: onOpenLayers, rotationDeg: 1.5),
          ),
          Positioned(
            left: 86,
            top: -12,
            child: _LayerCard(itemId: layers[1], index: 1, onOpenLayers: onOpenLayers, rotationDeg: 5),
          ),
        ],
      ),
    );
  }
}

class _AddLayerTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddLayerTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: 5 * 3.1415926535 / 180,
        child: Container(
          width: 74,
          height: 136,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dashedBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            '+',
            style: AppText.sans(size: 22, weight: FontWeight.w300, color: AppColors.mutedSoft),
          ),
        ),
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  final String itemId;
  final int index;
  final void Function({int? replaceIndex}) onOpenLayers;
  final double rotationDeg;

  const _LayerCard({required this.itemId, required this.index, required this.onOpenLayers, this.rotationDeg = 2.4});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final it = store.itemById(itemId);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GarmentCard(
          width: 110,
          height: 136,
          rotationDeg: rotationDeg,
          imagePath: it?.imagePath,
          onTap: () => onOpenLayers(replaceIndex: index),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: RoundIconButton(
            size: 26,
            background: Colors.white,
            borderColor: AppColors.removeButtonBorder,
            onTap: () => store.removeLayer(index),
            child: const Text('×', style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1)),
          ),
        ),
        if (it != null)
          Positioned(
            top: -8,
            left: -8,
            child: _PinButton(pinned: it.pinned, onTap: () => store.togglePinned(it.id)),
          ),
      ],
    );
  }
}

/// Wraps [card] with a top-left pin toggle when [item] isn't null — an
/// empty "add" slot has nothing to pin. Positioned relative to [card]'s own
/// (unrotated) layout box, so it stays put regardless of the card's own
/// [GarmentCard.rotationDeg].
Widget _withPinToggle(ClothingItem? item, WardrobeStore store, Widget card) {
  if (item == null) return card;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      card,
      Positioned(
        top: -8,
        left: -8,
        child: _PinButton(pinned: item.pinned, onTap: () => store.togglePinned(item.id)),
      ),
    ],
  );
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
      background: Colors.white,
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

/// Lays [back] out so it peeks from behind [front]'s bottom-right corner,
/// instead of sitting fully beside it — [front] paints last (on top),
/// hiding most of [back] except a sliver on the right and a strip below.
/// Used for the "+" add-layer affordance, so an empty slot reads as
/// waiting behind whatever's currently on top rather than claiming a full
/// lane of its own.
class _PeekingStack extends StatelessWidget {
  // How far `back`'s left edge tucks under `front`'s right edge, and how
  // far `back` pokes out below `front`'s bottom edge.
  static const _overlapX = 24.0;
  static const _peekY = 20.0;

  final double frontWidth;
  final double frontHeight;
  final Widget front;
  final double backWidth;
  final double backHeight;
  final Widget back;

  const _PeekingStack({
    required this.frontWidth,
    required this.frontHeight,
    required this.front,
    required this.backWidth,
    required this.backHeight,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    final left = frontWidth - _overlapX;
    final top = frontHeight - backHeight + _peekY;
    return SizedBox(
      width: math.max(frontWidth, left + backWidth),
      height: math.max(frontHeight, top + backHeight),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: left, top: top, child: back),
          Positioned(left: 0, top: 0, child: front),
        ],
      ),
    );
  }
}
