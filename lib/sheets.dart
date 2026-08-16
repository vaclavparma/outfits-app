import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

const Map<WardrobeZone, String> _zoneDefaultCategory = {
  WardrobeZone.top: 'tricka',
  WardrobeZone.bottom: 'kalhoty',
  WardrobeZone.shoes: 'boty',
};

Future<T?> _showSheet<T>(BuildContext context, String title, Widget content) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x47141414),
    builder: (sheetContext) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: _sheetTitleStyle)),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: Text(
                        'zavřít',
                        style: AppText.mono(
                          size: 10,
                          letterSpacing: 1,
                          color: AppColors.mutedTag,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                content,
              ],
            ),
          ),
        ),
      );
    },
  );
}

final TextStyle _sheetTitleStyle = AppText.sans(
  size: 20,
  weight: FontWeight.w300,
  color: AppColors.ink,
  letterSpacing: -0.2,
);

void openPickSheet(BuildContext context, WardrobeZone zone) {
  final titles = {
    WardrobeZone.top: 'Vyber top nebo šaty',
    WardrobeZone.bottom: 'Vyber spodek',
    WardrobeZone.shoes: 'Vyber boty',
  };
  _showSheet(
    context,
    titles[zone]!,
    _PickGrid(zone: zone, hostContext: context),
  );
}

class _PickGrid extends StatelessWidget {
  final WardrobeZone zone;
  final BuildContext hostContext;
  const _PickGrid({required this.zone, required this.hostContext});

