import 'dart:io';

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
            Expanded(child: _OutfitCollage(items: items)),
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

/// A compact collage of an outfit's item photos, so it reads at a glance —
/// one big tile for a single item, a big-plus-stacked split for 2-3, and a
/// full 2x2 grid for 4.
class _OutfitCollage extends StatelessWidget {
  final List<ClothingItem> items;
  const _OutfitCollage({required this.items});

  @override
  Widget build(BuildContext context) {
    final shown = items.take(4).toList();
    if (shown.isEmpty) {
      return const DiagonalStripes();
    }
    if (shown.length == 1) {
      return _tile(shown[0]);
    }
    if (shown.length >= 4) {
      return GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: shown.take(4).map(_tile).toList(),
      );
    }
    // 2 or 3 items: one big tile on the left, the rest stacked on the right.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: _tile(shown[0]),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              for (var i = 1; i < shown.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: i > 1 ? 1 : 0,
                      bottom: i < shown.length - 1 ? 1 : 0,
                    ),
                    child: _tile(shown[i]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(ClothingItem it) {
    final hasImage = it.imagePath != null && File(it.imagePath!).existsSync();
    return Container(
      color: AppColors.cardFill,
      child: hasImage
          ? Image.file(File(it.imagePath!), fit: BoxFit.cover)
          : const DiagonalStripes(),
    );
  }
}
