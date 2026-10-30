import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'debug_screen.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'reminders.dart';
import 'review_prompt.dart';
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
                    const SettingsContent(uppercaseLabels: true),
                    const SizedBox(height: 22),
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
                    const ReminderCard(),
                    const SizedBox(height: 22),
                    SettingsSectionLabel(l10n.sectionData, uppercase: true),
                    const SizedBox(height: 8),
                    const _DataCard(),
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

/// Export everything as a zip (to share or keep wherever), or import one —
/// e.g. on a new phone.
class _DataCard extends StatefulWidget {
  const _DataCard();

  @override
  State<_DataCard> createState() => _DataCardState();
}

class _DataCardState extends State<_DataCard> {
  /// Which row is working (zipping, unpacking), if either.
  bool _exporting = false;
  bool _importing = false;

  final _exportKey = GlobalKey();

  Future<void> _export() async {
    if (_exporting || _importFlow) return;
    final l10n = AppLocalizations.of(context)!;
    final store = context.read<WardrobeStore>();
    // Where the share popover points from on iPad.
    final box = _exportKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _exporting = true);
    try {
      final zip = await store.exportArchive();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(zip.path, mimeType: 'application/zip')],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) await infoDialog(context, title: l10n.exportData, message: l10n.exportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Set from the first tap until the import is over (picker and dialogs
  /// included), so a second tap can't start another one alongside.
  bool _importFlow = false;

  Future<void> _import() async {
    if (_exporting || _importFlow) return;
    _importFlow = true;
    try {
      await _runImport();
    } catch (_) {
      if (mounted) await _fail(ImportResult.failed);
    } finally {
      _importFlow = false;
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _runImport() async {
    final l10n = AppLocalizations.of(context)!;
    final store = context.read<WardrobeStore>();
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'zip',
          extensions: ['zip'],
          mimeTypes: ['application/zip'],
          uniformTypeIdentifiers: ['public.zip-archive'],
        ),
      ],
    );
    if (file == null || !mounted) return;
    setState(() => _importing = true);
    final (backup, problem) = await WardrobeStore.openArchive(file.path);
    if (!mounted) return;
    setState(() => _importing = false);
    if (backup == null) {
      await _fail(problem);
      return;
    }
    final confirmed = await confirmDialog(
      context,
      title: l10n.importConfirmTitle,
      message: l10n.importConfirmMessage(
        l10n.wardrobeCount(backup.wardrobeCount),
        l10n.itemCount(backup.itemCount),
        l10n.outfitCount(backup.outfitCount),
      ),
      confirmLabel: l10n.importConfirm,
    );
    if (!confirmed || !mounted) return;
    setState(() => _importing = true);
    final result = await store.importArchive(backup);
    if (!mounted) return;
    setState(() => _importing = false);
    if (result != ImportResult.done) {
      await _fail(result);
      return;
    }
    Haptics.done();
    // A reminder that was on where the backup came from needs this phone's
    // permission too; without it, it's switched off rather than silently
    // never coming.
    if (store.reminderEnabled && !await DailyReminder.requestPermission()) {
      store.setReminder(enabled: false);
    }
    if (!mounted) return;
    // Back to the start: screens open underneath may show what's gone.
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    store.flash(l10n.importDone);
  }

  Future<void> _fail(ImportResult result) {
    final l10n = AppLocalizations.of(context)!;
    return infoDialog(
      context,
      title: l10n.importFailedTitle,
      message: switch (result) {
        ImportResult.notABackup => l10n.importNotABackup,
        ImportResult.newerVersion => l10n.importNewerVersion,
        _ => l10n.importFailed,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _DataRow(
            key: _exportKey,
            icon: Icons.ios_share_rounded,
            label: l10n.exportData,
            hint: l10n.exportDataHint,
            busy: _exporting,
            onTap: _export,
          ),
          Divider(height: 1, thickness: 1, color: AppColors.rowBorder),
          _DataRow(
            icon: Icons.download_rounded,
            label: l10n.importData,
            hint: l10n.importDataHint,
            busy: _importing,
            onTap: _import,
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool busy;
  final VoidCallback onTap;

  const _DataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.sans(size: 16, color: AppColors.ink)),
                    const SizedBox(height: 3),
                    Text(hint, style: AppText.sans(size: 12, color: AppColors.mutedTag, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox.square(
                dimension: 22,
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(2),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentText),
                      )
                    : Icon(icon, size: 21, color: AppColors.accentText),
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
                        _VersionLine(text: info == null ? ' ' : l10n.aboutVersionLine(info.version, info.buildNumber)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _RateBanner(),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Brand names — not translated.
                  const Expanded(
                    child: _LinkButton(label: 'GitHub', url: _githubUrl),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _LinkButton(label: 'Buy Me a Coffee', url: _buyMeACoffeeUrl),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "Rate Outfits": five stars, a line on why it helps, and off to the
/// store's review page. Going there counts as rated — the app stops asking
/// with the system popup.
class _RateBanner extends StatelessWidget {
  const _RateBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.read<WardrobeStore>().markRated();
          ReviewPrompt.openStore();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
          decoration: BoxDecoration(color: AppColors.cardFill, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        children: [
                          for (var i = 0; i < 5; i++) Icon(Icons.star_rounded, size: 18, color: AppColors.warn),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.rateApp,
                      style: AppText.sans(size: 15, weight: FontWeight.w500, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(l10n.rateAppHint, style: AppText.sans(size: 13, color: AppColors.muted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: const Icon(Icons.north_east, size: 17, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The version line — five quick taps on it open the hidden debug screen.
class _VersionLine extends StatefulWidget {
  final String text;
  const _VersionLine({required this.text});

  @override
  State<_VersionLine> createState() => _VersionLineState();
}

class _VersionLineState extends State<_VersionLine> {
  static const _taps = 5;

  /// A pause longer than this starts the count over.
  static const _maxGap = Duration(milliseconds: 600);

  int _count = 0;
  DateTime? _last;

  void _tap() {
    final now = DateTime.now();
    final last = _last;
    _count = last != null && now.difference(last) <= _maxGap ? _count + 1 : 1;
    _last = now;
    if (_count < _taps) return;
    _count = 0;
    _last = null;
    openDebugScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(widget.text, style: AppText.mono(size: 10, letterSpacing: 0.4, color: AppColors.mutedTag)),
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
          constraints: const BoxConstraints(minHeight: 46),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: AppColors.cardBorder),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
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
                      Text('+ ${l10n.newWardrobe}', style: AppText.sans(size: 15, color: AppColors.accentText)),
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
      isTaken: store.wardrobeNameTaken,
    );
    if (name == null) return;
    Haptics.done();
    await store.addWardrobe(name);
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
        onTap: () {
          if (wardrobe.id != store.activeWardrobeId) Haptics.tick();
          store.switchWardrobe(wardrobe.id);
        },
        child: Padding(
          padding: _WardrobesCard._rowPadding,
          // At least 56 tall; a long name with large text wraps.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                SizedBox(width: 32, child: active ? Icon(Icons.check, size: 18, color: AppColors.accentText) : null),
                Expanded(
                  child: Text(
                    wardrobe.name,
                    maxLines: 2,
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
                _RowIcon(icon: Icons.edit_outlined, label: l10n.rename, onTap: () => _rename(context, store)),
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
      isTaken: (n) => store.wardrobeNameTaken(n, except: wardrobe.id),
    );
    if (name == null) return;
    Haptics.done();
    await store.renameWardrobe(wardrobe.id, name);
  }

  Future<void> _delete(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDialog(
      context,
      title: l10n.deleteWardrobeTitle,
      message: l10n.deleteWardrobeMessage(wardrobe.name),
      confirmLabel: l10n.delete,
    );
    if (!confirmed) return;
    Haptics.remove();
    await store.deleteWardrobe(wardrobe.id);
  }
}

/// A muted icon button in a wardrobe row (40 wide, so a pencil and a bin
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
          width: 40,
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
            onReorderStart: (_) => Haptics.pickUp(),
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
                    child: Text('+ ${l10n.newKind}', style: AppText.sans(size: 15, color: AppColors.accentText)),
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
      isTaken: store.kindNameTaken,
    );
    if (name == null) return;
    final kind = store.addKind(name);
    if (kind != null) Haptics.done();
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
      isTaken: (n) => store.kindNameTaken(n, except: kind.id),
    );
    if (name == null) return;
    Haptics.done();
    store.renameKind(kind.id, name);
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
    if (!confirmed) return;
    Haptics.remove();
    store.deleteKind(kind.id);
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
            onReorderStart: (_) => Haptics.pickUp(),
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
                    child: Text('+ ${l10n.newTypeTitle}', style: AppText.sans(size: 14, color: AppColors.accentText)),
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
      isTaken: (n) => store.typeNameTaken(kind.id, n),
    );
    if (name == null) return;
    Haptics.done();
    store.addType(kind.id, name);
  }

  Future<void> _rename(BuildContext context, WardrobeStore store, ClothingType t) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.renameTypeTitle,
      initialValue: t.name,
      confirmLabel: l10n.save,
      isTaken: (n) => store.typeNameTaken(kind.id, n, except: t.id),
    );
    if (name == null) return;
    Haptics.done();
    store.renameType(kind.id, t.id, name);
  }

  Future<void> _delete(BuildContext context, WardrobeStore store, ClothingType t) =>
      deleteTypeAskingWhereTo(context, kind, t);
}

/// The daily diary reminder: on/off, and (when on) the time it comes.
class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key});

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
    if (picked == null) return;
    Haptics.done();
    store.setReminder(minutes: picked.hour * 60 + picked.minute);
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
                        Expanded(
                          child: Text(l10n.reminderTime, style: AppText.sans(size: 16, color: AppColors.ink)),
                        ),
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatTimeOfDay(time, alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context)),
                          style: AppText.sans(size: 16, color: AppColors.accentText),
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
