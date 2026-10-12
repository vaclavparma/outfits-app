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

/// One navigator per tab for everything above the bottom tab bar: the tab
/// itself plus folder/collection screens pushed from it. They open *under*
/// a bar that stays put, and each tab keeps its own stack — leave a folder
/// for another tab and coming back lands you in that folder again. Sheets
/// and dialogs go on the root navigator and cover the bar.
final Map<WardrobeTabKind, GlobalKey<NavigatorState>> _tabNavigatorKeys = {
  for (final kind in WardrobeTabKind.values) kind: GlobalKey<NavigatorState>(),
};

/// Closes any folder/collection screen open in [kind]'s tab.
void _popTabToRoot(WardrobeTabKind kind) =>
    _tabNavigatorKeys[kind]!.currentState?.popUntil((route) => route.isFirst);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _wardrobeId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();

    // A folder/collection kept open in another tab belongs to the wardrobe
    // it was opened in — drop them all when the wardrobe changes.
    if (_wardrobeId != null && _wardrobeId != store.activeWardrobeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final kind in WardrobeTabKind.values) {
          _popTabToRoot(kind);
        }
      });
    }
    _wardrobeId = store.activeWardrobeId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      for (final kind in WardrobeTabKind.values)
                        _TabNavigator(kind: kind, active: kind == store.screen),
                    ],
                  ),
                ),
                _BottomTabs(
                  current: store.screen,
                  onSelect: (kind) {
                    // Tapping the tab you're on goes back to its start
                    // (iOS convention); another tab resumes where it was.
                    if (kind == store.screen) _popTabToRoot(kind);
                    FocusManager.instance.primaryFocus?.unfocus();
                    store.setScreen(kind);
                  },
                ),
              ],
            ),
            if (store.toast.isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                top: 2,
                child: _Toast(message: store.toast),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tab's own navigator, kept alive (and fading in/out) while another tab
/// is showing so its stack survives the switch. Inactive tabs don't take
/// taps, back gestures, animations or accessibility focus.
class _TabNavigator extends StatelessWidget {
  final WardrobeTabKind kind;
  final bool active;

  const _TabNavigator({required this.kind, required this.active});

  @override
  Widget build(BuildContext context) {
    final key = _tabNavigatorKeys[kind]!;
    return ExcludeSemantics(
      excluding: !active,
      child: IgnorePointer(
        ignoring: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: active ? Curves.easeOut : Curves.easeIn,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.02),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: TickerMode(
              enabled: active,
              // Routes Android's back button to this tab's navigator first,
              // so it closes an open folder instead of the app.
              child: NavigatorPopHandler<Object?>(
                enabled: active,
                onPopWithResult: (_) => key.currentState?.maybePop(),
                child: Navigator(
                  key: key,
                  onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _TabRoot(kind: kind)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header (wardrobe switcher, settings, about) and one tab's content —
/// the root page of that tab's navigator.
class _TabRoot extends StatelessWidget {
  final WardrobeTabKind kind;
  const _TabRoot({required this.kind});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _WardrobeSwitcher(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => openSettingsSheet(context),
                  child: Padding(
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
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.mutedSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (kind) {
              WardrobeTabKind.outfit => OutfitTab(
                onPick: (zone) => openPickSheet(context, zone),
                onOpenLayers: ({replaceIndex}) =>
                    openLayerSheet(context, replaceIndex: replaceIndex),
                onOpenSave: () => openSaveOutfitSheet(context),
              ),
              WardrobeTabKind.wardrobe => WardrobeTab(
                onOpenItem: (item) => openItemSheet(context, item),
              ),
              WardrobeTabKind.collections => const CollectionsTab(),
            },
          ),
        ],
      ),
    );
  }
}

enum _WardrobeMenuAction { edit }

/// The active wardrobe's name with a dropdown for switching between
/// wardrobes; adding/renaming/deleting lives in the "edit" sheet it links to.
class _WardrobeSwitcher extends StatelessWidget {
  const _WardrobeSwitcher();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<Object>(
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      elevation: 3,
      shadowColor: const Color(0x1F000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.rowBorder),
      ),
      onSelected: (value) => _onSelected(context, store, value),
      itemBuilder: (context) => [
        for (final w in store.wardrobes)
          PopupMenuItem<Object>(
            value: w.id,
            height: 44,
            child: Row(
              children: [
                Icon(
                  w.id == store.activeWardrobeId ? Icons.check : null,
                  size: 17,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    w.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13.5, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          value: _WardrobeMenuAction.edit,
          height: 44,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 17,
                color: AppColors.mutedSoft,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.editWardrobes,
                style: AppText.sans(size: 13.5, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                store.activeWardrobe.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  size: 14,
                  weight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.mutedSoft,
            ),
          ],
        ),
      ),
    );
  }

  void _onSelected(BuildContext context, WardrobeStore store, Object value) {
    switch (value) {
      case String id:
        store.switchWardrobe(id);
      case _WardrobeMenuAction.edit:
        openManageWardrobesSheet(context);
    }
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.rowBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          Flexible(
            child: Text(
              message,
              style: AppText.sans(
                size: 11.5,
                height: 1.35,
                color: AppColors.ink,
              ),
            ),
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
      decoration: BoxDecoration(
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
                          color: current == kind
                              ? AppColors.ink
                              : AppColors.mutedSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: current == kind
                              ? AppColors.accent
                              : Colors.transparent,
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
