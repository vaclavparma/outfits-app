import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// [title] is resolved inside the sheet's own builder (via [sheetContext]),
/// not by the caller, so it stays correct if the locale changes while the
/// sheet is open (e.g. switching language from the settings sheet itself).
/// Besides swiping down / tapping outside, every sheet has a close button
/// next to its title — the gestures alone weren't obvious enough, e.g. with
/// one sheet stacked on top of another.
Future<T?> _showSheet<T>(
  BuildContext context,
  // Null leaves the header out — the content then has its own close
  // button.
  String Function(BuildContext)? title,
  Widget content, {
  double maxHeightFactor = 0.85,
  ValueChanged<int>? onSwipe,
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
          child: _SheetSwipe(
            onSwipe: onSwipe,
            child: Container(
            // Full width even when the content is narrow (a few chips, a
            // one-line message) — otherwise the sheet shrinks to fit it.
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
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
                  if (title != null) ...[
                    Row(
                      children: [
                        Expanded(child: Text(title(sheetContext), style: _sheetTitleStyle)),
                        const SizedBox(width: 8),
                        const _SheetCloseButton(),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  content,
                ],
              ),
            ),
          ),
          ),
        ),
      );
    },
  );
}

/// Turns a quick sideways flick anywhere on a sheet — header, photo, text
/// fields, buttons — into [onSwipe] with the finger's direction: +1 for a
/// flick to the right, -1 to the left.
///
/// Reads raw pointer events instead of entering the gesture arena: text
/// fields claim horizontal drags for themselves (scrolling, and on Android
/// drag-selection), so a regular drag recognizer only ever won over the
/// photo. A flick must be fast (a long-press cursor drag isn't) and mostly
/// sideways (scrolling the sheet isn't).
class _SheetSwipe extends StatefulWidget {
  final ValueChanged<int>? onSwipe;
  final Widget child;
  const _SheetSwipe({required this.onSwipe, required this.child});

  @override
  State<_SheetSwipe> createState() => _SheetSwipeState();
}

class _SheetSwipeState extends State<_SheetSwipe> {
  static const _minDistance = 35.0;
  static const _maxDuration = Duration(milliseconds: 600);

  int _pointers = 0;
  Offset? _start;
  Duration? _startTime;

  @override
  Widget build(BuildContext context) {
    final onSwipe = widget.onSwipe;
    if (onSwipe == null) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _pointers++;
        // A second finger means a pinch or similar, not a swipe.
        _start = _pointers == 1 ? e.position : null;
        _startTime = e.timeStamp;
      },
      onPointerCancel: (_) {
        _pointers = (_pointers - 1).clamp(0, 10);
        _start = null;
      },
      onPointerUp: (e) {
        _pointers = (_pointers - 1).clamp(0, 10);
        final start = _start, startTime = _startTime;
        _start = null;
        if (start == null || startTime == null) return;
        final d = e.position - start;
        if (e.timeStamp - startTime <= _maxDuration &&
            d.dx.abs() >= _minDistance &&
            d.dx.abs() > d.dy.abs() * 1.5) {
          onSwipe(d.dx > 0 ? 1 : -1);
        }
      },
      child: widget.child,
    );
  }
}

/// The "×" in a sheet header. Opaque 40×40 target, pulled right so the
/// glyph lines up with the content's right edge.
class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(10, 0),
      child: Semantics(
        button: true,
        label: AppLocalizations.of(context)!.close,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.close, size: 22, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}

TextStyle get _sheetTitleStyle => AppText.sans(
  size: 20,
  weight: FontWeight.w300,
  color: AppColors.ink,
  letterSpacing: -0.2,
);

/// Small uppercase-mono label above a form field/section within a sheet
/// (e.g. "kategorie", "tagy", "kolekce").
TextStyle get _sectionLabelStyle => AppText.mono(
  size: 9.5,
  letterSpacing: 1.3,
  color: AppColors.mutedSoft,
);

/// Picks what a canvas card shows: any item of its kind, filtered by type
/// and search, or a new one added right here.
void openPickSheet(BuildContext context, String slotId) {
  final kindId = context.read<WardrobeStore>().slotById(slotId)?.kindId;
  if (kindId == null) return;
  _showSheet(
    context,
    (ctx) => ctx.read<WardrobeStore>().kindName(kindId),
    _PickGrid(slotId: slotId, hostContext: context),
  );
}

class _PickGrid extends StatefulWidget {
  final String slotId;
  final BuildContext hostContext;
  const _PickGrid({required this.slotId, required this.hostContext});

  @override
  State<_PickGrid> createState() => _PickGridState();
}

class _PickGridState extends State<_PickGrid> {
  String _query = '';
  String? _tab;

