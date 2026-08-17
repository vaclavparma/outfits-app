import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Full-screen (pushed) view of one collection's outfits. Renaming/deleting
/// the collection lives here, in a proper header menu, rather than being
/// crammed into the overview card.
class CollectionDetailScreen extends StatefulWidget {
  final String name;
  const CollectionDetailScreen({super.key, required this.name});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  // Tracks renames locally so a rename isn't mistaken for the collection
  // having been deleted (which also removes the old name from store.cols).
  late String _name = widget.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<WardrobeStore>(
          builder: (context, store, _) {
            if (!store.cols.contains(_name)) {
              // The collection was deleted — pop back out once that's processed.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }
            final outfits = store.saved[_name] ?? [];
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
                        onSelected: (action) =>
                            _handleMenuAction(store, action),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(
                              'Přejmenovat',
                              style: AppText.sans(
                                size: 14,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Smazat',
                              style: AppText.sans(
                                size: 14,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: outfits.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Zatím prázdné. Ulož outfit a vyber tuto kolekci.',
                              textAlign: TextAlign.center,
                              style: AppText.sans(
                                size: 13,
                                color: AppColors.mutedTag,
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: outfits.length,
                          itemBuilder: (context, i) => _OutfitCard(
                            colName: _name,
                            index: i,
                            outfit: outfits[i],
                          ),
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
    if (action == 'rename') {
      final newName = await promptTextDialog(
        context,
        title: 'Přejmenovat kolekci',
        initialValue: _name,
      );
      if (newName == null) return;
      final applied = await store.renameCollection(_name, newName);
      setState(() => _name = applied);
    } else if (action == 'delete') {
      final confirmed = await confirmDialog(
        context,
        title: 'Smazat kolekci?',
        message:
            'Kolekce „$_name“ a vše v ní bude smazáno. Tuto akci nelze vrátit.',
      );
      if (confirmed) store.deleteCollection(_name);
    }
  }
}

class _OutfitCard extends StatelessWidget {
  final String colName;
  final int index;
  final SavedOutfit outfit;

  const _OutfitCard({
    required this.colName,
    required this.index,
    required this.outfit,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final items = outfit.itemIds
        .map(store.itemById)
        .whereType<ClothingItem>()
        .toList();
    return GestureDetector(
      onTap: () {
        store.loadOutfit(outfit);
        Navigator.of(context).pop();
      },
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
            Expanded(child: OutfitCollage(items: items)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          outfit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(size: 13, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          outfit.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mono(
                            size: 8,
                            letterSpacing: 0.3,
                            color: AppColors.mutedTag,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    size: 22,
                    background: Colors.white,
                    borderColor: AppColors.removeButtonBorder,
                    onTap: () => _confirmDeleteOutfit(
                      context,
                      store,
                      colName,
                      index,
                      outfit.name,
                    ),
                    child: const Text(
                      '×',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        height: 1,
                      ),
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

Future<void> _confirmDeleteOutfit(
  BuildContext context,
  WardrobeStore store,
  String colName,
  int index,
  String outfitName,
) async {
  final confirmed = await confirmDialog(
    context,
    title: 'Smazat outfit?',
    message: '„$outfitName“ bude smazán. Tuto akci nelze vrátit.',
  );
  if (confirmed) store.deleteOutfit(colName, index);
}
