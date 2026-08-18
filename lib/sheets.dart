import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

const Map<WardrobeZone, String> _zoneDefaultCategory = {
  WardrobeZone.top: 'horni',
  WardrobeZone.bottom: 'dolni',
  WardrobeZone.shoes: 'boty',
};

/// [title] is resolved inside the sheet's own builder (via [sheetContext]),
/// not by the caller, so it stays correct if the locale changes while the
/// sheet is open (e.g. switching language from the settings sheet itself).
/// Sheets close via the standard swipe-down/tap-outside gestures — there's
/// no explicit "close" link in the header.
Future<T?> _showSheet<T>(
  BuildContext context,
  String Function(BuildContext) title,
  Widget content,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x47141414),
    builder: (sheetContext) {
      // Push the whole sheet up above the keyboard — without this, a
      // focused text field can end up hidden behind it, since the fixed
      // maxHeight below doesn't otherwise account for the keyboard's inset.
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: ConstrainedBox(
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
                  Text(title(sheetContext), style: _sheetTitleStyle),
                  const SizedBox(height: 16),
                  content,
                ],
              ),
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

    // The top zone spans two categories (horní díl + šaty), each with its
    // own folders — offer the union of both rather than picking one.
    final catsInZone = fullList.map((it) => it.cat).toSet();
    final allFolders = <String>[];
    for (final c in catsInZone) {
      for (final f in store.foldersFor(c)) {
        if (!allFolders.contains(f)) allFolders.add(f);
      }
    }
    final filtered = store.folderFilter == null
        ? fullList
        : fullList.where((it) => it.folder == store.folderFilter).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allFolders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final f in allFolders)
                  SelectChip(
                    label: f,
                    active: store.folderFilter == f,
                    onTap: () => store.toggleFolderFilter(f),
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
              caption: it.folder ?? '',
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

void openLayerSheet(BuildContext context, {int? replaceIndex}) {
  _showSheet(
    context,
    (ctx) => replaceIndex == null
        ? AppLocalizations.of(ctx)!.addLayerTitle
        : AppLocalizations.of(ctx)!.changeLayerTitle,
    _LayerChoices(replaceIndex: replaceIndex),
  );
}

class _LayerChoices extends StatelessWidget {
  final int? replaceIndex;
  const _LayerChoices({this.replaceIndex});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    if (replaceIndex == null && store.layers.length >= WardrobeStore.kMaxLayers) {
      return Text(
        l10n.layerLimitMessage(WardrobeStore.kMaxLayers),
        style: AppText.sans(size: 12, color: AppColors.mutedTag),
      );
    }
    // In replace mode, the layer being swapped stays selectable (it's not
    // "already used" from the user's point of view — it's what's on offer).
    final available = store
        .byCat('horni')
        .where(
          (it) =>
              !store.layers.contains(it.id) ||
              (replaceIndex != null && store.layers[replaceIndex!] == it.id),
        )
        .toList();
    if (available.isEmpty) {
      return Text(
        l10n.noMoreLayers,
        style: AppText.sans(size: 12, color: AppColors.mutedTag),
      );
    }
    final availableFolders = store.foldersFor('horni');
    final choices = store.folderFilter == null
        ? available
        : available.where((it) => it.folder == store.folderFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableFolders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final f in availableFolders)
                  SelectChip(
                    label: f,
                    active: store.folderFilter == f,
                    onTap: () => store.toggleFolderFilter(f),
                  ),
              ],
            ),
          ),
        if (choices.isEmpty)
          Text(
            l10n.noMoreLayers,
            style: AppText.sans(size: 12, color: AppColors.mutedTag),
          ),
        for (final it in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: GestureDetector(
              onTap: () {
                if (replaceIndex != null) {
                  store.setLayer(replaceIndex!, it.id);
                } else {
                  store.addLayer(it.id);
                }
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
                      width: 64,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.cardFill,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: it.imagePath == null
                          ? const DiagonalStripes()
                          : GarmentImage(it.imagePath!),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      it.folder ?? l10n.noFolder,
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
  String? presetFolder,
  void Function(ClothingItem item)? onAdded,
}) {
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.addItemTitle,
    _AddItemForm(
      presetCategory: presetCategory,
      presetFolder: presetFolder,
      onAdded: onAdded,
    ),
  );
}

