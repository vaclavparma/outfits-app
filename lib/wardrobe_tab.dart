import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'type_detail_screen.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// The clothing in the active wardrobe: one section per kind, with a
/// folder per type. While searching, the sections give way to a flat grid
/// of matching items.
class WardrobeTab extends StatefulWidget {
  /// [browseIds]: the items it was picked from, in order, to swipe through.
  final void Function(ClothingItem item, List<String> browseIds) onOpenItem;

  const WardrobeTab({super.key, required this.onOpenItem});

  @override
  State<WardrobeTab> createState() => _WardrobeTabState();
}

class _WardrobeTabState extends State<WardrobeTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final kinds = store.kinds;

    final results = _query.trim().isEmpty
        ? null
        : store.items
              .where((it) => textsMatchSearch(store.searchTexts(it), _query))
              .toList();

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tabWardrobe,
                    style: AppText.sans(size: 26, weight: FontWeight.w300, color: AppColors.ink, letterSpacing: -0.4),
                  ),
                ),
                _AddButton(label: l10n.addClothes, onTap: () => openAddItemSheet(context)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          sliver: SliverToBoxAdapter(
            child: SearchField(onChanged: (v) => setState(() => _query = v)),
          ),
        ),
        if (results != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: results.isEmpty
                ? SliverToBoxAdapter(
                    child: Text(
                      l10n.nothingFound,
                      style: AppText.sans(size: 13, color: AppColors.mutedTag),
                    ),
                  )
                : SliverGrid.count(
                    crossAxisCount: gridColumns(context, 3),
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 100 / 124,
                    children: [
                      for (final it in results)
                        GarmentCard(
                          width: double.infinity,
                          height: double.infinity,
                          slotLabel: store.kindName(it.cat).toLowerCase(),
                          imagePath: it.imagePath,
                          onTap: () => widget.onOpenItem(it, [for (final x in results) x.id]),
                        ),
                    ],
                  ),
          )
        else
          SliverList.list(
            children: [
              for (final k in kinds)
                _KindSection(key: ValueKey(k.id), kind: k),
              const SizedBox(height: 12),
            ],
          ),
      ],
    );
  }
}

/// "+ Přidat" next to the title.
class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(19)),
          alignment: Alignment.center,
          child: Text(
            '+ $label',
            style: AppText.sans(size: 13, weight: FontWeight.w500, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// One kind: its name and count, then a folder per type (a collage of
/// what's in it) — tap one to see its clothing — and a tile for a new type.
class _KindSection extends StatelessWidget {
  final ClothingKind kind;

  const _KindSection({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final all = store.itemsOfKind(kind.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  kind.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 17, weight: FontWeight.w500, color: AppColors.ink),
                ),
              ),
              Text(
                l10n.itemCount(all.length),
                style: AppText.mono(size: 9.5, letterSpacing: 0.8, color: AppColors.mutedSoft),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            crossAxisCount: gridColumns(context, 3),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
            children: [
              for (final t in kind.types)
                _TypeFolder(
                  kind: kind,
                  type: t,
                  items: [for (final it in all) if (it.typeId == t.id) it],
                ),
              AddTile(label: l10n.newTypeTile, onTap: () => _newType(context, store)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _newType(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.newTypeTitle,
      initialValue: '',
      hintText: l10n.newTypeHint,
      confirmLabel: l10n.create,
      isTaken: (n) => store.typeNameTaken(kind.id, n),
    );
    if (name != null) store.addType(kind.id, name);
  }
}

class _TypeFolder extends StatelessWidget {
  final ClothingKind kind;
  final ClothingType type;
  final List<ClothingItem> items;

  const _TypeFolder({required this.kind, required this.type, required this.items});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TypeDetailScreen(kindId: kind.id, typeId: type.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.rowBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: items.isEmpty
                  ? Container(
                      color: AppColors.cardFill,
                      alignment: Alignment.center,
                      child: Icon(Icons.checkroom_outlined, size: 24, color: AppColors.mutedSoft),
                    )
                  : OutfitCollage(items: items),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.itemCount(items.length),
                    style: AppText.mono(size: 8.5, letterSpacing: 0.5, color: AppColors.mutedSoft),
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