  void _addNew(BuildContext context, String kindId) {
    Navigator.of(context).pop();
    final host = widget.hostContext;
    openAddItemSheet(
      host,
      presetKind: kindId,
      presetType: _tab,
      onAdded: (item) => host.read<WardrobeStore>().setSlotItem(widget.slotId, item.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final slot = store.slotById(widget.slotId);
    if (slot == null) return const SizedBox.shrink();
    final kind = store.kindById(slot.kindId);
    final all = store.itemsOfKind(slot.kindId);
    final current = store.itemInSlot(slot.id);
    final tabs = typeTabsFor(kind, all, l10n);
    if (!tabs.any((t) => t.key == _tab)) _tab = null;
    final filtered = all
        .where((it) => inTypeTab(it, _tab))
        .where((it) => textsMatchSearch(store.searchTexts(it), _query))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SearchField(
              fillColor: AppColors.background,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        if (tabs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TypeTabs(tabs: tabs, selected: _tab, onSelect: (k) => setState(() => _tab = k)),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length + 1,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns(context, 3),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 100 / 124,
          ),
          itemBuilder: (context, i) {
            if (i == filtered.length) {
              return AddTile(label: l10n.add, onTap: () => _addNew(context, slot.kindId));
            }
            final it = filtered[i];
            return GarmentCard(
              width: double.infinity,
              height: double.infinity,
              imagePath: it.imagePath,
              borderColor: current?.id == it.id ? AppColors.ink : AppColors.cardBorder,
              onTap: () {
                store.setSlotItem(slot.id, it.id);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ],
    );
  }
}

/// [presetKind] and [presetType] preselect where the new clothing goes
/// (e.g. the wardrobe section or canvas card it was added from); both can
/// still be changed in the form.
void openAddItemSheet(
  BuildContext context, {
  String? presetKind,
  String? presetType,
  void Function(ClothingItem item)? onAdded,
}) {
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.addItemTitle,
    _AddItemForm(
      presetKind: presetKind,
      presetType: presetType,
      onAdded: onAdded,
    ),
  );
}

class _AddItemForm extends StatefulWidget {
  final String? presetKind;
  final String? presetType;
  final void Function(ClothingItem item)? onAdded;

  const _AddItemForm({this.presetKind, this.presetType, this.onAdded});

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  String? _kind;
  String? _type;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<WardrobeStore>();
    final kind = store.kindById(widget.presetKind ?? '') ?? store.kinds.firstOrNull;
    _kind = kind?.id;
    _type = (kind?.typeById(widget.presetType) ?? kind?.types.firstOrNull)?.id;
  }

  Future<void> _newType(WardrobeStore store, String kindId) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.newTypeTitle,
      initialValue: '',
      hintText: l10n.newTypeHint,
      confirmLabel: l10n.create,
      isTaken: (n) => store.typeNameTaken(kindId, n),
    );
    if (name == null) return;
    final type = store.addType(kindId, name);
    if (type != null && mounted) setState(() => _type = type.id);
  }

  /// Longest edge a stored photo is scaled down to (aspect ratio kept). The
  /// biggest it's ever shown is the item detail, ~1200×660 px on the largest
  /// iPhone — full camera resolution (up to 8K) is just wasted storage.
  static const double _maxPhotoEdge = 1600;

  Future<void> _pick(ImageSource source) async {
    final kind = _kind, type = _type;
    if (_busy || kind == null || type == null) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      // The gallery lets you select several photos at once — handy for
      // adding a handful of items of the same kind and type in one go.
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
      final label = store.kindName(kind);
      final result = await store.addItems(
        kind,
        type,
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
    final kind = store.kindById(_kind ?? '');
    final kinds = store.kinds;
    final canAdd = kind != null && kind.typeById(_type) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sectionKind, style: _sectionLabelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final k in kinds)
              SelectChip(
                label: k.name,
                active: _kind == k.id,
                mono: false,
                height: 34,
                // A type belongs to one kind, so switching kind starts
                // on that kind's first type.
                onTap: () => setState(() {
                  _kind = k.id;
                  _type = k.types.firstOrNull?.id;
                }),
              ),
          ],
        ),
        if (kind != null) ...[
          const SizedBox(height: 18),
          Text(l10n.sectionType, style: _sectionLabelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final t in kind.types)
                SelectChip(label: t.name, active: _type == t.id, onTap: () => setState(() => _type = t.id)),
              SelectChip(label: '+ ${l10n.addTypeChip}', active: false, onTap: () => _newType(store, kind.id)),
            ],
          ),
        ],
        const SizedBox(height: 18),
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

/// Opens an item's detail, full screen above the tab bar. [browseIds] are
/// the items shown alongside [item] where it was opened from (a type, search
/// results, stats), in that order — swiping sideways steps through them.
void openItemDetail(BuildContext context, ClothingItem item, {List<String>? browseIds}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => _ItemPage(initialId: item.id, ids: browseIds ?? [item.id])),
  );
}

/// The detail page: the item's type as the title, its detail (swipe
/// anywhere for the next/previous one), and the actions pinned below.
class _ItemPage extends StatefulWidget {
  final String initialId;
  final List<String> ids;
  const _ItemPage({required this.initialId, required this.ids});

