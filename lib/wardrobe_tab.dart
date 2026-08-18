import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'folder_detail_screen.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// One SliverGrid of folder tiles per category, mirroring [CollectionsTab]:
/// tap a folder to see (and add) its clothing on [FolderDetailScreen]; the
/// trailing tile in each category creates a new folder there.
class WardrobeTab extends StatelessWidget {
  final void Function(ClothingItem item) onOpenItem;

  const WardrobeTab({super.key, required this.onOpenItem});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;

    // Every category is always shown (even empty ones) so there's always a
    // + tile to create its first folder — no separate empty state needed.
    final sections = store.visibleCategories
        .map((c) => (c, store.foldersFor(c.key)))
        .toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          sliver: SliverMainAxisGroup(
            slivers: [
              for (final (cat, folders) in sections) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: categoryLabel(context, cat.key),
                    trailing: l10n.itemCount(store.byCat(cat.key).length),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 22),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i == folders.length) {
                          return AddTile(
                            label: l10n.newFolderTile,
                            onTap: () => _createFolder(context, store, cat.key),
                          );
                        }
                        return _FolderCard(catKey: cat.key, name: folders[i]);
                      },
                      childCount: folders.length + 1,
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

class _FolderCard extends StatelessWidget {
  final String catKey;
  final String name;
  const _FolderCard({required this.catKey, required this.name});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final items = store
        .byCat(catKey)
        .where((it) => it.folder == name)
        .toList();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FolderDetailScreen(catKey: catKey, name: name),
        ),
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
              child: items.isEmpty
                  ? Container(
                      color: AppColors.cardFill,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.checkroom_outlined,
                        size: 28,
                        color: AppColors.mutedSoft,
                      ),
                    )
                  : OutfitCollage(items: items),
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
                    AppLocalizations.of(context)!.itemCount(items.length),
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

Future<void> _createFolder(
  BuildContext context,
  WardrobeStore store,
  String catKey,
) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await promptTextDialog(
    context,
    title: l10n.newFolderDialogTitle,
    initialValue: '',
    hintText: l10n.newFolderHint,
    confirmLabel: l10n.create,
  );
  if (name != null && name.trim().isNotEmpty) store.addFolder(catKey, name);
}
