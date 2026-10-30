import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

import 'l10n/app_localizations.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Full-screen (pushed) view of one type's clothing in the active
/// wardrobe — like a folder; the trailing tile in the grid adds clothing to
/// it. Types are renamed and deleted in settings.
class TypeDetailScreen extends StatelessWidget {
  final String kindId;
  final String typeId;
  const TypeDetailScreen({super.key, required this.kindId, required this.typeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<WardrobeStore>(
          builder: (context, store, _) {
            final kind = store.kindById(kindId);
            final type = kind?.typeById(typeId);
            if (kind == null || type == null) {
              // The type was deleted — pop back out once that's processed.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }
            final l10n = AppLocalizations.of(context)!;
            final items = store.itemsOfKind(kindId).where((it) => it.typeId == typeId).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: Row(
                    children: [
                      const AppBackButton(),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              type.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(size: 16, weight: FontWeight.w500, color: AppColors.ink),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              kind.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.mono(size: 9.5, letterSpacing: 0.6, color: AppColors.mutedSoft),
                            ),
                          ],
                        ),
                      ),
                      // Balances the back button so the title stays centered.
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Hold an item and drag it to put the type's clothes in
                // another order; "+" stays last.
                Expanded(
                  child: ReorderableGridView.count(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    crossAxisCount: gridColumns(context, 3),
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 100 / 124,
                    buildDefaultDragHandles: false,
                    itemDragEnable: (i) => i < items.length,
                    proxyDecorator: liftedTile(17),
                    onReorderStart: (_) => Haptics.pickUp(),
                    onReorder: (from, to) => store.reorderItemsInType(kindId, typeId, from, to),
                    children: [
                      for (final (i, it) in items.indexed)
                        GridDragStart(
                          key: ValueKey(it.id),
                          index: i,
                          child: GarmentCard(
                            width: double.infinity,
                            height: double.infinity,
                            imagePath: it.imagePath,
                            onTap: () => openItemDetail(context, it, browseIds: [for (final x in items) x.id]),
                          ),
                        ),
                      AddTile(
                        key: const ValueKey('+'),
                        label: l10n.add,
                        onTap: () => openAddItemSheet(context, presetKind: kindId, presetType: typeId),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