class _AddItemForm extends StatefulWidget {
  final String? presetCategory;
  final String? presetFolder;
  final void Function(ClothingItem item)? onAdded;

  const _AddItemForm({this.presetCategory, this.presetFolder, this.onAdded});

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  late String _cat;
  String? _folder;
  bool _busy = false;

  /// Whether the category/folder are fixed by the caller (opened from
  /// inside a specific folder) rather than chosen in this form.
  bool get _fixedFolder => widget.presetFolder != null;

  @override
  void initState() {
    super.initState();
    _cat = widget.presetCategory ?? 'boty';
    _folder = widget.presetFolder ?? _defaultFolderFor(_cat);
  }

  /// Every item needs a folder, so default to whatever folder filter is
  /// active in the wardrobe grid (if it belongs to this category), else the
  /// first folder that exists for it, else none yet (category has none).
  String? _defaultFolderFor(String cat) {
    final store = context.read<WardrobeStore>();
    final folders = store.foldersFor(cat);
    if (folders.contains(store.folderFilter)) return store.folderFilter;
    return folders.isNotEmpty ? folders.first : null;
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy || _folder == null) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      // The gallery lets you select several photos at once — handy for
      // adding a handful of items of the same category/folder in one go.
      // The camera can only ever produce one photo per capture.
      final files = source == ImageSource.gallery
          ? await picker.pickMultiImage(imageQuality: 85)
          : await picker
                .pickImage(source: source, imageQuality: 85)
                .then((f) => f == null ? <XFile>[] : [f]);
      if (files.isEmpty) return;
      if (!mounted) return;
      final store = context.read<WardrobeStore>();
      final l10n = AppLocalizations.of(context)!;
      final label = categoryLabel(context, _cat);
      final result = await store.addItems(
        _cat,
        _folder!,
        sourceImagePaths: files.map((f) => f.path).toList(),
      );
      store.flash(
        files.length > 1
            ? l10n.toastSavedMultiple(files.length, label)
            : result.photoFailures > 0
            ? l10n.toastSavedPhotoFailed(label)
            : l10n.toastSavedWithPhoto(label),
      );
      widget.onAdded?.call(result.items.first);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = context.watch<WardrobeStore>();
    final categories = store.visibleCategories;
    final folders = store.foldersFor(_cat);
    final canAdd = _folder != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_fixedFolder) ...[
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
                  // A folder belongs to one category, so switching category
                  // picks a fresh default folder for the new one.
                  onTap: () => setState(() {
                    _cat = c.key;
                    _folder = _defaultFolderFor(_cat);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(l10n.sectionFolder, style: _sectionLabelStyle),
          const SizedBox(height: 8),
          if (folders.isEmpty)
            Text(
              l10n.needFolderHint,
              style: AppText.sans(
                size: 12.5,
                color: AppColors.mutedTag,
                height: 1.4,
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final f in folders)
                  SelectChip(
                    label: f,
                    active: _folder == f,
                    onTap: () => setState(() => _folder = f),
                  ),
              ],
            ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _busy || !canAdd
                    ? null
                    : () => _pick(ImageSource.camera),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: canAdd ? AppColors.accent : AppColors.cardBorder,
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
                            color: canAdd
                                ? Colors.white
                                : AppColors.mutedSoft,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: GestureDetector(
                onTap: _busy || !canAdd
                    ? null
                    : () => _pick(ImageSource.gallery),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.fromGallery,
                    style: AppText.sans(
                      size: 13,
                      color: canAdd ? AppColors.label : AppColors.mutedSoft,
                    ),
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

class _ItemDetail extends StatelessWidget {
  final String itemId;
  const _ItemDetail({required this.itemId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final cur = store.itemById(itemId);
    if (cur == null) return const SizedBox.shrink();
    final folders = store.foldersFor(cur.cat);

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
            Expanded(
              child: Text(
                categoryLabel(context, cur.cat),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(size: 15, color: AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final f in folders)
              SelectChip(
                label: f,
                active: cur.folder == f,
                onTap: () => store.setFolder(cur.id, f),
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
              color: hasCols ? AppColors.accent : AppColors.cardBorder,
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

void openSettingsSheet(BuildContext context) {
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.settingsTitle,
    const SettingsContent(),
  );
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

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
