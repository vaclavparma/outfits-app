import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'reminders.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

const _githubUrl = 'https://github.com/vaclavparma/outfits-app';
const _buyMeACoffeeUrl = 'https://buymeacoffee.com/vaclavparma';

/// Opens settings full screen, above the tab bar — they're app-wide, not
/// part of any one tab.
void openSettingsScreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
}

/// The app card (version, links), the wardrobes, the kinds and types of
/// clothing, and the app-wide options.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: Row(
                  children: [
                    const AppBackButton(),
                    Expanded(
                      child: Text(
                        l10n.settingsTitle,
                        textAlign: TextAlign.center,
                        style: AppText.sans(size: 16, weight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ),
                    // Balances the back button so the title stays centered.
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    const _AppCard(),
                    const SizedBox(height: 28),
                    SettingsSectionLabel(l10n.sectionWardrobes, uppercase: true),
                    const SizedBox(height: 8),
                    const _WardrobesCard(),
                    const SizedBox(height: 22),
                    SettingsSectionLabel(l10n.sectionKinds, uppercase: true),
                    const SizedBox(height: 8),
                    const _KindsCard(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                      child: Text(
                        l10n.kindsHint,
                        style: AppText.sans(size: 11.5, color: AppColors.mutedTag, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SettingsSectionLabel(l10n.sectionDiary, uppercase: true),
                    const SizedBox(height: 8),
                    const _ReminderCard(),
                    const SizedBox(height: 22),
                    const SettingsContent(uppercaseLabels: true),
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

class _AppCard extends StatelessWidget {
  const _AppCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsCard(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/icon/app_icon_small.png', width: 72, height: 72),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info?.appName ?? 'Outfits',
                          style: AppText.sans(size: 20, weight: FontWeight.w600, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(l10n.aboutTagline, style: AppText.sans(size: 14, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Text(
                          info == null ? ' ' : l10n.aboutVersionLine(info.version, info.buildNumber),
                          style: AppText.mono(size: 10, letterSpacing: 0.4, color: AppColors.mutedTag),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  // Brand names — not translated.
                  const Expanded(child: _LinkButton(label: 'GitHub', url: _githubUrl)),
                  const SizedBox(width: 10),
                  const Expanded(child: _LinkButton(label: 'Buy Me a Coffee', url: _buyMeACoffeeUrl)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  const _LinkButton({required this.label, required this.url});

  Future<void> _open() async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // No browser/app available to handle it — nothing else to do.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _open,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: AppColors.cardBorder),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 14, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.north_east, size: 12, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every wardrobe: tap to switch, "edit" to rename/delete, and a row to
/// add one.
class _WardrobesCard extends StatelessWidget {
  const _WardrobesCard();

  static const _rowPadding = EdgeInsets.fromLTRB(18, 0, 8, 0);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    return SettingsCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final w in store.wardrobes) ...[
            _WardrobeRow(wardrobe: w),
            Divider(height: 1, thickness: 1, color: AppColors.rowBorder),
          ],
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _add(context, store),
              child: Padding(
                padding: _rowPadding,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 32),
                      Text('+ ${l10n.newWardrobe}', style: AppText.sans(size: 15, color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

class _WardrobeRow extends StatelessWidget {
  final Wardrobe wardrobe;
  const _WardrobeRow({required this.wardrobe});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final active = wardrobe.id == store.activeWardrobeId;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => store.switchWardrobe(wardrobe.id),
        child: Padding(
          padding: _WardrobesCard._rowPadding,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: active ? Icon(Icons.check, size: 18, color: AppColors.accent) : null,
                ),
                Expanded(
                  child: Text(
                    wardrobe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 16, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.itemCount(store.itemCountIn(wardrobe.id)),
                  style: AppText.mono(size: 10, letterSpacing: 0.4, color: AppColors.mutedTag),
                ),
                const SizedBox(width: 16),
                _RowIcon(
                  icon: Icons.edit_outlined,
                  label: l10n.rename,
                  onTap: () => _rename(context, store),
                ),
                // Greyed out rather than hidden for the last wardrobe, so the
                // icons line up in every row.
                _RowIcon(
                  icon: Icons.delete_outline,
                  label: l10n.delete,
                  onTap: store.wardrobes.length > 1 ? () => _delete(context, store) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.renameWardrobeTitle,
      initialValue: wardrobe.name,
      confirmLabel: l10n.save,
    );
    if (name != null) await store.renameWardrobe(wardrobe.id, name);
  }

  Future<void> _delete(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDialog(
      context,
      title: l10n.deleteWardrobeTitle,
      message: l10n.deleteWardrobeMessage(wardrobe.name),
      confirmLabel: l10n.delete,
    );
    if (confirmed) await store.deleteWardrobe(wardrobe.id);
  }
}

/// A muted icon button in a wardrobe row (34 wide, so a pencil and a bin
/// sit close together, full row height to tap); disabled when [onTap] is
/// null.
class _RowIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _RowIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 48,
          child: Icon(
            icon,
            size: 19,
            color: onTap == null ? AppColors.mutedSoft.withValues(alpha: 0.35) : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

/// Every kind of clothing, in the order the wardrobe shows them: drag the
/// handle to reorder, pencil/bin to rename/delete, tap to see its types.
class _KindsCard extends StatefulWidget {
  const _KindsCard();

  @override
  State<_KindsCard> createState() => _KindsCardState();
}

class _KindsCardState extends State<_KindsCard> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final kinds = store.kinds;
    return SettingsCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: _liftedRow,
            itemCount: kinds.length,
            onReorderItem: store.reorderKinds,
            itemBuilder: (context, i) {
              final k = kinds[i];
              return _KindRow(
                key: ValueKey(k.id),
                index: i,
                kind: k,
                expanded: _expanded.contains(k.id),
                onToggleExpanded: () => setState(() {
                  if (!_expanded.remove(k.id)) _expanded.add(k.id);
                }),
              );
            },
          ),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _add(context, store),
              child: Padding(
                padding: const EdgeInsets.only(left: 44),
                child: SizedBox(
                  height: 56,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('+ ${l10n.newKind}', style: AppText.sans(size: 15, color: AppColors.accent)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.newKind,
      initialValue: '',
      hintText: l10n.newKindHint,
      confirmLabel: l10n.create,
    );
    if (name == null) return;
    final kind = store.addKind(name);
    // Straight to its types.
    if (kind != null) setState(() => _expanded.add(kind.id));
  }
}

/// A row being dragged to a new place: lifted off the card.
Widget _liftedRow(Widget child, int index, Animation<double> animation) => AnimatedBuilder(
  animation: animation,
  builder: (context, child) => Material(
    color: AppColors.surface,
    elevation: 6 * animation.value,
    shadowColor: const Color(0x33000000),
    borderRadius: BorderRadius.circular(12),
    child: child,
  ),
  child: child,
);

/// The grip a row is dragged by.
class _DragHandle extends StatelessWidget {
  final int index;
  final double width;
  const _DragHandle({required this.index, this.width = 44});

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Semantics(
        label: AppLocalizations.of(context)!.reorder,
        child: SizedBox(
          width: width,
          height: 48,
          child: Icon(Icons.drag_indicator, size: 20, color: AppColors.mutedSoft),
        ),
      ),
    );
  }
}

class _KindRow extends StatelessWidget {
  final int index;
  final ClothingKind kind;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const _KindRow({
    super.key,
    required this.index,
    required this.kind,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.read<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
              child: Row(
                children: [
                  _DragHandle(index: index),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(size: 16, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kind.types.map((t) => t.name).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(size: 12, color: AppColors.mutedTag),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RowIcon(icon: Icons.edit_outlined, label: l10n.rename, onTap: () => _rename(context, store)),
                  _RowIcon(icon: Icons.delete_outline, label: l10n.delete, onTap: () => _delete(context, store)),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: SizedBox(
                      width: 34,
                      child: Icon(Icons.keyboard_arrow_down, size: 22, color: AppColors.mutedSoft),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: expanded ? _TypeList(kind: kind) : const SizedBox(width: double.infinity),
        ),
        Divider(height: 1, thickness: 1, color: AppColors.rowBorder),
      ],
    );
  }

  Future<void> _rename(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.renameKindTitle,
      initialValue: kind.name,
      confirmLabel: l10n.save,
    );
    if (name != null) store.renameKind(kind.id, name);
  }

  Future<void> _delete(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final count = store.kindItemCount(kind.id);
    if (count > 0) {
      await infoDialog(
        context,
        title: l10n.kindNotEmptyTitle,
        message: l10n.kindNotEmptyMessage(kind.name, l10n.itemCount(count)),
      );
      return;
    }
    final confirmed = await confirmDialog(
      context,
      title: l10n.deleteKindTitle,
      message: l10n.deleteKindMessage(kind.name),
      confirmLabel: l10n.delete,
    );
    if (confirmed) store.deleteKind(kind.id);
  }
}

/// An expanded kind's types: reorderable rows with their item counts,
/// rename and delete, and a row to add one.
class _TypeList extends StatelessWidget {
  final ClothingKind kind;
  const _TypeList({required this.kind});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final types = kind.types;
    return Container(
      color: AppColors.background.withValues(alpha: 0.6),
      padding: const EdgeInsets.only(left: 32, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: _liftedRow,
            itemCount: types.length,
            onReorderItem: (from, to) => store.reorderTypes(kind.id, from, to),
            itemBuilder: (context, i) {
              final t = types[i];
              return Padding(
                key: ValueKey(t.id),
                padding: const EdgeInsets.only(right: 40),
                child: Row(
                  children: [
                    _DragHandle(index: i, width: 40),
                    Expanded(
                      child: Text(
                        t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(size: 14.5, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.itemCount(store.typeItemCount(kind.id, t.id)),
                      style: AppText.mono(size: 9.5, letterSpacing: 0.4, color: AppColors.mutedTag),
                    ),
                    const SizedBox(width: 10),
                    _RowIcon(icon: Icons.edit_outlined, label: l10n.rename, onTap: () => _rename(context, store, t)),
                    // Greyed out for the last type: every item needs one.
                    _RowIcon(
                      icon: Icons.delete_outline,
                      label: l10n.delete,
                      onTap: types.length > 1 ? () => _delete(context, store, t) : null,
                    ),
                  ],
                ),
              );
            },
          ),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _add(context, store),
              child: Padding(
                padding: const EdgeInsets.only(left: 40),
                child: SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('+ ${l10n.newTypeTitle}', style: AppText.sans(size: 14, color: AppColors.accent)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.newTypeTitle,
      initialValue: '',
      hintText: l10n.newTypeHint,
      confirmLabel: l10n.create,
    );
    if (name != null) store.addType(kind.id, name);
  }

  Future<void> _rename(BuildContext context, WardrobeStore store, ClothingType t) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.renameTypeTitle,
      initialValue: t.name,
      confirmLabel: l10n.save,
    );
    if (name != null) store.renameType(kind.id, t.id, name);
  }

  Future<void> _delete(BuildContext context, WardrobeStore store, ClothingType t) =>
      deleteTypeAskingWhereTo(context, kind, t);
}

/// The daily diary reminder: on/off, and (when on) the time it comes.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  Future<void> _toggle(BuildContext context, WardrobeStore store, bool on) async {
    if (!on) {
      store.setReminder(enabled: false);
      return;
    }
    final allowed = await DailyReminder.requestPermission();
    if (allowed) {
      store.setReminder(enabled: true);
    } else if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      await infoDialog(context, title: l10n.reminderDeniedTitle, message: l10n.reminderDeniedMessage);
    }
  }

  Future<void> _pickTime(BuildContext context, WardrobeStore store) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: store.reminderMinutes ~/ 60, minute: store.reminderMinutes % 60),
    );
    if (picked != null) store.setReminder(minutes: picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final time = TimeOfDay(hour: store.reminderMinutes ~/ 60, minute: store.reminderMinutes % 60);
    return SettingsCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.reminderLabel, style: AppText.sans(size: 16, color: AppColors.ink)),
                      const SizedBox(height: 3),
                      Text(l10n.reminderHint, style: AppText.sans(size: 12, color: AppColors.mutedTag, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: store.reminderEnabled,
                  activeThumbColor: AppColors.accent,
                  onChanged: (on) => _toggle(context, store, on),
                ),
              ],
            ),
          ),
          if (store.reminderEnabled) ...[
            Divider(height: 1, thickness: 1, color: AppColors.rowBorder),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _pickTime(context, store),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        Expanded(child: Text(l10n.reminderTime, style: AppText.sans(size: 16, color: AppColors.ink))),
                        Text(
                          MaterialLocalizations.of(context).formatTimeOfDay(
                            time,
                            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                          ),
                          style: AppText.sans(size: 16, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
