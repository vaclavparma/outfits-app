import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

class WardrobeTab extends StatelessWidget {
  final void Function(ClothingItem item) onOpenItem;

  const WardrobeTab({super.key, required this.onOpenItem});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();

    final allTags = distinctTags(store.items);

    bool visible(ClothingItem it) =>
        store.tagFilter == null || it.tags.contains(store.tagFilter);

    // Every category is always shown (even empty ones) so there's always a
    // + tile to add the first item of that kind — no separate empty state
    // or floating add button needed.
    final sections = kCategories
        .map((c) => (c, store.byCat(c.key).where(visible).toList()))
        .toList();

    // A single CustomScrollView with one SliverGrid per category, rather than
    // a ListView of shrinkWrap-ped GridViews: shrinkWrap forces every grid to
    // lay out (and build) all of its children up front regardless of scroll
    // position, which stops paying off once the wardrobe has many items.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          sliver: SliverMainAxisGroup(
            slivers: [
              if (allTags.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              for (final t in allTags)
                                SelectChip(
                                  label: t,
                                  active: store.tagFilter == t,
                                  onTap: () => store.toggleTagFilter(t),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => openManageTagsSheet(context),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.mutedSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              for (final (cat, its) in sections) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: cat.label,
                    trailing: '${its.length} kusů',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 22),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          childAspectRatio: 100 / 124,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i == its.length) {
                          return AddTile(
                            onTap: () => openAddItemSheet(
                              context,
                              presetCategory: cat.key,
                            ),
                          );
                        }
                        final it = its[i];
                        return GarmentCard(
                          width: double.infinity,
                          height: double.infinity,
                          slotLabel: shortCategoryLabel(it.cat).toLowerCase(),
                          tags: it.tagsLabel,
                          imagePath: it.imagePath,
                          onTap: () => onOpenItem(it),
                        );
                      },
                      childCount: its.length + 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
