import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'collections_tab.dart';
import 'diary_tab.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'outfit_tab.dart';
import 'settings_screen.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'wardrobe_tab.dart';
import 'widgets.dart';

/// One navigator per tab for everything above the bottom tab bar: the tab
/// itself plus type/collection screens pushed from it. They open *under* a
/// bar that stays put, and each tab keeps its own stack — leave a type for
/// another tab and coming back lands you in it again. Sheets
/// and dialogs go on the root navigator and cover the bar.
final Map<WardrobeTabKind, GlobalKey<NavigatorState>> _tabNavigatorKeys = {
  for (final kind in WardrobeTabKind.values) kind: GlobalKey<NavigatorState>(),
};

/// How many screens are open on top of each tab's root. Swiping between
/// tabs only works while the visible tab is at its root — inside a
/// type or collection a sideways swipe is iOS "back" instead — and not while a
/// finger is on an outfit card (swiping, moving or resizing it).
final Map<WardrobeTabKind, ValueNotifier<int>> _tabDepth = {
  for (final kind in WardrobeTabKind.values) kind: ValueNotifier(0),
};

final Map<WardrobeTabKind, NavigatorObserver> _tabObservers = {
  for (final kind in WardrobeTabKind.values) kind: _DepthObserver(_tabDepth[kind]!),
};

class _DepthObserver extends NavigatorObserver {
  final ValueNotifier<int> depth;
  _DepthObserver(this.depth);

  void _bump(int delta) {
    void apply() => depth.value = (depth.value + delta).clamp(0, 1 << 20);
    // Navigation can happen mid-build (e.g. a screen popping itself);
    // listeners rebuild widgets, so wait for the frame to finish then.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _bump(1); // not the tab's own root page
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump(-1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump(-1);
}

/// Closes any type/collection screen open in [kind]'s tab.
void _popTabToRoot(WardrobeTabKind kind) =>
    _tabNavigatorKeys[kind]!.currentState?.popUntil((route) => route.isFirst);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _wardrobeId;
  late int _page = context.read<WardrobeStore>().screen.index;
  late final PageController _pages = PageController(initialPage: _page);

  /// Set while a tab tap (or the store, e.g. "use in outfit") is driving
  /// the page — the pages it slides past mustn't become the current tab.
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    // Fresh navigators below start at their roots; a previous HomeScreen's
    // screens were torn down without "pop" notifications.
    for (final depth in _tabDepth.values) {
      depth.value = 0;
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _slideTo(int page) async {
    if (!_pages.hasClients) return;
    _animating = true;
    await _pages.animateToPage(page, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    _animating = false;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();

    // A type/collection kept open in another tab belongs to the wardrobe
    // it was opened in — drop them all when the wardrobe changes.
    if (_wardrobeId != null && _wardrobeId != store.activeWardrobeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final kind in WardrobeTabKind.values) {
          _popTabToRoot(kind);
        }
      });
    }
    _wardrobeId = store.activeWardrobeId;

    // The tab changed from outside the pager (bottom bar, store) — follow.
    if (store.screen.index != _page) {
      _page = store.screen.index;
      WidgetsBinding.instance.addPostFrameCallback((_) => _slideTo(_page));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([_tabDepth[store.screen]!, canvasTouches]),
                    builder: (context, _) => PageView(
                      controller: _pages,
                      physics: _tabDepth[store.screen]!.value == 0 && canvasTouches.value == 0
                          ? const PageScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) {
                        if (_animating) return;
                        _page = i;
                        FocusManager.instance.primaryFocus?.unfocus();
                        store.setScreen(WardrobeTabKind.values[i]);
                      },
                      children: [
                        for (final kind in WardrobeTabKind.values)
                          _TabNavigator(kind: kind, active: kind == store.screen),
                      ],
                    ),
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
                child: ContentWidth(
                  maxWidth: kMaxContentWidth - 40,
                  child: _Toast(message: store.toast),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tab's own navigator, one page of the tab pager — kept alive while
/// scrolled away so its stack (an open type…) survives. Only the current
/// tab handles the back button, runs animations and is read out by
/// screen readers.
class _TabNavigator extends StatefulWidget {
  final WardrobeTabKind kind;
  final bool active;

  const _TabNavigator({required this.kind, required this.active});

  @override
  State<_TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<_TabNavigator> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final key = _tabNavigatorKeys[widget.kind]!;
    return ExcludeSemantics(
      excluding: !widget.active,
      child: TickerMode(
        enabled: widget.active,
        // Routes Android's back button to this tab's navigator first,
        // so it closes an open type or collection instead of the app.
        child: NavigatorPopHandler<Object?>(
          enabled: widget.active,
          onPopWithResult: (_) => key.currentState?.maybePop(),
          // On an iPad the tab (and screens opened from it) sits in a
          // centered column; the page itself stays full width so swiping
          // between tabs works from the margins too.
          child: ContentWidth(
            child: Navigator(
              key: key,
              observers: [_tabObservers[widget.kind]!],
              onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _TabRoot(kind: widget.kind)),
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
                  onTap: () => openSettingsScreen(context),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.settings_outlined,
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
                onPick: (slotId) => openPickSheet(context, slotId),
                onOpenSave: () => openSaveOutfitSheet(context),
              ),
              WardrobeTabKind.wardrobe => WardrobeTab(
                onOpenItem: (item, browseIds) =>
                    openItemDetail(context, item, browseIds: browseIds),
              ),
              WardrobeTabKind.collections => const CollectionsTab(),
              WardrobeTabKind.diary => const DiaryTab(),
            },
          ),
        ],
      ),
    );
  }
}

