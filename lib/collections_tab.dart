import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

class CollectionsTab extends StatefulWidget {
  const CollectionsTab({super.key});

  @override
  State<CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends State<CollectionsTab> {
  final _newColController = TextEditingController();

  @override
  void dispose() {
    _newColController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            children: [
              if (store.cols.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Zatím žádné kolekce. Založ první níže.',
                    style: AppText.sans(size: 13, color: AppColors.mutedTag, height: 1.5),
                  ),
                ),
              for (final name in store.cols)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _renameCollection(context, store, name),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(name, style: AppText.sans(size: 13, color: AppColors.ink)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.edit_outlined, size: 13, color: AppColors.mutedSoft),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text('${(store.saved[name] ?? []).length} outfitů',
                                  style: AppText.mono(size: 9, letterSpacing: 1, color: AppColors.mutedSoft)),
                              const SizedBox(width: 10),
                              RoundIconButton(
                                size: 22,
                                background: Colors.white,
                                borderColor: const Color(0xFFEAE9E7),
                                onTap: () => _confirmDeleteCollection(context, store, name),
                                child: const Text('×',
                                    style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if ((store.saved[name] ?? []).isEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E0DC)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Zatím prázdné. Ulož outfit a vyber tuto kolekci.',
                              style: AppText.sans(size: 11, color: AppColors.mutedTag, height: 1.5),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (var k = 0; k < (store.saved[name] ?? []).length; k++)
                              _OutfitRow(colName: name, index: k, outfit: store.saved[name]![k]),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newColController,
                  decoration: InputDecoration(
                    hintText: 'Nová kolekce',
                    hintStyle: AppText.sans(size: 13, color: AppColors.mutedTag),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  style: AppText.sans(size: 13, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                size: 42,
                onTap: () {
                  store.addCollection(_newColController.text);
                  _newColController.clear();
                },
                child: const Text('+',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: Colors.white, height: 1)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _renameCollection(BuildContext context, WardrobeStore store, String name) async {
  final newName = await showDialog<String>(
    context: context,
    builder: (dialogContext) => _RenameCollectionDialog(initialName: name),
  );
  if (newName != null) store.renameCollection(name, newName);
}

class _RenameCollectionDialog extends StatefulWidget {
  final String initialName;
  const _RenameCollectionDialog({required this.initialName});

  @override
  State<_RenameCollectionDialog> createState() => _RenameCollectionDialogState();
}

class _RenameCollectionDialogState extends State<_RenameCollectionDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Přejmenovat kolekci', style: AppText.sans(size: 16, color: AppColors.ink)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: AppText.sans(size: 14, color: AppColors.ink),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Zrušit', style: AppText.sans(size: 13, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text('Uložit', style: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.accent)),
        ),
      ],
    );
  }
}

Future<void> _confirmDeleteCollection(BuildContext context, WardrobeStore store, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Smazat kolekci?', style: AppText.sans(size: 16, color: AppColors.ink)),
      content: Text(
        'Kolekce „$name“ a všechny uložené outfity v ní budou smazány.',
        style: AppText.sans(size: 13, color: AppColors.label, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Zrušit', style: AppText.sans(size: 13, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Smazat', style: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.accent)),
        ),
      ],
    ),
  );
  if (confirmed == true) store.deleteCollection(name);
}

class _OutfitRow extends StatelessWidget {
  final String colName;
  final int index;
  final SavedOutfit outfit;

  const _OutfitRow({required this.colName, required this.index, required this.outfit});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    ClothingItem? findItem(String id) {
      for (final i in store.items) {
        if (i.id == id) return i;
      }
      return null;
    }

    final thumbs = outfit.itemIds.take(4).map(findItem).whereType<ClothingItem>().toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.rowBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => store.loadOutfit(outfit),
                child: Row(
                  children: [
                    for (final it in thumbs)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 26,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.cardFill,
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (it.imagePath != null && File(it.imagePath!).existsSync())
                            ? Image.file(File(it.imagePath!), fit: BoxFit.cover)
                            : const DiagonalStripes(),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(outfit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(size: 13, color: AppColors.ink)),
                          const SizedBox(height: 3),
                          Text(outfit.meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.mono(size: 8.5, letterSpacing: 0.4, color: AppColors.mutedTag)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            RoundIconButton(
              size: 24,
              background: Colors.white,
              borderColor: const Color(0xFFEAE9E7),
              onTap: () => store.deleteOutfit(colName, index),
              child: const Text('×', style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
