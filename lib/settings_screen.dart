import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
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

/// The app card (version, links), the wardrobes, and the app-wide options.
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
