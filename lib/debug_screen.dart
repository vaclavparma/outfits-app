import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'reminders.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Opens the hidden debug screen (tap the version in settings five times).
void openDebugScreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const DebugScreen()));
}

/// Developer tools: what's stored where, the raw data, and ways to clean
/// up or start over. In English only — it's not meant for users.
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  ({
    String path,
    int stateBytes,
    int photoCount,
    int photoBytes,
    int missingPhotos,
    int orphanPhotos,
    List<String> backups,
    int? pendingReminders,
  })?
  _info;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final store = context.read<WardrobeStore>();
    final dir = await store.dataDirectory();
    final state = File('${dir.path}/satnik_v1.json');
    final photos = Directory('${dir.path}/satnik_images');
    var count = 0, bytes = 0;
    if (await photos.exists()) {
      await for (final f in photos.list()) {
        if (f is File) {
          count++;
          bytes += await f.length();
        }
      }
    }
    final info = (
      path: dir.path,
      stateBytes: await state.exists() ? await state.length() : 0,
      photoCount: count,
      photoBytes: bytes,
      missingPhotos: await store.missingPhotoCount(),
      orphanPhotos: (await store.orphanPhotos()).length,
      backups: [for (final f in await store.migrationBackups()) f.uri.pathSegments.last],
      pendingReminders: await DailyReminder.pendingCount(),
    );
    if (mounted) setState(() => _info = info);
  }

  /// Runs [action] with the screen marked busy, then shows [done] and
  /// refreshes the numbers.
  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final message = await action();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<bool> _confirm(String title, String message, String label) =>
      confirmDialog(context, title: title, message: message, confirmLabel: label);

  static String _count(int n, String one, [String? many]) => '$n ${n == 1 ? one : many ?? '${one}s'}';

  static String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final info = _info;
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
                        'Debug',
                        textAlign: TextAlign.center,
                        style: AppText.sans(size: 16, weight: FontWeight.w500, color: AppColors.ink),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: _busy ? const Center(child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    ),
                  ],
                ),
              ),
              Expanded(
                // Pull down to count again (e.g. reminders, rescheduled in
                // the background).
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      const SettingsSectionLabel('STORAGE', uppercase: true),
                      const SizedBox(height: 8),
                      SettingsCard(
                        child: Column(
                          children: [
                            _Row('State file', info == null ? '…' : _size(info.stateBytes)),
                            _Row('Photos', info == null ? '…' : '${info.photoCount} · ${_size(info.photoBytes)}'),
                            _Row('Items missing a photo', info == null ? '…' : '${info.missingPhotos}'),
                            _Row('Unused photo files', info == null ? '…' : '${info.orphanPhotos}'),
                            _Row('Migration backups', info == null ? '…' : (info.backups.isEmpty ? 'none' : info.backups.join('\n'))),
                            _Row('Folder', info?.path ?? '…', small: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SettingsSectionLabel('CONTENT', uppercase: true),
                      const SizedBox(height: 8),
                      SettingsCard(
                        child: Column(
                          children: [
                            for (final w in store.wardrobeSummaries)
                              _Row(
                                w.active ? '${w.name} (active)' : w.name,
                                '${_count(w.items, 'item')} · ${_count(w.outfits, 'outfit')} · ${_count(w.diary, 'diary entry', 'diary entries')}',
                              ),
                            _Row('Kinds / types', '${store.kinds.length} / ${store.kinds.fold<int>(0, (n, k) => n + k.types.length)}'),
                            _Row('Canvas cards', '${store.canvas.length}'),
                            _Row(
                              'Reminder',
                              '${store.reminderEnabled ? 'on' : 'off'} · ${(store.reminderMinutes ~/ 60).toString().padLeft(2, '0')}:'
                                  '${(store.reminderMinutes % 60).toString().padLeft(2, '0')} · '
                                  '${info?.pendingReminders ?? '?'} scheduled',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SettingsSectionLabel('TOOLS', uppercase: true),
                      const SizedBox(height: 8),
                      SettingsCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _Action('View raw data', onTap: () => _openJson(context, store)),
                            _Action(
                              'Send a test reminder',
                              onTap: () => _run(() async {
                                final t = store.texts;
                                final ok = await DailyReminder.showNow(
                                  title: t.reminderTitle,
                                  body: t.reminderBody,
                                  channelName: t.reminderChannel,
                                );
                                return ok ? 'Sent' : 'Notifications not allowed (or not available)';
                              }),
                            ),
                            _Action(
                              'Detect all colors again',
                              onTap: () async {
                                if (!await _confirm('Detect all colors again?', 'Colors corrected by hand are replaced too.', 'Detect')) return;
                                await _run(() async {
                                  await store.redetectAllColors();
                                  return 'Colors detected';
                                });
                              },
                            ),
                            _Action(
                              'Delete unused photo files',
                              onTap: () => _run(() async => 'Deleted ${await store.deleteOrphanPhotos()} files'),
                            ),
                            _Action(
                              'Delete migration backups',
                              onTap: () async {
                                if (!await _confirm('Delete migration backups?', 'Copies of the data from before older updates.', 'Delete')) return;
                                await _run(() async {
                                  final files = await store.migrationBackups();
                                  for (final f in files) {
                                    await f.delete();
                                  }
                                  return 'Deleted ${files.length} backups';
                                });
                              },
                            ),
                            _Action('Show onboarding again', onTap: () {
                              Navigator.of(context).popUntil((r) => r.isFirst);
                              store.resetOnboarding();
                            }),
                            _Action(
                              'Clear this wardrobe\'s diary',
                              danger: true,
                              onTap: () async {
                                if (!await _confirm('Clear the diary?', 'Every entry of “${store.activeWardrobe.name}” is deleted.', 'Clear')) return;
                                store.clearDiary();
                                await _refresh();
                              },
                            ),
                            _Action(
                              'Erase all data',
                              danger: true,
                              last: true,
                              onTap: () async {
                                if (!await _confirm(
                                  'Erase all data?',
                                  'Every wardrobe, photo, outfit, diary entry and setting is deleted, and the app starts over like a fresh install. This can\'t be undone.',
                                  'Erase',
                                )) {
                                  return;
                                }
                                if (!context.mounted) return;
                                Navigator.of(context).popUntil((r) => r.isFirst);
                                await store.eraseEverything();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openJson(BuildContext context, WardrobeStore store) {
    final text = const JsonEncoder.withIndent('  ').convert(store.stateJson);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: Row(
                    children: [
                      const AppBackButton(),
                      Expanded(
                        child: Text(
                          'satnik_v1.json',
                          textAlign: TextAlign.center,
                          style: AppText.mono(size: 13, color: AppColors.ink),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy',
                        icon: Icon(Icons.copy_rounded, size: 20, color: AppColors.ink),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: SelectableText(text, style: AppText.mono(size: 10.5, letterSpacing: 0, color: AppColors.ink, height: 1.4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool small;
  const _Row(this.label, this.value, {this.small = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: AppText.sans(size: 13.5, color: AppColors.ink))),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: AppText.mono(size: small ? 9 : 11, letterSpacing: 0.2, color: AppColors.mutedTag, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool last;
  const _Action(this.label, {required this.onTap, this.danger = false, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: AppColors.rowBorder))),
          child: Text(label, style: AppText.sans(size: 15, color: danger ? AppColors.danger : AppColors.accentText)),
        ),
      ),
    );
  }
}
