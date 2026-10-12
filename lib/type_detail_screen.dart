import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Full-screen (pushed) view of one type's clothing in the active
/// wardrobe — like a folder: renaming/deleting the type lives in the header
/// menu, and the trailing tile in the grid adds clothing to it.
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
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 20, color: AppColors.ink),
                        color: AppColors.surface,
                        elevation: 3,
                        shadowColor: const Color(0x1F000000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.rowBorder),
                        ),
                        onSelected: (action) async {
                          if (action == 'rename') {
                            final name = await promptTextDialog(
                              context,
                              title: l10n.renameTypeTitle,
                              initialValue: type.name,
                              confirmLabel: l10n.save,
                            );
                            if (name != null) store.renameType(kindId, typeId, name);
                          } else if (context.mounted) {
                            await deleteTypeAskingWhereTo(context, kind, type);
                          }
                        },
                        itemBuilder: (context) => [
                          _menuItem('rename', Icons.edit_outlined, l10n.rename, AppColors.ink),
                          // Every item needs a type, so the last one stays.
                          if (kind.types.length > 1)
                            _menuItem('delete', Icons.delete_outline, l10n.delete, AppColors.danger),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    crossAxisCount: gridColumns(context, 3),
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 100 / 124,
                    children: [
                      for (final it in items)
                        GarmentCard(
                          width: double.infinity,
                          height: double.infinity,
                          caption: it.name ?? '',
                          imagePath: it.imagePath,
                          onTap: () => openItemSheet(context, it, browseIds: [for (final x in items) x.id]),
                        ),
                      AddTile(
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

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color == AppColors.ink ? AppColors.mutedSoft : color),
          const SizedBox(width: 10),
          Text(label, style: AppText.sans(size: 13.5, color: color)),
        ],
      ),
    );
  }
}