  void _addNew(BuildContext context) {
    Navigator.of(context).pop();
    openAddItemSheet(
      hostContext,
      presetCategory: _zoneDefaultCategory[zone],
      onAdded: (item) {
        final store = hostContext.read<WardrobeStore>();
        final idx = store.zoneList(zone).indexWhere((i) => i.id == item.id);
        if (idx >= 0) store.selectIndex(zone, idx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final fullList = store.zoneList(zone);
    final current = store.at(fullList, zone);

    final zoneTags = distinctTags(fullList);
    final filtered = store.tagFilter == null
        ? fullList
        : fullList.where((it) => it.tags.contains(store.tagFilter)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (zoneTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final t in zoneTags)
                  SelectChip(
                    label: t,
                    active: store.tagFilter == t,
                    onTap: () => store.toggleTagFilter(t),
                  ),
              ],
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 100 / 124,
          ),
          itemBuilder: (context, i) {
            if (i == filtered.length) {
              return GestureDetector(
                onTap: () => _addNew(context),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.dashedBorder),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+',
                        style: AppText.sans(
                          size: 22,
                          weight: FontWeight.w300,
                          color: AppColors.mutedSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'přidat',
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
            }
            final it = filtered[i];
            return GarmentCard(
              width: double.infinity,
              height: double.infinity,
              slotLabel: shortCategoryLabel(it.cat).toLowerCase(),
              tags: it.tagsLabel,
              imagePath: it.imagePath,
              borderColor: current?.id == it.id
                  ? AppColors.ink
                  : AppColors.cardBorder,
              onTap: () {
                final actualIndex = fullList.indexWhere((x) => x.id == it.id);
                store.selectIndex(zone, actualIndex);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ],
    );
  }
}

void openLayerSheet(BuildContext context) {
  _showSheet(context, 'Přidat vrstvu', const _LayerChoices());
}

class _LayerChoices extends StatelessWidget {
  const _LayerChoices();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    if (store.layers.length >= WardrobeStore.kMaxLayers) {
      return Text(
        'Můžeš mít nejvýš ${WardrobeStore.kMaxLayers} vrstvy navíc.',
        style: AppText.sans(size: 12, color: AppColors.mutedTag),
      );
    }
    final choices = store
        .byCat('bundy')
        .where((it) => !store.layers.contains(it.id))
        .toList();
    if (choices.isEmpty) {
      return Text(
        'Žádné další vrstvy k přidání.',
        style: AppText.sans(size: 12, color: AppColors.mutedTag),
      );
    }
    return Column(
      children: [
        for (final it in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: GestureDetector(
              onTap: () {
                store.addLayer(it.id);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.rowBorder),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cardFill,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          (it.imagePath != null &&
                              File(it.imagePath!).existsSync())
                          ? Image.file(File(it.imagePath!), fit: BoxFit.cover)
                          : const DiagonalStripes(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      it.tagsLabel.isNotEmpty ? it.tagsLabel : 'bez tagů',
                      style: AppText.mono(
                        size: 8.5,
                        letterSpacing: 0.4,
                        color: AppColors.mutedTag,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

void openAddItemSheet(
  BuildContext context, {
  String? presetCategory,
  void Function(ClothingItem item)? onAdded,
}) {
  _showSheet(
    context,
    'Přidat kus',
    _AddItemForm(presetCategory: presetCategory, onAdded: onAdded),
  );
}

class _AddItemForm extends StatefulWidget {
  final String? presetCategory;
  final void Function(ClothingItem item)? onAdded;

  const _AddItemForm({this.presetCategory, this.onAdded});

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  late String _cat;
  final List<String> _tags = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _cat = widget.presetCategory ?? 'boty';
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;
      if (!mounted) return;
      final item = await context.read<WardrobeStore>().addItem(
        _cat,
        _tags,
        sourceImagePath: file.path,
      );
      widget.onAdded?.call(item);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'kategorie',
          style: AppText.mono(
            size: 9.5,
            letterSpacing: 1.3,
            color: AppColors.mutedSoft,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final c in kCategories)
              SelectChip(
                label: c.label,
                active: _cat == c.key,
                mono: false,
                height: 34,
                onTap: () => setState(() => _cat = c.key),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'tagy (nepovinné)',
          style: AppText.mono(
            size: 9.5,
            letterSpacing: 1.3,
            color: AppColors.mutedSoft,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final t in kQuickTags)
              SelectChip(
                label: t,
                active: _tags.contains(t),
                onTap: () => setState(
                  () => _tags.contains(t) ? _tags.remove(t) : _tags.add(t),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _busy ? null : () => _pick(ImageSource.camera),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Vyfotit',
                          style: AppText.sans(
                            size: 13,
                            weight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: GestureDetector(
                onTap: _busy ? null : () => _pick(ImageSource.gallery),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Z galerie',
                    style: AppText.sans(size: 13, color: AppColors.label),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

void openItemSheet(BuildContext context, ClothingItem item) {
  _showSheet(context, 'Detail kusu', _ItemDetail(itemId: item.id));
}

class _ItemDetail extends StatefulWidget {
  final String itemId;
  const _ItemDetail({required this.itemId});

  @override
  State<_ItemDetail> createState() => _ItemDetailState();
}

class _ItemDetailState extends State<_ItemDetail> {
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final cur = store.itemById(widget.itemId);
    if (cur == null) return const SizedBox.shrink();
    final tags = cur.tags;
    final suggest = kQuickTags.where((t) => !tags.contains(t)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 66,
              height: 84,
              child: GarmentCard(
                width: 66,
                height: 84,
                imagePath: cur.imagePath,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              categoryLabel(cur.cat),
              style: AppText.sans(size: 15, color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'tagy kusu',
          style: AppText.mono(
            size: 9.5,
            letterSpacing: 1.3,
            color: AppColors.mutedSoft,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final t in tags)
              Container(
                height: 30,
                padding: const EdgeInsets.only(left: 12, right: 6),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t, style: AppText.mono(size: 11, color: Colors.white)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => store.setTags(
                        cur.id,
                        tags.where((x) => x != t).toList(),
                      ),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '×',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (tags.isEmpty)
              Text(
                'bez tagů',
                style: AppText.mono(
                  size: 11,
                  color: AppColors.mutedSoft,
                  height: 1.6,
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final t in suggest)
              GestureDetector(
                onTap: () => store.setTags(cur.id, [...tags, t]),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.dashedBorder),
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      '+ $t',
                      style: AppText.mono(size: 11, color: AppColors.muted),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'vlastní tag',
                  hintStyle: AppText.sans(size: 13, color: AppColors.mutedTag),
                  filled: true,
                  fillColor: AppColors.background,
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
                final t = _tagController.text.trim().toLowerCase();
                if (t.isEmpty || tags.contains(t)) return;
                store.setTags(cur.id, [...tags, t]);
                _tagController.clear();
              },
              child: const Text(
                '+',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  store.useItem(cur);
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Použít v outfitu',
                    style: AppText.sans(
                      size: 13,
                      weight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            GestureDetector(
              onTap: () => _confirmDeleteItem(context, store, cur),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Smazat',
                  style: AppText.sans(size: 13, color: AppColors.muted),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

void openSaveOutfitSheet(BuildContext context) {
  _showSheet(context, 'Uložit outfit', const _SaveOutfitForm());
}

class _SaveOutfitForm extends StatefulWidget {
  const _SaveOutfitForm();

  @override
  State<_SaveOutfitForm> createState() => _SaveOutfitFormState();
}

class _SaveOutfitFormState extends State<_SaveOutfitForm> {
  final _nameController = TextEditingController();
  String? _selectedCol;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final hasCols = store.cols.isNotEmpty;
    _selectedCol ??= hasCols ? store.cols.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'název outfitu',
          style: AppText.mono(
            size: 9.5,
            letterSpacing: 1.3,
            color: AppColors.mutedSoft,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'např. Pondělní porada',
            hintStyle: AppText.sans(size: 14, color: AppColors.mutedTag),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
          style: AppText.sans(size: 14, color: AppColors.ink),
        ),
        const SizedBox(height: 18),
        Text(
          'kolekce',
          style: AppText.mono(
            size: 9.5,
            letterSpacing: 1.3,
            color: AppColors.mutedSoft,
          ),
        ),
        const SizedBox(height: 8),
        if (hasCols)
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final c in store.cols)
                SelectChip(
                  label: c,
                  active: _selectedCol == c,
                  mono: false,
                  height: 34,
                  onTap: () => setState(() => _selectedCol = c),
                ),
            ],
          )
        else
          Text(
            'Nejdřív vytvoř kolekci v záložce Kolekce.',
            style: AppText.sans(
              size: 12.5,
              color: AppColors.mutedTag,
              height: 1.4,
            ),
          ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: !hasCols
              ? null
              : () async {
                  await store.saveOutfit(
                    rawName: _nameController.text,
                    targetCol: _selectedCol ?? '',
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: hasCols ? AppColors.ink : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              'Uložit',
              style: AppText.sans(
                size: 13,
                weight: FontWeight.w500,
                color: hasCols ? Colors.white : AppColors.mutedSoft,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void openManageTagsSheet(BuildContext context) {
  _showSheet(context, 'Spravovat tagy', const _ManageTagsList());
}

class _ManageTagsList extends StatelessWidget {
  const _ManageTagsList();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final allTags = distinctTags(store.items);
    if (allTags.isEmpty) {
      return Text(
        'Zatím žádné tagy. Vytvoříš je při přidávání nebo úpravě kusu.',
        style: AppText.sans(size: 12.5, color: AppColors.mutedTag, height: 1.4),
      );
    }
    return Column(
      children: [
        for (final tag in allTags)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.rowBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tag,
                      style: AppText.sans(size: 13, color: AppColors.ink),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 17,
                      color: AppColors.mutedSoft,
                    ),
                    onPressed: () => _renameTag(context, store, tag),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.mutedSoft,
                    ),
                    onPressed: () => _confirmDeleteTag(context, store, tag),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> _renameTag(
  BuildContext context,
  WardrobeStore store,
  String tag,
) async {
  final newTag = await promptTextDialog(
    context,
    title: 'Přejmenovat tag',
    initialValue: tag,
  );
  if (newTag != null) store.renameTag(tag, newTag);
}

Future<void> _confirmDeleteItem(
  BuildContext context,
  WardrobeStore store,
  ClothingItem item,
) async {
  final confirmed = await confirmDialog(
    context,
    title: 'Smazat kus?',
    message: 'Oblečení bude smazáno. Tuto akci nelze vrátit.',
  );
  if (!confirmed) return;
  await store.deleteItem(item);
  if (context.mounted) Navigator.of(context).pop();
}

Future<void> _confirmDeleteTag(
  BuildContext context,
  WardrobeStore store,
  String tag,
) async {
  final confirmed = await confirmDialog(
    context,
    title: 'Smazat tag?',
    message: 'Tag „$tag“ bude smazán a odebrán ze všech kusů oblečení.',
  );
  if (confirmed) store.deleteTag(tag);
}
