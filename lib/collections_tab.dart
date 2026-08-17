import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'collection_detail_screen.dart';
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: store.cols.length + 1,
      itemBuilder: (context, i) {
        if (i == store.cols.length) {
          return AddTile(
            label: 'nová kolekce',
            onTap: () => _createCollection(context, store),
          );
        }
        final name = store.cols[i];
        final count = (store.saved[name] ?? []).length;
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CollectionDetailScreen(name: name),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.rowBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            alignment: Alignment.bottomLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 1 ? '1 outfit' : '$count outfitů',
                  style: AppText.mono(
                    size: 9,
                    letterSpacing: 0.6,
                    color: AppColors.mutedSoft,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _createCollection(
  BuildContext context,
  WardrobeStore store,
) async {
  final name = await promptTextDialog(
    context,
    title: 'Nová kolekce',
    initialValue: '',
    hintText: 'např. Práce',
    confirmLabel: 'Vytvořit',
  );
  if (name != null && name.trim().isNotEmpty) store.addCollection(name);
}
