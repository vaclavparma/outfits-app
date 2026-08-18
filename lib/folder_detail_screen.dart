import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Full-screen (pushed) view of one folder's clothing, mirroring
/// [CollectionDetailScreen]: renaming/deleting the folder lives here, in a
/// header menu, and the trailing tile in the grid adds a new item to it.
class FolderDetailScreen extends StatefulWidget {
  final String catKey;
  final String name;
  const FolderDetailScreen({
    super.key,
    required this.catKey,
    required this.name,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  // Tracks renames locally so a rename isn't mistaken for the folder having
  // been deleted (which also removes the old name from knownFolders).
  late String _name = widget.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<WardrobeStore>(
          builder: (context, store, _) {
            if (!store.foldersFor(widget.catKey).contains(_name)) {
              // The folder was deleted — pop back out once that's processed.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }
            final l10n = AppLocalizations.of(context)!;
            final items = store
                .byCat(widget.catKey)
                .where((it) => it.folder == _name)
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 16,
                            weight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 20,
                          color: AppColors.ink,
                        ),
                        color: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(0x1F000000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.rowBorder),
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (action) =>
                            _handleMenuAction(store, action),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'rename',
                            height: 44,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 17,
                                  color: AppColors.mutedSoft,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)!.rename,
                                  style: AppText.sans(
                                    size: 13.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            height: 44,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  size: 17,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)!.delete,
                                  style: AppText.sans(
                                    size: 13.5,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          childAspectRatio: 100 / 124,
                        ),
                    itemCount: items.length + 1,
                    itemBuilder: (context, i) {
                      if (i == items.length) {
                        return AddTile(
                          label: l10n.add,
                          onTap: () => openAddItemSheet(
                            context,
                            presetCategory: widget.catKey,
                            presetFolder: _name,
                          ),
                        );
                      }
                      final it = items[i];
                      return GarmentCard(
                        width: double.infinity,
                        height: double.infinity,
                        imagePath: it.imagePath,
                        onTap: () => openItemSheet(context, it),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(WardrobeStore store, String action) async {
    final l10n = AppLocalizations.of(context)!;
    if (action == 'rename') {
      final newName = await promptTextDialog(
        context,
        title: l10n.renameFolderTitle,
        initialValue: _name,
        confirmLabel: l10n.save,
      );
      if (newName == null) return;
      final applied = await store.renameFolder(widget.catKey, _name, newName);
      setState(() => _name = applied);
    } else if (action == 'delete') {
      final confirmed = await confirmDialog(
        context,
        title: l10n.deleteFolderTitle,
        message: l10n.deleteFolderMessage(_name),
        confirmLabel: l10n.delete,
      );
      if (confirmed) store.deleteFolder(widget.catKey, _name);
    }
  }
}
