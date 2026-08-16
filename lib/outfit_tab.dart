import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Callbacks the tab needs from the surrounding [HomeScreen] to open bottom
/// sheets, since the sheet content depends on shared modal-presentation
/// state that lives above the tabs.
class OutfitTab extends StatelessWidget {
  final void Function(WardrobeZone zone) onPick;
  final VoidCallback onOpenLayers;
  final VoidCallback onOpenSave;

  const OutfitTab({
    super.key,
    required this.onPick,
    required this.onOpenLayers,
    required this.onOpenSave,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WardrobeStore>(
      builder: (context, store, _) {
        final top = store.at(store.topList, WardrobeZone.top);
        final bot = store.at(store.botList, WardrobeZone.bottom);
        final shoe = store.at(store.shoeList, WardrobeZone.shoes);
        final isDress = top != null && top.cat == 'saty';

        return Column(
          children: [
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final topCardWidth = isDress ? 208.0 : 176.0;
                    final hasRoomForTile =
                        store.layers.length < WardrobeStore.kMaxLayers;
                    final naturalLayersWidth = store.layers.isEmpty
                        ? 58.0
                        : store.layers.length * 120.0 +
                              (hasRoomForTile ? 10 + 58 : 0);
                    final maxAvailable =
                        (constraints.maxWidth - topCardWidth - 18).clamp(
                          58.0,
                          999.0,
                        );
                    final layersBoxWidth = naturalLayersWidth < maxAvailable
                        ? naturalLayersWidth
                        : maxAvailable;
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GarmentCard(
                                  width: topCardWidth,
                                  height: isDress ? 342 : 172,
                                  rotationDeg: -1.6,
                                  slotLabel: isDress
                                      ? 'šaty · celé tělo'
                                      : 'top',
                                  name: top == null ? 'Přidej top' : null,
                                  imagePath: top?.imagePath,
                                  onTap: () => onPick(WardrobeZone.top),
                                  onSwipe: (dir) =>
                                      store.step(WardrobeZone.top, dir),
                                  shadow: const [
                                    BoxShadow(
                                      color: Color(0x0D000000),
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: layersBoxWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 18),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (
                                            var k = 0;
                                            k < store.layers.length;
                                            k++
                                          )
                                            _LayerCard(
                                              itemId: store.layers[k],
                                              index: k,
                                              onOpenLayers: onOpenLayers,
                                            ),
                                          if (store.layers.isNotEmpty)
                                            const SizedBox(width: 10),
                                          if (store.layers.length <
                                              WardrobeStore.kMaxLayers)
                                            GestureDetector(
                                              onTap: onOpenLayers,
                                              child: Transform.rotate(
                                                angle:
                                                    -1.5 * 3.1415926535 / 180,
                                                child: Container(
                                                  width: 58,
                                                  height: 136,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors
                                                          .dashedBorder,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '+',
                                                    style: AppText.sans(
                                                      size: 22,
                                                      weight: FontWeight.w300,
                                                      color:
                                                          AppColors.mutedSoft,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isDress)
                            Transform.translate(
                              offset: const Offset(14, -12),
                              child: GarmentCard(
                                width: 190,
                                height: 208,
                                rotationDeg: 1.4,
                                slotLabel: bot != null && bot.cat == 'sukne'
                                    ? 'sukně'
                                    : 'spodek',
                                name: bot == null ? 'Přidej spodek' : null,
                                imagePath: bot?.imagePath,
                                onTap: () => onPick(WardrobeZone.bottom),
                                onSwipe: (dir) =>
                                    store.step(WardrobeZone.bottom, dir),
                                shadow: const [
                                  BoxShadow(
                                    color: Color(0x0D000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          Transform.translate(
                            offset: const Offset(-22, -10),
                            child: GarmentCard(
                              width: 158,
                              height: 110,
                              rotationDeg: -2.2,
                              slotLabel: 'boty',
                              name: shoe == null ? 'Přidej boty' : null,
                              imagePath: shoe?.imagePath,
                              onTap: () => onPick(WardrobeZone.shoes),
                              onSwipe: (dir) =>
                                  store.step(WardrobeZone.shoes, dir),
                              shadow: const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                      child: Text(
                        'Zamíchat',
                        style: AppText.sans(size: 12.5, color: AppColors.label),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: onOpenSave,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Uložit outfit',
                          style: AppText.sans(
                            size: 13,
                            weight: FontWeight.w500,
                            color: Colors.white,
                          ),
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

class _LayerCard extends StatelessWidget {
  final String itemId;
  final int index;
  final VoidCallback onOpenLayers;

  const _LayerCard({
    required this.itemId,
    required this.index,
    required this.onOpenLayers,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final it = store.itemById(itemId);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GarmentCard(
            width: 110,
            height: 136,
            rotationDeg: 2.4,
            imagePath: it?.imagePath,
            onTap: onOpenLayers,
          ),
          Positioned(
            top: -6,
            right: -6,
            child: RoundIconButton(
              size: 22,
              background: Colors.white,
              borderColor: AppColors.removeButtonBorder,
              onTap: () => store.removeLayer(index),
              child: const Text(
                '×',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
