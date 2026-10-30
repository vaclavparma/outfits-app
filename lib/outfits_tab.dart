import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

enum _Filter { all, favorites, oftenWorn, longUnworn }

/// Every saved outfit, newest first: search them by what's in them, filter
/// them (favorites, worn often, not worn lately), heart them. Tap one for
/// its detail.
class OutfitsTab extends StatefulWidget {
  const OutfitsTab({super.key});

  @override
  State<OutfitsTab> createState() => _OutfitsTabState();
}

class _OutfitsTabState extends State<OutfitsTab> {
  /// Worn at least this many times counts as "worn often".
  static const _oftenWorn = 2;

  /// Not worn for at least this many days (or never) is "not worn lately".
  static const _unwornDays = 30;

  String _query = '';
  _Filter _filter = _Filter.all;

  /// Everything an outfit can be found by: everything each of its pieces
  /// can (see [WardrobeStore.searchTexts]).
  List<String?> _searchTexts(WardrobeStore store, SavedOutfit o) => [
    for (final id in o.itemIds)
      if (store.itemById(id) case final it?) ...store.searchTexts(it),
  ];


  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final today = DateUtils.dateOnly(DateTime.now());
    final wears = store.outfitWearStats;
    final all = store.outfits.reversed.toList();
    // The search field goes away with the last outfit (or in an empty
    // wardrobe), and comes back empty — so does the search.
    if (all.isEmpty) _query = '';
    var shown = all
        .where((o) => textsMatchSearch(_searchTexts(store, o), _query))
        .toList();
    switch (_filter) {
      case _Filter.all:
        break;
      case _Filter.favorites:
        shown = shown.where((o) => o.favorite).toList();
      case _Filter.oftenWorn:
        shown = shown.where((o) => (wears[o.id]?.count ?? 0) >= _oftenWorn).toList()
          ..sort((a, b) => wears[b.id]!.count.compareTo(wears[a.id]!.count));
      case _Filter.longUnworn:
        final cutoff = addDays(today, -_unwornDays);
        shown = shown.where((o) => !(wears[o.id]?.last.isAfter(cutoff) ?? false)).toList()
          // Never worn first, then the longest ago.
          ..sort((a, b) {
            final la = wears[a.id]?.last, lb = wears[b.id]?.last;
            if (la == null || lb == null) return la == null ? (lb == null ? 0 : -1) : 1;
            return la.compareTo(lb);
          });
    }

    // Only the whole collection, unfiltered, can be put in order.
    final canReorder = _query.trim().isEmpty && _filter == _Filter.all;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          sliver: SliverList.list(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      l10n.tabOutfits,
                      style: AppText.sans(size: 26, weight: FontWeight.w300, color: AppColors.ink, letterSpacing: -0.4),
                    ),
                  ),
                  if (all.isNotEmpty)
                    Text(l10n.outfitCount(all.length), style: AppText.mono(size: 9.5, letterSpacing: 0.6, color: AppColors.mutedSoft)),
                ],
              ),
              const SizedBox(height: 14),
              if (all.isNotEmpty) ...[
                SearchField(hint: l10n.searchOutfitsHint, onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (all.isNotEmpty)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final (f, label) in [
                    (_Filter.all, l10n.all),
                    (_Filter.favorites, l10n.filterFavorites),
                    (_Filter.oftenWorn, l10n.filterOftenWorn),
                    (_Filter.longUnworn, l10n.statsNotWorn),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: SelectChip(
                        label: label,
                        active: _filter == f,
                        mono: false,
                        height: 34,
                        onTap: () => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (all.isEmpty || shown.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 60, 40, 0),
              child: Column(
                children: [
                  if (all.isEmpty) ...[
                    Icon(Icons.checkroom_outlined, size: 32, color: AppColors.mutedSoft),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    all.isEmpty ? l10n.outfitsEmpty : l10n.nothingFound,
                    textAlign: TextAlign.center,
                    style: AppText.sans(size: 13, color: AppColors.mutedTag, height: 1.45),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            // Hold an outfit and drag it to put them in another order — in
            // "All" only: the other filters sort by wear or show some, as
            // does a search.
            sliver: SliverReorderableGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns(context, 2),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: shown.length,
              proxyDecorator: liftedTile(18),
              onReorderStart: (_) => Haptics.pickUp(),
              onReorder: store.reorderOutfits,
              itemBuilder: (context, i) => GridDragStart(
                key: ValueKey(shown[i].id),
                index: i,
                enabled: canReorder,
                child: _OutfitCard(outfit: shown[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final SavedOutfit outfit;
  const _OutfitCard({required this.outfit});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final colors = store.topColors([outfit.slots]);
    return GestureDetector(
      onTap: () => openOutfitDetail(context, outfit),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.rowBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: OutfitPreview(slots: outfit.slots, itemById: store.itemById, nameOf: store.displayName),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 14,
              child: Row(
                children: [
                  for (final c in colors)
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: c.swatch,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.mutedSoft.withValues(alpha: 0.6), width: 0.8),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Semantics(
                button: true,
                toggled: outfit.favorite,
                label: l10n.favorite,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Haptics.tick();
                    store.toggleFavorite(outfit.id);
                  },
                  child: SizedBox(
                    width: 44,
                    height: 40,
                    child: Icon(
                      outfit.favorite ? Icons.favorite : Icons.favorite_border,
                      size: 21,
                      color: outfit.favorite ? AppColors.accentText : AppColors.mutedSoft,
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