  @override
  State<_ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<_ItemPage> {
  late String _currentId = widget.initialId;

  /// Which way the content slides: the finger's direction (+1 right).
  int _slide = 1;

  /// Items can't be added while browsing, but one could be deleted or moved.
  List<String> _liveIds(WardrobeStore store) => widget.ids.where((id) => store.itemById(id) != null).toList();

  /// A flick with the finger moving left (-1) goes to the next item, right
  /// (+1) to the previous one — like flipping pages or photos. The content
  /// slides along with the finger. Stops at either end.
  void _swipe(int finger) {
    final ids = _liveIds(context.read<WardrobeStore>());
    final index = ids.indexOf(_currentId);
    final next = index - finger;
    if (index < 0 || next < 0 || next >= ids.length) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      _slide = finger;
      _currentId = ids[next];
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final cur = store.itemById(_currentId);
    if (cur == null) {
      // Deleted or moved away — nothing left to show. (Usually whatever did
      // it closes this page itself; only if not, close it here.)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) Navigator.of(context).pop();
      });
      return Scaffold(backgroundColor: AppColors.background);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
                child: Row(
                  children: [
                    const AppBackButton(),
                    Expanded(
                      child: Text(
                        store.typeName(cur) ?? store.kindName(cur.cat),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(size: 16, weight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _SheetSwipe(
                  onSwipe: _swipe,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, ?current],
                      ),
                      // Content moves with the finger: the old item leaves the
                      // way the finger went, the new one follows in from the
                      // opposite side. With Reduce Motion it only cross-fades.
                      transitionBuilder: (child, animation) {
                        final incoming = child.key == ValueKey(_currentId);
                        final dx = reduceMotion ? 0.0 : (incoming ? -_slide : _slide) * 0.25;
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _ItemDetail(key: ValueKey(_currentId), itemId: _currentId),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
                child: Row(
                  children: [
                    Expanded(
                      child: _DetailAction(
                        label: l10n.done,
                        filled: true,
                        textColor: Colors.white,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 9),
                    _DetailIconAction(
                      icon: Icons.drive_file_move_outline,
                      label: l10n.moveTitle,
                      onTap: () => _showSheet(
                        context,
                        (ctx) => AppLocalizations.of(ctx)!.moveTitle,
                        _MoveItem(itemId: cur.id),
                      ),
                    ),
                    const SizedBox(width: 9),
                    _DetailIconAction(
                      icon: Icons.delete_outline,
                      label: l10n.delete,
                      onTap: () => _confirmDeleteItem(context, store, cur),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One item: photo, name (its own, or made up from color and type), kind
/// and type with its colors, wear stats, and the optional details.
class _ItemDetail extends StatefulWidget {
  final String itemId;

  const _ItemDetail({super.key, required this.itemId});

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
    // The title follows the name as it's typed, not once saving catches up.
    _name.addListener(() => setState(() {}));
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
    final typed = _name.text.trim();
    final autoName = store.displayName(ClothingItem(id: cur.id, cat: cur.cat, typeId: cur.typeId, colors: cur.colors));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A short hold opens the photo full screen, as on the outfit tab.
        GarmentCard(
          width: double.infinity,
          height: 320,
          imagePath: cur.imagePath,
          zoomable: true,
        ),
        const SizedBox(height: 18),
        Text(
          typed.isEmpty ? autoName : typed,
          style: AppText.sans(
            size: 28,
            weight: FontWeight.w300,
            // A made-up name stays a little in the background.
            color: typed.isEmpty ? AppColors.label : AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        if (typed.isEmpty) ...[
          const SizedBox(height: 3),
          Text(l10n.itemAutoNameHint, style: AppText.mono(size: 9.5, letterSpacing: 0.3, color: AppColors.mutedTag)),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                [store.kindName(cur.cat), ?store.typeName(cur)].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(size: 15, color: AppColors.muted),
              ),
            ),
            // Colors detected from the photo; tap to correct them. Hidden
            // until detection (a background pass after startup) has run,
            // rather than flashing an empty bar.
            if (cur.imagePath != null && cur.colors != null)
              Semantics(
                button: true,
                label: l10n.colorsEdit,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openColorEditor(context, cur.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: ColorBar(colors: cur.colors!),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _ItemWearStats(item: cur),
        const SizedBox(height: 22),
        Text(l10n.sectionDetails.toUpperCase(), style: _sectionLabelStyle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.rowBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _InfoRow(
                label: l10n.sectionItemName,
                // The made-up name, as a suggestion to type over.
                hint: autoName,
                controller: _name,
                onChanged: (v) => store.setItemInfo(itemId, name: v),
              ),
              _InfoRow(
                label: l10n.sectionSeller,
                hint: l10n.sellerHint,
                controller: _seller,
                onChanged: (v) => store.setItemInfo(itemId, seller: v),
              ),
              _InfoRow(
                label: l10n.sectionSize,
                hint: l10n.sizeHint,
                controller: _size,
                onChanged: (v) => store.setItemInfo(itemId, size: v),
              ),
              _InfoRow(
                label: l10n.sectionPrice,
                hint: l10n.priceHint,
                controller: _price,
                onChanged: (v) => store.setItemInfo(itemId, price: v),
              ),
              _InfoRow(
                label: l10n.sectionNote,
                hint: l10n.noteHint,
                controller: _note,
                multiline: true,
                last: true,
                onChanged: (v) => store.setItemInfo(itemId, note: v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// How much an item gets worn, from the diary: times worn, when last, the
/// price per wear (if a price is filled in), and this month day by day.
class _ItemWearStats extends StatelessWidget {
  final ClothingItem item;
  const _ItemWearStats({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final stats = store.wearStats[item.id];
    final count = stats?.count ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = stats?.last;
    final ago = last == null ? null : daysBetween(last, today);
    final perWear = count == 0 ? null : pricePerWear(item.price, count, locale);
    final worn = store.daysWornIn(item.id, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _WearTile(value: l10n.timesWorn(count), label: l10n.itemWornLabel)),
            const SizedBox(width: 8),
            Expanded(
              child: _WearTile(
                value: switch (ago) {
                  null => l10n.statsNever,
                  0 => l10n.itemLastToday,
                  1 => l10n.itemLastYesterday,
                  final n => l10n.statsDaysAgo(n),
                },
                label: l10n.itemLastWornLabel,
                small: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _WearTile(value: perWear ?? '–', label: l10n.itemPerWearLabel)),
          ],
        ),
        const SizedBox(height: 14),
        Text(DateFormat.LLLL(locale).format(now).toUpperCase(), style: _sectionLabelStyle),
        const SizedBox(height: 6),
        _MonthStrip(worn: worn),
      ],
    );
  }
}

/// The current month, a square per day: days in [worn] (day numbers)
/// filled, the rest of the month still to come dimmed.
class _MonthStrip extends StatelessWidget {
  final Set<int> worn;
  const _MonthStrip({required this.worn});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    return Row(
      children: [
        for (var d = 1; d <= days; d++)
          Expanded(
            child: Container(
              height: 14,
              margin: EdgeInsets.only(left: d == 1 ? 0 : 2.5),
              decoration: BoxDecoration(
                color: worn.contains(d)
                    ? AppColors.accentText
                    : d > now.day
                    ? AppColors.cardFill.withValues(alpha: 0.5)
                    : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

/// [price] (as typed: "499 Kč", "$29", "1 290,50 €") divided by [wears], in
/// the same notation; `null` if it has no number in it.
String? pricePerWear(String? price, int wears, String locale) {
  if (price == null || wears <= 0) return null;
  final match = RegExp(r'\d[\d\s\u00a0.,]*').firstMatch(price);
  if (match == null) return null;
  final digits = match.group(0)!.replaceAll(RegExp(r'[\s\u00a0]'), '').replaceAll(RegExp(r'[.,]$'), '');
  // The last separator followed by one or two digits is the decimal one;
  // any other separators group thousands.
  final dec = RegExp(r'[.,](\d{1,2})$').firstMatch(digits);
  final sep = dec == null ? null : digits[dec.start];
  final whole = (dec == null ? digits : digits.substring(0, dec.start)).replaceAll(RegExp(r'[.,]'), '');
  final value = double.tryParse(dec == null ? whole : '$whole.${dec.group(1)}');
  if (value == null) return null;
  final each = value / wears;
  final decimalSep = sep ?? (locale.startsWith('cs') ? ',' : '.');
  final shown = each >= 10 || each == each.roundToDouble()
      ? each.round().toString()
      : each.toStringAsFixed(1).replaceAll('.', decimalSep);
  return price.replaceRange(match.start, match.start + match.group(0)!.trimRight().length, shown);
}

class _WearTile extends StatelessWidget {
  final String value;
  final String label;

  /// For a longer value ("před 12 dny") rather than a figure.
  final bool small;

  const _WearTile({required this.value, required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      // At least this tall; more with large text.
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.rowBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.sans(size: small ? 16 : 24, weight: FontWeight.w300, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.mono(size: 9, letterSpacing: 0.3, color: AppColors.mutedTag)),
        ],
      ),
    );
  }
}

void _openColorEditor(BuildContext context, String itemId) {
  _showSheet(
    context,
    (ctx) => AppLocalizations.of(ctx)!.colorsTitle,
    _ColorEditor(itemId: itemId),
    maxHeightFactor: 0.92,
  );
}

/// Corrects an item's colors by picking them from its photo: choose a slot
/// (1–3) below the photo, then tap the spot on the photo to take its color.
/// Every change is saved right away, like the item's other details.
class _ColorEditor extends StatefulWidget {
  final String itemId;
  const _ColorEditor({required this.itemId});

  @override
  State<_ColorEditor> createState() => _ColorEditorState();
}

class _ColorEditorState extends State<_ColorEditor> {
  static const _photoHeight = 300.0;

  /// Decoded at a modest size — enough to pick from, cheap to hold.
  static const _sampleSide = 600;

  int _selected = 0;
  ({ByteData pixels, int width, int height})? _sample;
  Offset? _marker;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final path = context.read<WardrobeStore>().itemById(widget.itemId)?.imagePath;
    if (path == null) return;
    try {
      final bytes = await File(path).readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final landscape = descriptor.width >= descriptor.height;
      final codec = await descriptor.instantiateCodec(
        targetWidth: landscape ? _sampleSide : null,
        targetHeight: landscape ? null : _sampleSide,
      );
      final image = (await codec.getNextFrame()).image;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = image.width, h = image.height;
      image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      if (pixels != null && mounted) setState(() => _sample = (pixels: pixels, width: w, height: h));
    } catch (_) {
      // Unreadable photo: nothing to pick from; the rest still works.
    }
  }

  /// Average of a small square around the pixel, so fabric texture and
  /// JPEG noise don't decide the color.
  int _colorAt(int px, int py) {
    final s = _sample!;
    var r = 0, g = 0, b = 0, n = 0;
    for (var y = math.max(0, py - 2); y <= math.min(s.height - 1, py + 2); y++) {
      for (var x = math.max(0, px - 2); x <= math.min(s.width - 1, px + 2); x++) {
        final o = (y * s.width + x) * 4;
        r += s.pixels.getUint8(o);
        g += s.pixels.getUint8(o + 1);
        b += s.pixels.getUint8(o + 2);
        n++;
      }
    }
    return 0xFF000000 | (r ~/ n) << 16 | (g ~/ n) << 8 | (b ~/ n);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final item = store.itemById(widget.itemId);
    if (item == null || item.imagePath == null) return const SizedBox.shrink();
    final colors = item.colors ?? const <int>[];
    final selected = colors.isEmpty ? 0 : _selected.clamp(0, colors.length - 1);

    void setSlot(int color) {
      final next = [...colors];
      if (next.isEmpty) {
        next.add(color);
      } else {
        next[selected] = color;
      }
      store.setItemColors(item.id, next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.colorsHint, style: AppText.sans(size: 12.5, color: AppColors.mutedTag, height: 1.4)),
        const SizedBox(height: 12),
        SizedBox(
          height: _photoHeight,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, box) {
              final sample = _sample;
              // Where the photo actually sits inside the box (BoxFit.contain).
              Rect? photoRect;
              if (sample != null) {
                final scale = math.min(box.maxWidth / sample.width, box.maxHeight / sample.height);
                final w = sample.width * scale, h = sample.height * scale;
                photoRect = Rect.fromLTWH((box.maxWidth - w) / 2, (box.maxHeight - h) / 2, w, h);
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  onTapDown: (d) {
                    final r = photoRect;
                    if (r == null || !r.contains(d.localPosition)) return;
                    final px = ((d.localPosition.dx - r.left) / r.width * sample!.width).floor();
                    final py = ((d.localPosition.dy - r.top) / r.height * sample.height).floor();
                    HapticFeedback.selectionClick();
                    setState(() => _marker = d.localPosition);
                    setSlot(_colorAt(px, py));
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.white,
                          child: Image.file(File(item.imagePath!), fit: BoxFit.contain),
                        ),
                      ),
                      if (_marker case final m? when colors.isNotEmpty)
                        Positioned(
                          left: m.dx - 14,
                          top: m.dy - 14,
                          child: IgnorePointer(
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Color(colors[selected]),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final (i, c) in colors.indexed) ...[
              Semantics(
                button: true,
                selected: i == selected,
                label: l10n.colorSlot(i + 1),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selected = i;
                    _marker = null;
                  }),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(c),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: i == selected ? AppColors.accent : AppColors.cardBorder,
                        width: i == selected ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            if (colors.length < 3)
              Semantics(
                button: true,
                label: l10n.colorAdd,
                child: GestureDetector(
                  onTap: () {
                    // A new slot starts as a copy of the selected color; a tap
                    // on the photo then sets it.
                    final next = [...colors, colors.isEmpty ? 0xFFBDBDBD : colors[selected]];
                    store.setItemColors(item.id, next);
                    setState(() {
                      _selected = next.length - 1;
                      _marker = null;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dashedBorder),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.add, size: 20, color: AppColors.mutedSoft),
                  ),
                ),
              ),
            const Spacer(),
            if (colors.length > 1)
              IconButton(
                tooltip: l10n.colorRemove,
                onPressed: () {
                  store.setItemColors(item.id, [...colors]..removeAt(selected));
                  setState(() {
                    _selected = math.max(0, selected - 1);
                    _marker = null;
                  });
                },
                icon: Icon(Icons.delete_outline, size: 20, color: AppColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _selected = 0;
              _marker = null;
            });
            store.redetectColors(item.id);
          },
          icon: Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.accentText),
          label: Text(l10n.colorsRedetect, style: AppText.sans(size: 13, color: AppColors.accentText)),
        ),
      ],
    );
  }
}

/// Saves what's on the canvas — after a confirmation if exactly these
/// clothes are already saved (here or in another wardrobe).
Future<void> saveCurrentOutfit(BuildContext context) async {
  final store = context.read<WardrobeStore>();
  final l10n = AppLocalizations.of(context)!;
  if (store.currentOutfitItems.isEmpty) {
    store.flash(l10n.diaryCanvasEmpty);
    return;
  }
  final existing = store.findSavedCopyOfCurrentOutfit();
  if (existing != null) {
    final saveAnyway = await confirmDialog(
      context,
      title: l10n.outfitAlreadySavedTitle,
      message: existing.here ? l10n.outfitAlreadySavedHere : l10n.outfitAlreadySavedIn(existing.wardrobe),
      confirmLabel: l10n.saveAnyway,
    );
    if (!saveAnyway) return;
  }
  if (await store.saveOutfit()) store.flash(l10n.toastOutfitSavedPlain);
}

/// Closes the sheets so the outfit tab (which the store just switched to)
/// shows.
void _backToOutfit(BuildContext context) =>
    Navigator.of(context).popUntil((route) => route.isFirst);

/// Where an item can be moved: another type, another kind (and a type
/// there), or another wardrobe. Picking a type moves it right away and
/// returns to its detail; another wardrobe takes it out of this one, so
/// the detail closes too.
class _MoveItem extends StatefulWidget {
  final String itemId;
  const _MoveItem({required this.itemId});

  @override
  State<_MoveItem> createState() => _MoveItemState();
}

class _MoveItemState extends State<_MoveItem> {
  /// The kind whose types are on offer — the item's own until another is
  /// picked.
  String? _kind;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final cur = store.itemById(widget.itemId);
    if (cur == null) return const SizedBox.shrink();
    final kind = store.kindById(_kind ?? cur.cat) ?? store.kindById(cur.cat);
    final kinds = store.kinds;
    final otherWardrobes = store.wardrobes.where((w) => w.id != store.activeWardrobeId).toList();
    bool isCurrent(String typeId) => kind?.id == cur.cat && cur.typeId == typeId;

    void moveTo(String typeId) {
      if (kind == null || isCurrent(typeId)) return;
      store.moveItem(cur.id, kind.id, typeId);
      Navigator.of(context).pop();
    }

    Widget section(String label, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _sectionLabelStyle),
          const SizedBox(height: 8),
          Wrap(spacing: 7, runSpacing: 7, children: chips),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section(l10n.sectionKind, [
          for (final k in kinds)
            SelectChip(
              label: k.name,
              active: k.id == kind?.id,
              mono: false,
              height: 34,
              onTap: () => setState(() => _kind = k.id),
            ),
        ]),
        if (kind != null)
          section(l10n.sectionType, [
            for (final t in kind.types) SelectChip(label: t.name, active: isCurrent(t.id), onTap: () => moveTo(t.id)),
          ]),
        if (otherWardrobes.isNotEmpty)
          section(l10n.sectionWardrobe, [
            for (final w in otherWardrobes)
              SelectChip(
                label: w.name,
                active: false,
                mono: false,
                height: 34,
                onTap: () {
                  store.moveItemToWardrobe(cur.id, w.id);
                  store.flash(l10n.toastMovedToWardrobe(w.name));
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
              ),
          ]),
      ],
    );
  }
}

/// Round outlined icon-only button in the item detail's action row, the
/// same height as the pill buttons next to it.
class _DetailIconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DetailIconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: AppColors.muted),
        ),
      ),
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

  const _DetailAction({
    required this.label,
    required this.onTap,
    required this.textColor,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Grows for a label that wraps with large text.
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            weight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// One optional detail of a clothing item, as a row of the details card:
/// a small label on the left, the text field filling the rest.
class _InfoRow extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool multiline;
  final bool last;

  const _InfoRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.multiline = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: AppColors.rowBorder)),
      ),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: multiline ? 18 : 0),
            child: SizedBox(
              width: 86,
              child: Text(label, style: AppText.mono(size: 9.5, letterSpacing: 0.4, color: AppColors.mutedTag)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              // Text fields share one tap region, so moving between fields
              // keeps the keyboard up; anywhere else hides it.
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: multiline ? 5 : 1,
              // A one-line field would otherwise claim every sideways drag to
              // scroll its text — swallowing the swipe to the next item. It
              // still scrolls itself to the caret while typing.
              scrollPhysics: multiline ? null : const NeverScrollableScrollPhysics(),
              keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppText.sans(size: 15, color: AppColors.mutedTag),
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              style: AppText.sans(size: 15, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deletes [type] of [kind]: an empty type just goes; one with clothes
/// (in any wardrobe) first asks which of the kind's other types they move
/// to. A kind's last type can't be deleted.
Future<void> deleteTypeAskingWhereTo(BuildContext context, ClothingKind kind, ClothingType type) async {
  final store = context.read<WardrobeStore>();
  if (kind.types.length < 2) return;
  final count = store.typeItemCount(kind.id, type.id);
  if (count == 0) {
    store.deleteType(kind.id, type.id);
    return;
  }
  final target = await showDialog<String>(
    context: context,
    builder: (_) => _MoveTypeItemsDialog(kind: kind, type: type, count: count),
  );
  if (target != null) store.deleteType(kind.id, type.id, moveTo: target);
}

/// Deleting a type that has clothes: pick which of the kind's other types
/// they move to.
class _MoveTypeItemsDialog extends StatefulWidget {
  final ClothingKind kind;
  final ClothingType type;
  final int count;
  const _MoveTypeItemsDialog({required this.kind, required this.type, required this.count});

  @override
  State<_MoveTypeItemsDialog> createState() => _MoveTypeItemsDialogState();
}

class _MoveTypeItemsDialogState extends State<_MoveTypeItemsDialog> {
  late final _others = widget.kind.types.where((t) => t.id != widget.type.id).toList();
  late String _target = _others.first.id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.deleteTypeTitle, style: AppText.sans(size: 16, color: AppColors.ink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deleteTypeMoveMessage(widget.type.name, l10n.itemCount(widget.count)),
            style: AppText.sans(size: 13, color: AppColors.label, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final t in _others)
                SelectChip(
                  label: t.name,
                  active: t.id == _target,
                  mono: false,
                  height: 34,
                  onTap: () => setState(() => _target = t.id),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: AppText.sans(size: 13, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_target),
          child: Text(
            l10n.delete,
            style: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.accentText),
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
  if (!confirmed || !context.mounted) return;
  // Close the detail first: once the item is gone, the page would close
  // itself too — and a second pop after that would close the home screen.
  Navigator.of(context).pop();
  await store.deleteItem(item);
}

class SettingsContent extends StatelessWidget {
  /// The settings screen sets its section headings in capitals.
  final bool uppercaseLabels;
  const SettingsContent({super.key, this.uppercaseLabels = false});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionLabel(l10n.sectionAppearance, uppercase: uppercaseLabels),
        const SizedBox(height: 8),
        SettingsCard(
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final (code, label) in [
                (null, l10n.languageSystemOption),
                ('light', l10n.themeLight),
                ('dark', l10n.themeDark),
              ])
                SelectChip(
                  label: label,
                  active: store.themeModeCode == code,
                  mono: false,
                  height: 34,
                  onTap: () => store.setThemeMode(code),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SettingsSectionLabel(l10n.sectionLanguage, uppercase: uppercaseLabels),
        const SizedBox(height: 8),
        SettingsCard(
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
      ],
    );
  }
}

/// Shared card chrome for a settings section — the pickers, the on/off
/// rows, the wardrobe list and the app card all read as one family.
class SettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SettingsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.rowBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// A settings section's small mono heading ("vzhled", "jazyk"…).
class SettingsSectionLabel extends StatelessWidget {
  final String text;
  final bool uppercase;
  const SettingsSectionLabel(this.text, {super.key, this.uppercase = false});

  @override
  Widget build(BuildContext context) =>
      Text(uppercase ? text.toUpperCase() : text, style: _sectionLabelStyle);
}

/// One day of the diary: the outfits written down for it, and buttons to
/// add the one on the canvas or a saved one.
void openDiaryDaySheet(BuildContext context, DateTime day) {
  _showSheet(context, (ctx) => _diaryDayTitle(ctx, day), _DiaryDay(day: day));
}

String _diaryDayTitle(BuildContext context, DateTime day) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString()).format(day);
  final prefix = day == today
      ? l10n.diaryToday
      : day == addDays(today, -1)
      ? l10n.diaryYesterday
      : null;
  return prefix == null ? date : '$prefix · $date';
}

class _DiaryDay extends StatelessWidget {
  final DateTime day;
  const _DiaryDay({required this.day});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final entries = store.diaryOn(day)..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final canvasHasClothes = store.currentOutfitItems.isNotEmpty;
    final time = DateFormat.Hm(Localizations.localeOf(context).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entries.isEmpty ? l10n.diaryDayEmpty : l10n.outfitCount(entries.length),
          style: entries.isEmpty
              ? AppText.sans(size: 13, color: AppColors.mutedTag)
              : AppText.mono(size: 10, letterSpacing: 0.5, color: AppColors.mutedTag),
        ),
        const SizedBox(height: 14),
        if (entries.isNotEmpty) ...[
          SizedBox(
            height: 244,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final e = entries[i];
                return GestureDetector(
                  // Wear it again: onto the canvas.
                  onTap: () {
                    store.loadDiaryEntry(e);
                    _backToOutfit(context);
                  },
                  child: Container(
                    width: 176,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.rowBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(child: OutfitPreview(slots: e.slots, itemById: store.itemById, nameOf: store.displayName)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  time.format(e.loggedAt),
                                  style: AppText.mono(size: 10, letterSpacing: 0.5, color: AppColors.label),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: l10n.diaryRemoveEntry,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final confirmed = await confirmDialog(
                                      context,
                                      title: l10n.diaryRemoveEntryTitle,
                                      message: l10n.diaryRemoveEntryMessage,
                                      confirmLabel: l10n.delete,
                                    );
                                    if (confirmed) store.deleteDiaryEntry(e.id);
                                  },
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Icon(Icons.close, size: 16, color: AppColors.muted),
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
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Expanded(
              child: _DetailAction(
                label: '+ ${l10n.diaryFromCanvas}',
                filled: canvasHasClothes,
                textColor: canvasHasClothes ? Colors.white : AppColors.mutedSoft,
                onTap: () {
                  if (!store.logCanvas(day)) store.flash(l10n.diaryCanvasEmpty);
                },
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _DetailAction(
                label: l10n.diaryFromSaved,
                textColor: AppColors.ink,
                onTap: () => _showSheet(
                  context,
                  (ctx) => AppLocalizations.of(ctx)!.diaryPickSavedTitle,
                  _PickSavedOutfit(day: day),
                  maxHeightFactor: 0.92,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Every saved outfit, newest first — tap one to write it down for [day].
/// [closeBoth] also closes the sheet this one was opened from, with a toast
/// saying where it was logged.
class _PickSavedOutfit extends StatelessWidget {
  final DateTime day;
  final bool closeBoth;
  const _PickSavedOutfit({required this.day, this.closeBoth = false});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final outfits = store.outfits.reversed.toList();
    if (outfits.isEmpty) {
      return Text(l10n.outfitsEmpty, style: AppText.sans(size: 13, color: AppColors.mutedTag, height: 1.4));
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: gridColumns(context, 3),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 0.8,
      children: [
        for (final o in outfits)
          GestureDetector(
            onTap: () {
              // An outfit whose clothes have all been deleted has nothing to log.
              if (!store.logSavedOutfit(day, o)) return;
              final nav = Navigator.of(context)..pop();
              if (closeBoth) {
                nav.pop();
                store.flash(l10n.toastLogged(_diaryDayTitle(context, day)));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.rowBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: OutfitPreview(slots: o.slots, itemById: store.itemById, nameOf: store.displayName),
            ),
          ),
      ],
    );
  }
}

/// Logs a worn outfit without going through the calendar: pick the day
/// (today by default), then the outfit on the canvas or a saved one.
void openLogOutfitSheet(BuildContext context) {
  _showSheet(context, (ctx) => AppLocalizations.of(ctx)!.diaryLogOutfit, const _LogOutfit());
}

class _LogOutfit extends StatefulWidget {
  const _LogOutfit();

  @override
  State<_LogOutfit> createState() => _LogOutfitState();
}

class _LogOutfitState extends State<_LogOutfit> {
  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  late DateTime _day = _today;

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: _today,
    );
    if (picked != null && mounted) setState(() => _day = DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final today = _today, yesterday = addDays(today, -1);
    final other = _day != today && _day != yesterday;
    final canvasHasClothes = store.currentOutfitItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sectionDay, style: _sectionLabelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            SelectChip(
              label: l10n.diaryToday,
              active: _day == today,
              mono: false,
              height: 34,
              onTap: () => setState(() => _day = today),
            ),
            SelectChip(
              label: l10n.diaryYesterday,
              active: _day == yesterday,
              mono: false,
              height: 34,
              onTap: () => setState(() => _day = yesterday),
            ),
            SelectChip(
              label: other ? DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString()).format(_day) : l10n.diaryOtherDay,
              active: other,
              mono: false,
              height: 34,
              onTap: _pickDay,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _DetailAction(
                label: '+ ${l10n.diaryFromCanvas}',
                filled: canvasHasClothes,
                textColor: canvasHasClothes ? Colors.white : AppColors.mutedSoft,
                onTap: () {
                  if (!store.logCanvas(_day)) {
                    store.flash(l10n.diaryCanvasEmpty);
                    return;
                  }
                  store.flash(l10n.toastLogged(_diaryDayTitle(context, _day)));
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _DetailAction(
                label: l10n.diaryFromSaved,
                textColor: AppColors.ink,
                onTap: () => _showSheet(
                  context,
                  (ctx) => AppLocalizations.of(ctx)!.diaryPickSavedTitle,
                  _PickSavedOutfit(day: _day, closeBoth: true),
                  maxHeightFactor: 0.92,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A saved outfit up close: how much it's been worn, what's in it, its
/// layout, and wearing it today, editing it on the canvas or deleting it.
void openOutfitDetail(BuildContext context, SavedOutfit outfit) {
  // No title: the outfit speaks for itself, the stats are in the sheet.
  // The close button sits next to what's in it instead.
  _showSheet(context, null, _OutfitDetail(outfitId: outfit.id), maxHeightFactor: 0.92);
}

class _OutfitDetail extends StatelessWidget {
  final String outfitId;
  const _OutfitDetail({required this.outfitId});

  /// The weekday it's worn on most, if one clearly stands out (at least
  /// twice, and more than any other) — 1 = Monday.
  static int? _usualWeekday(Set<DateTime> days) {
    if (days.length < 3) return null;
    final counts = <int, int>{};
    for (final d in days) {
      counts.update(d.weekday, (n) => n + 1, ifAbsent: () => 1);
    }
    final ranked = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.first.value < 2 || (ranked.length > 1 && ranked[1].value == ranked.first.value)) return null;
    return ranked.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final outfit = store.outfits.where((o) => o.id == outfitId).firstOrNull;
    if (outfit == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final days = store.outfitWearDays(outfit);
    final last = days.isEmpty ? null : days.reduce((a, b) => a.isAfter(b) ? a : b);
    final thisMonth = {for (final d in days) if (d.year == now.year && d.month == now.month) d.day};
    final weekday = _usualWeekday(days);
    final wornToday = days.contains(today);
    final pieces = [
      for (final id in outfit.itemIds)
        if (store.itemById(id) case final it?) store.displayName(it).toLowerCase(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                pieces.join(' · '),
                style: AppText.mono(size: 10, letterSpacing: 0.3, color: AppColors.mutedTag, height: 1.4),
              ),
            ),
            const SizedBox(width: 8),
            const _SheetCloseButton(),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 340,
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.rowBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: OutfitPreview(slots: outfit.slots, itemById: store.itemById, nameOf: store.displayName),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(DateFormat.LLLL(Localizations.localeOf(context).toString()).format(now).toUpperCase(), style: _sectionLabelStyle),
            const SizedBox(width: 12),
            if (weekday != null)
              Expanded(
                child: Text(
                  l10n.outfitUsualWeekday(weekday.toString()),
                  textAlign: TextAlign.right,
                  style: AppText.mono(size: 9.5, letterSpacing: 0.3, color: AppColors.mutedTag),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _MonthStrip(worn: thisMonth),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _WearTile(value: l10n.timesWorn(days.length), label: l10n.itemWornLabel)),
            const SizedBox(width: 8),
            Expanded(
              child: _WearTile(
                value: switch (last == null ? null : daysBetween(last, today)) {
                  null => l10n.statsNever,
                  0 => l10n.itemLastToday,
                  1 => l10n.itemLastYesterday,
                  final n => l10n.statsDaysAgo(n),
                },
                label: l10n.itemLastWornLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _DetailAction(
                label: wornToday ? l10n.outfitWornToday : l10n.wearToday,
                filled: !wornToday,
                textColor: wornToday ? AppColors.mutedSoft : Colors.white,
                onTap: () {
                  if (wornToday || !store.logSavedOutfit(today, outfit)) return;
                  store.flash(l10n.toastLogged(_diaryDayTitle(context, today)));
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 3,
              child: _DetailAction(
                label: l10n.editOnCanvas,
                textColor: AppColors.ink,
                onTap: () {
                  store.loadOutfit(outfit);
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 9),
            _DetailIconAction(
              icon: Icons.delete_outline,
              label: l10n.delete,
              onTap: () async {
                final confirmed = await confirmDialog(
                  context,
                  title: l10n.deleteOutfitTitle,
                  message: l10n.deleteOutfitPlain,
                  confirmLabel: l10n.delete,
                );
                if (!confirmed || !context.mounted) return;
                Navigator.of(context).pop();
                await store.deleteOutfit(outfit.id);
              },
            ),
          ],
        ),
      ],
    );
  }
}
