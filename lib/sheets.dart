import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

const Map<WardrobeZone, String> _zoneDefaultCategory = {
  WardrobeZone.top: 'tricka',
  WardrobeZone.bottom: 'kalhoty',
  WardrobeZone.shoes: 'boty',
};

/// [title] is resolved inside the sheet's own builder (via [sheetContext]),
/// not by the caller, so it stays correct if the locale changes while the
/// sheet is open (e.g. switching language from the settings sheet itself).
Future<T?> _showSheet<T>(
  BuildContext context,
  String Function(BuildContext) title,
  Widget content, {
  bool showCloseLink = true,
}) {
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
                    Expanded(
                      child: Text(title(sheetContext), style: _sheetTitleStyle),
                    ),
                    if (showCloseLink)
                      GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: Text(
                          AppLocalizations.of(sheetContext)!.close,
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

/// Small uppercase-mono label above a form field/section within a sheet
/// (e.g. "kategorie", "tagy", "kolekce").
final TextStyle _sectionLabelStyle = AppText.mono(
  size: 9.5,
  letterSpacing: 1.3,
  color: AppColors.mutedSoft,
);

void openPickSheet(BuildContext context, WardrobeZone zone) {
  String title(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    return switch (zone) {
      WardrobeZone.top => l10n.pickTopTitle,
      WardrobeZone.bottom => l10n.pickBottomTitle,
      WardrobeZone.shoes => l10n.pickShoesTitle,
    };
  }

  _showSheet(context, title, _PickGrid(zone: zone, hostContext: context));
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
              return AddTile(
                label: AppLocalizations.of(context)!.add,
                onTap: () => _addNew(context),
              );
            }
            final it = filtered[i];
            return GarmentCard(
              width: double.infinity,
              height: double.infinity,
              slotLabel: shortCategoryLabel(context, it.cat).toLowerCase(),
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
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.addLayerTitle,
    const _LayerChoices(),
  );
}

class _LayerChoices extends StatelessWidget {
  const _LayerChoices();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    if (store.layers.length >= WardrobeStore.kMaxLayers) {
      return Text(
        l10n.layerLimitMessage(WardrobeStore.kMaxLayers),
        style: AppText.sans(size: 12, color: AppColors.mutedTag),
      );
    }
    final choices = store
        .byCat('bundy')
        .where((it) => !store.layers.contains(it.id))
        .toList();
    if (choices.isEmpty) {
      return Text(
        l10n.noMoreLayers,
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
                      child: it.imagePath == null
                          ? const DiagonalStripes()
                          : GarmentImage(it.imagePath!),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      it.tagsLabel.isNotEmpty ? it.tagsLabel : l10n.noTags,
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
    (ctx) => AppLocalizations.of(ctx)!.addItemTitle,
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
      final store = context.read<WardrobeStore>();
      final l10n = AppLocalizations.of(context)!;
      final label = categoryLabel(context, _cat);
      final result = await store.addItem(
        _cat,
        _tags,
        sourceImagePath: file.path,
      );
      store.flash(
        result.photoFailed
            ? l10n.toastSavedPhotoFailed(label)
            : l10n.toastSavedWithPhoto(label),
      );
      widget.onAdded?.call(result.item);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = context.watch<WardrobeStore>().visibleCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sectionCategory, style: _sectionLabelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final c in categories)
              SelectChip(
                label: categoryLabel(context, c.key),
                active: _cat == c.key,
                mono: false,
                height: 34,
                onTap: () => setState(() => _cat = c.key),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(l10n.sectionTagsOptional, style: _sectionLabelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final t in kQuickTags(context))
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
                          l10n.takePhoto,
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
                    l10n.fromGallery,
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
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.itemDetailTitle,
    _ItemDetail(itemId: item.id),
  );
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
    final l10n = AppLocalizations.of(context)!;
    final cur = store.itemById(widget.itemId);
    if (cur == null) return const SizedBox.shrink();
    final tags = cur.tags;
    final suggest = kQuickTags(
      context,
    ).where((t) => !tags.contains(t)).toList();

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
              categoryLabel(context, cur.cat),
              style: AppText.sans(size: 15, color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(l10n.sectionItemTags, style: _sectionLabelStyle),
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
                l10n.noTags,
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
                  hintText: l10n.customTagHint,
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
                    l10n.useInOutfit,
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
                  l10n.delete,
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
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.saveOutfitButton,
    const _SaveOutfitForm(),
  );
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
    final l10n = AppLocalizations.of(context)!;
    final hasCols = store.cols.isNotEmpty;
    _selectedCol ??= hasCols ? store.cols.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sectionOutfitName, style: _sectionLabelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: l10n.outfitNameHint,
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
        Text(l10n.sectionCollection, style: _sectionLabelStyle),
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
            l10n.needCollectionHint,
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
                  final result = await store.saveOutfit(
                    rawName: _nameController.text,
                    targetCol: _selectedCol ?? '',
                    defaultName: l10n.defaultOutfitName,
                  );
                  if (result != null) {
                    store.flash(
                      l10n.toastOutfitSaved(result.name, result.col),
                    );
                  } else {
                    store.flash(l10n.toastNeedCollectionFirst);
                  }
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
              l10n.save,
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
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.manageTagsTitle,
    const _ManageTagsList(),
  );
}

class _ManageTagsList extends StatelessWidget {
  const _ManageTagsList();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final allTags = distinctTags(store.items);
    if (allTags.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.noTagsYet,
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
  final l10n = AppLocalizations.of(context)!;
  final newTag = await promptTextDialog(
    context,
    title: l10n.renameTagTitle,
    initialValue: tag,
    confirmLabel: l10n.save,
  );
  if (newTag != null) store.renameTag(tag, newTag);
}

Future<void> _confirmDeleteItem(
  BuildContext context,
  WardrobeStore store,
  ClothingItem item,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await confirmDialog(
    context,
    title: l10n.deleteItemTitle,
    message: '${l10n.deleteItemMessage} ${l10n.actionCannotBeUndone}',
    confirmLabel: l10n.delete,
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
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await confirmDialog(
    context,
    title: l10n.deleteTagTitle,
    message: l10n.deleteTagMessage(tag),
    confirmLabel: l10n.delete,
  );
  if (confirmed) store.deleteTag(tag);
}

void openSettingsSheet(BuildContext context) {
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.settingsTitle,
    const _SettingsContent(),
    showCloseLink: false,
  );
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sectionLanguage, style: _sectionLabelStyle),
        const SizedBox(height: 8),
        _SettingsCard(
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              SelectChip(
                label: l10n.languageSystemOption,
                active: store.localeCode == null,
                mono: false,
                height: 34,
                onTap: () => store.setLocale(null),
              ),
              // Each language's own name, not translated — a language
              // picker conventionally shows every option in its own
              // language so it stays legible no matter which one is active.
              SelectChip(
                label: 'Čeština',
                active: store.localeCode == 'cs',
                mono: false,
                height: 34,
                onTap: () => store.setLocale('cs'),
              ),
              SelectChip(
                label: 'English',
                active: store.localeCode == 'en',
                mono: false,
                height: 34,
                onTap: () => store.setLocale('en'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SettingsCard(
          child: _ToggleRow(
            label: l10n.showDressesLabel,
            hint: l10n.showDressesHint,
            value: store.showDresses,
            onChanged: store.setShowDresses,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          child: _ToggleRow(
            label: l10n.showSkirtsLabel,
            hint: l10n.showSkirtsHint,
            value: store.showSkirts,
            onChanged: store.setShowSkirts,
          ),
        ),
      ],
    );
  }
}

/// Shared bordered-card chrome for a settings section — used for the
/// language picker and every on/off row, so they all read as one family of
/// controls instead of the language picker looking like a bare label.
class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.rowBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

/// A settings on/off row: label + explanatory hint on the left, switch on
/// the right.
class _ToggleRow extends StatelessWidget {
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.sans(size: 13, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(
                hint,
                style: AppText.sans(
                  size: 11.5,
                  color: AppColors.mutedTag,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          activeThumbColor: AppColors.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
