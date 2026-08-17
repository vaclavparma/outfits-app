import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'about_sheet.dart';
import 'collections_tab.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'outfit_tab.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'wardrobe_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => openSettingsSheet(context),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: AppColors.mutedSoft,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => openAboutSheet(context),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.info_outline, size: 20, color: AppColors.mutedSoft),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(store.screen),
                      child: switch (store.screen) {
                        WardrobeTabKind.outfit => OutfitTab(
                          onPick: (zone) => openPickSheet(context, zone),
                          onOpenLayers: ({replaceIndex}) =>
                              openLayerSheet(context, replaceIndex: replaceIndex),
                          onOpenSave: () => openSaveOutfitSheet(context),
                        ),
                        WardrobeTabKind.wardrobe => WardrobeTab(onOpenItem: (item) => openItemSheet(context, item)),
                        WardrobeTabKind.collections => const CollectionsTab(),
                      },
                    ),
                  ),
                ),
                _BottomTabs(current: store.screen, onSelect: store.setScreen),
              ],
            ),
            if (store.toast.isNotEmpty) Positioned(left: 20, right: 20, top: 2, child: _Toast(message: store.toast)),
          ],
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  final String message;
  const _Toast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.rowBorder),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          ),
          Flexible(
            child: Text(message, style: AppText.sans(size: 11.5, height: 1.35, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  final WardrobeTabKind current;
  final void Function(WardrobeTabKind) onSelect;

  const _BottomTabs({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (WardrobeTabKind.outfit, l10n.tabOutfit),
      (WardrobeTabKind.wardrobe, l10n.tabWardrobe),
      (WardrobeTabKind.collections, l10n.tabCollections),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          for (final (kind, label) in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(kind),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: AppText.mono(
                          size: 10.5,
                          letterSpacing: 1.3,
                          color: current == kind ? AppColors.ink : AppColors.mutedSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: current == kind ? AppColors.accent : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
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
