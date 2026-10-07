import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'photo_shrink.dart';
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
  Widget content, {
  double maxHeightFactor = 0.85,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // Above the bottom tab bar, which lives outside the home navigator.
    useRootNavigator: true,
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
            maxHeight: MediaQuery.of(sheetContext).size.height * maxHeightFactor,
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

class _PickGrid extends StatefulWidget {
  final WardrobeZone zone;
  final BuildContext hostContext;
  const _PickGrid({required this.zone, required this.hostContext});

  @override
  State<_PickGrid> createState() => _PickGridState();
}

class _PickGridState extends State<_PickGrid> {
  String _query = '';

  WardrobeZone get zone => widget.zone;
  BuildContext get hostContext => widget.hostContext;

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
    final filtered = fullList
        .where((it) => store.folderFilter == null || it.folder == store.folderFilter)
        .where((it) => matchesSearch(it, _query, categoryLabel: categoryLabel(context, it.cat)))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SearchField(
            fillColor: AppColors.background,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
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

class _LayerChoices extends StatefulWidget {
  final int? replaceIndex;
  const _LayerChoices({this.replaceIndex});

  @override
  State<_LayerChoices> createState() => _LayerChoicesState();
}

class _LayerChoicesState extends State<_LayerChoices> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final replaceIndex = widget.replaceIndex;
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
    // The item currently worn as the main top is excluded outright — it
    // can't also be layered over itself (most visible with a sparse
    // wardrobe, where it'd otherwise be the only "layer" on offer).
    final currentTopId = store.at(store.topList, WardrobeZone.top)?.id;
    final available = store
        .byCat('horni')
        .where(
          (it) =>
              it.id != currentTopId &&
              (!store.layers.contains(it.id) ||
                  (replaceIndex != null && store.layers[replaceIndex] == it.id)),
        )
        .toList();
    if (available.isEmpty) {
      return Text(
        l10n.noMoreLayers,
        style: AppText.sans(size: 12, color: AppColors.mutedTag),
      );
    }
    final availableFolders = store.foldersFor('horni');
    final choices = available
        .where((it) => store.folderFilter == null || it.folder == store.folderFilter)
        .where((it) => matchesSearch(it, _query, categoryLabel: categoryLabel(context, it.cat)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SearchField(
            fillColor: AppColors.background,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
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
            _query.trim().isEmpty ? l10n.noMoreLayers : l10n.nothingFound,
            style: AppText.sans(size: 12, color: AppColors.mutedTag),
          ),
        for (final it in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: GestureDetector(
              onTap: () {
                if (replaceIndex != null) {
                  store.setLayer(replaceIndex, it.id);
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (it.name != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                it.name!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.sans(size: 13, color: AppColors.ink),
                              ),
                            ),
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
  /// first folder that exists for it, else [WardrobeStore.fallbackFolder] —
  /// a category with no folders yet must still be addable to (otherwise a
  /// brand-new wardrobe can never add its first item).
  String _defaultFolderFor(String cat) {
    final store = context.read<WardrobeStore>();
    final folders = store.foldersFor(cat);
    if (folders.contains(store.folderFilter)) return store.folderFilter!;
    return folders.isNotEmpty ? folders.first : store.fallbackFolder;
  }

  /// Longest edge a stored photo is scaled down to (aspect ratio kept). The
  /// biggest it's ever shown is the item detail, ~1200×660 px on the largest
  /// iPhone — full camera resolution (up to 8K) is just wasted storage.
  static const double _maxPhotoEdge = kMaxPhotoEdge * 1.0;

  Future<void> _pick(ImageSource source) async {
    if (_busy || _folder == null) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      // The gallery lets you select several photos at once — handy for
      // adding a handful of items of the same category/folder in one go.
      // The camera can only ever produce one photo per capture.
      final files = source == ImageSource.gallery
          ? await picker.pickMultiImage(
              maxWidth: _maxPhotoEdge,
              maxHeight: _maxPhotoEdge,
              imageQuality: 85,
            )
          : await picker
                .pickImage(
                  source: source,
                  maxWidth: _maxPhotoEdge,
                  maxHeight: _maxPhotoEdge,
                  imageQuality: 85,
                )
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
    // Photo + five detail fields + actions: needs more room than most sheets.
    maxHeightFactor: 0.92,
  );
}

class _ItemDetail extends StatefulWidget {
  final String itemId;
  const _ItemDetail({required this.itemId});

  @override
  State<_ItemDetail> createState() => _ItemDetailState();
}

class _ItemDetailState extends State<_ItemDetail> {
  late final TextEditingController _name;
  late final TextEditingController _seller;
  late final TextEditingController _size;
  late final TextEditingController _price;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final it = context.read<WardrobeStore>().itemById(widget.itemId);
    _name = TextEditingController(text: it?.name);
    _seller = TextEditingController(text: it?.seller);
    _size = TextEditingController(text: it?.size);
    _price = TextEditingController(text: it?.price);
    _note = TextEditingController(text: it?.note);
  }

  @override
  void dispose() {
    for (final c in [_name, _seller, _size, _price, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final itemId = widget.itemId;
    final cur = store.itemById(itemId);
    if (cur == null) return const SizedBox.shrink();
    // The sheet is opened from inside the item's own folder, so only the
    // *other* folders are offered — as move targets.
    final otherFolders = store.foldersFor(cur.cat).where((f) => f != cur.folder).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GarmentCard(
          width: double.infinity,
          height: 220,
          imagePath: cur.imagePath,
        ),
        const SizedBox(height: 8),
        Text(
          categoryLabel(context, cur.cat),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.sans(size: 15, color: AppColors.ink),
        ),
        const SizedBox(height: 14),
        if (otherFolders.isNotEmpty) ...[
          Text(l10n.moveToFolder, style: _sectionLabelStyle),
          const SizedBox(height: 5),
          // One scrollable row rather than a wrapping block — with many
          // folders a Wrap pushed the detail fields far down. Chips may
          // scroll out under the sheet's side padding, up to its edge.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final (i, f) in otherFolders.indexed) ...[
                  if (i > 0) const SizedBox(width: 7),
                  SelectChip(
                    label: f,
                    active: false,
                    onTap: () {
                      store.setFolder(cur.id, f);
                      // It just left the folder being viewed behind the sheet.
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _InfoField(
          label: l10n.sectionItemName,
          hint: l10n.itemNameHint,
          controller: _name,
          onChanged: (v) => store.setItemInfo(itemId, name: v),
        ),
        _InfoField(
          label: l10n.sectionSeller,
          hint: l10n.sellerHint,
          controller: _seller,
          onChanged: (v) => store.setItemInfo(itemId, seller: v),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoField(
                label: l10n.sectionSize,
                hint: l10n.sizeHint,
                controller: _size,
                onChanged: (v) => store.setItemInfo(itemId, size: v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoField(
                label: l10n.sectionPrice,
                hint: l10n.priceHint,
                controller: _price,
                onChanged: (v) => store.setItemInfo(itemId, price: v),
              ),
            ),
          ],
        ),
        _InfoField(
          label: l10n.sectionNote,
          hint: l10n.noteHint,
          controller: _note,
          multiline: true,
          onChanged: (v) => store.setItemInfo(itemId, note: v),
        ),
        const SizedBox(height: 4),
        // Equal-width side actions with a wider "Done" between them.
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _DetailAction(
                label: l10n.useInOutfit,
                filled: true,
                textColor: Colors.white,
                onTap: () {
                  // A top can go in several places — ask where.
                  if (cur.cat == 'horni') {
                    _showSheet(
                      context,
                      (ctx) => AppLocalizations.of(ctx)!.wearWhereTitle,
                      _WearTopChoices(item: cur),
                    );
                    return;
                  }
                  store.useItem(cur);
                  _backToOutfit(context);
                },
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 3,
              child: _DetailAction(
                label: l10n.done,
                textColor: AppColors.ink,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 2,
              child: _DetailAction(
                label: l10n.delete,
                textColor: AppColors.muted,
                bold: false,
                onTap: () => _confirmDeleteItem(context, store, cur),
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
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () async {
            final result = await store.saveOutfit(
              rawName: _nameController.text,
              targetCol: _selectedCol ?? '',
              defaultName: l10n.defaultOutfitName,
            );
            store.flash(l10n.toastOutfitSaved(result.name, result.col));
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.save,
              style: AppText.sans(
                size: 13,
                weight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Back to the home screen (on the outfit tab), not just out of the sheet —
/// the item sheet is usually opened from a folder screen pushed on top.
void _backToOutfit(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  popToHomeTabs();
}

/// Where in the outfit a top should go: the top itself, one of the current
/// layers (replacing it), or a new layer — each shown with what's there now.
class _WearTopChoices extends StatelessWidget {
  final ClothingItem item;
  const _WearTopChoices({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final top = store.at(store.topList, WardrobeZone.top);
    final isWorn = top?.id == item.id || store.layers.contains(item.id);

    Widget row({required String label, required ClothingItem? occupant, required VoidCallback onTap, bool isNew = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: GestureDetector(
          onTap: () {
            onTap();
            _backToOutfit(context);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.rowBorder),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isNew ? null : AppColors.cardFill,
                    border: Border.all(color: isNew ? AppColors.dashedBorder : AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: isNew
                      ? Text('+', style: AppText.sans(size: 20, weight: FontWeight.w300, color: AppColors.mutedSoft))
                      : occupant?.imagePath == null
                      ? const DiagonalStripes()
                      : GarmentImage(occupant!.imagePath!),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppText.sans(size: 14, color: AppColors.ink))),
                if (occupant?.id == item.id)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      l10n.wornHere,
                      style: AppText.mono(size: 8.5, letterSpacing: 0.4, color: AppColors.mutedTag),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(label: l10n.wearAsTop, occupant: top, onTap: () => store.useItem(item)),
        for (var i = 0; i < store.layers.length; i++)
          row(
            label: l10n.wearAsLayer(i + 1),
            occupant: store.itemById(store.layers[i]),
            onTap: () => store.wearAsLayer(item, i),
          ),
        if (!isWorn && store.layers.length < WardrobeStore.kMaxLayers)
          row(
            label: l10n.wearAsNewLayer,
            occupant: null,
            isNew: true,
            onTap: () => store.wearAsLayer(item, store.layers.length),
          ),
      ],
    );
  }
}

/// A pill button in the item detail's action row — filled accent, or
/// outlined. A label too long for its share of the row wraps onto a second
/// line rather than shrinking (scaling "Použít v outfitu" down to fit got
/// it to ~10pt on a typical iPhone).
class _DetailAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final bool filled;
  final bool bold;

  const _DetailAction({
    required this.label,
    required this.onTap,
    required this.textColor,
    this.filled = false,
    this.bold = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : null,
          borderRadius: BorderRadius.circular(23),
          border: filled ? null : Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppText.sans(
            size: 13,
            height: 1.15,
            weight: bold ? FontWeight.w500 : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// One optional, labelled free-text detail of a clothing item — same look
/// as the outfit-name field in the save sheet.
class _InfoField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool multiline;

  const _InfoField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _sectionLabelStyle),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            onChanged: onChanged,
            // Text fields share one tap region, so moving between fields
            // keeps the keyboard up; anywhere else hides it.
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            textCapitalization: TextCapitalization.sentences,
            minLines: multiline ? 2 : 1,
            maxLines: multiline ? 5 : 1,
            keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.sans(size: 14, color: AppColors.mutedTag),
              filled: true,
              fillColor: AppColors.background,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: border,
              enabledBorder: border,
            ),
            style: AppText.sans(size: 14, color: AppColors.ink),
          ),
        ],
      ),
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

void openManageWardrobesSheet(BuildContext context) {
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.editWardrobes,
    const _ManageWardrobes(),
  );
}

/// Rename/delete any wardrobe (not just the active one) and add new ones.
class _ManageWardrobes extends StatelessWidget {
  const _ManageWardrobes();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final canDelete = store.wardrobes.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in store.wardrobes)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.rowBorder),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 14,
                        weight: w.id == store.activeWardrobeId ? FontWeight.w500 : FontWeight.w400,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _rename(context, store, w),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.mutedSoft),
                  ),
                  if (canDelete)
                    IconButton(
                      onPressed: () => _delete(context, store, w),
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.accent),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        SizedBox(
          height: 64,
          child: AddTile(label: l10n.newWardrobeTile, onTap: () => _add(context, store)),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context, WardrobeStore store, Wardrobe w) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.renameWardrobeTitle,
      initialValue: w.name,
      confirmLabel: l10n.save,
    );
    if (name != null) await store.renameWardrobe(w.id, name);
  }

  Future<void> _delete(BuildContext context, WardrobeStore store, Wardrobe w) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDialog(
      context,
      title: l10n.deleteWardrobeTitle,
      message: l10n.deleteWardrobeMessage(w.name),
      confirmLabel: l10n.delete,
    );
    if (confirmed) await store.deleteWardrobe(w.id);
  }

  Future<void> _add(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.newWardrobe,
      initialValue: '',
      hintText: l10n.newWardrobeHint,
      confirmLabel: l10n.create,
    );
    if (name != null) await store.addWardrobe(name);
  }
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