/// The active wardrobe's name; with more than one wardrobe, a dropdown to
/// switch between them. Adding, renaming and deleting live in settings.
class _WardrobeSwitcher extends StatefulWidget {
  const _WardrobeSwitcher();

  @override
  State<_WardrobeSwitcher> createState() => _WardrobeSwitcherState();
}

class _WardrobeSwitcherState extends State<_WardrobeSwitcher> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final canSwitch = store.wardrobes.length > 1;

    return PopupMenuButton<String>(
      enabled: canSwitch,
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(-10, 8),
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 320),
      menuPadding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      color: AppColors.surface,
      elevation: 6,
      shadowColor: const Color(0x29000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.rowBorder),
      ),
      onOpened: () => setState(() => _open = true),
      onCanceled: () => setState(() => _open = false),
      onSelected: (id) {
        setState(() => _open = false);
        store.switchWardrobe(id);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.sectionWardrobes.toUpperCase(),
            style: AppText.mono(size: 9.5, letterSpacing: 1.3, color: AppColors.mutedSoft),
          ),
        ),
        for (final w in store.wardrobes) _item(store, w, l10n),
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
                style: AppText.sans(size: 14, weight: FontWeight.w500, color: AppColors.ink),
              ),
            ),
            if (canSwitch) ...[
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.mutedSoft),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(WardrobeStore store, Wardrobe w, AppLocalizations l10n) {
    final active = w.id == store.activeWardrobeId;
    return PopupMenuItem<String>(
      value: w.id,
      height: 48,
      padding: EdgeInsets.zero,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.cardFill : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                w.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  size: 14.5,
                  weight: active ? FontWeight.w500 : FontWeight.w400,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              l10n.itemCount(store.itemCountIn(w.id)),
              style: AppText.mono(size: 10, letterSpacing: 0.4, color: AppColors.mutedTag),
            ),
            SizedBox(
              width: 28,
              child: active
                  ? Align(alignment: Alignment.centerRight, child: Icon(Icons.check, size: 17, color: AppColors.accent))
                  : null,
            ),
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
      for (final kind in WardrobeTabKind.values)
        (
          kind,
          switch (kind) {
            WardrobeTabKind.outfit => l10n.tabOutfit,
            WardrobeTabKind.collections => l10n.tabCollections,
            WardrobeTabKind.diary => l10n.tabDiary,
            WardrobeTabKind.wardrobe => l10n.tabWardrobe,
          },
        ),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: ContentWidth(
        maxWidth: kMaxContentWidth - 40,
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
      ),
    );
  }
}
