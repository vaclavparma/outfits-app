import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'collection_detail_screen.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Overview of all collections. Tap a card to see its outfits (and
/// rename/delete it) on [CollectionDetailScreen]; the trailing tile creates
/// a new one.
class CollectionsTab extends StatelessWidget {
  const CollectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;

    return ReorderableGridView.count(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
      dragStartDelay: gridDragStartDelay,
      onDragStart: onGridDragStart,
      dragWidgetBuilderV2: roundedDragFeedback(16),
      onReorder: store.reorderCollections,
      footer: [
        AddTile(
          label: l10n.newCollectionTile,
          onTap: () => _createCollection(context, store),
        ),
      ],
      children: [
        for (final name in store.cols)
          _CollectionCard(key: ValueKey(name), name: name),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final String name;
  const _CollectionCard({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final outfits = store.saved[name] ?? [];
    final cover = outfits.isEmpty
        ? null
        : outfits.last.itemIds
              .map(store.itemById)
              .whereType<ClothingItem>()
              .toList();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CollectionDetailScreen(name: name)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.rowBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: cover == null
                  ? Container(
                      color: AppColors.cardFill,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.checkroom_outlined,
                        size: 28,
                        color: AppColors.mutedSoft,
                      ),
                    )
                  : OutfitCollage(items: cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppLocalizations.of(context)!.outfitCount(outfits.length),
                    style: AppText.mono(
                      size: 9,
                      letterSpacing: 0.6,
                      color: AppColors.mutedSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _createCollection(
  BuildContext context,
  WardrobeStore store,
) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await promptTextDialog(
    context,
    title: l10n.newCollectionDialogTitle,
    initialValue: '',
    hintText: l10n.newCollectionHint,
    confirmLabel: l10n.create,
  );
  if (name != null && name.trim().isNotEmpty) store.addCollection(name);
}
