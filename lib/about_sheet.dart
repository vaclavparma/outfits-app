import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

const _githubUrl = 'https://github.com/vaclavparma/outfits-app';
const _buyMeACoffeeUrl = 'https://buymeacoffee.com/vaclavparma';

Future<void> _openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // No browser/app available to handle it — nothing else to do.
  }
}

void openAboutSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x47141414),
    builder: (sheetContext) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          child: const _AboutContent(),
        ),
      );
    },
  );
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              info?.appName ?? 'Outfits',
              style: AppText.sans(
                size: 19,
                weight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Šatník pro plánování outfitů',
              textAlign: TextAlign.center,
              style: AppText.sans(
                size: 12.5,
                color: AppColors.mutedTag,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              info == null
                  ? ''
                  : 'v${info.version} (${info.buildNumber}) · Václav Parma',
              style: AppText.mono(
                size: 9.5,
                letterSpacing: 0.3,
                color: AppColors.mutedSoft,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              height: 1,
              color: AppColors.hairline,
            ),
            const SizedBox(height: 18),
            _LinkRow(
              icon: Icons.code,
              label: 'Zdrojový kód na GitHubu',
              onTap: () => _openUrl(_githubUrl),
            ),
            const SizedBox(height: 8),
            _LinkRow(
              icon: Icons.coffee_outlined,
              label: 'Podpoř vývoj — Buy Me a Coffee',
              onTap: () => _openUrl(_buyMeACoffeeUrl),
            ),
          ],
        );
      },
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.label),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(size: 13, color: AppColors.label),
              ),
            ),
            const Icon(
              Icons.arrow_outward,
              size: 14,
              color: AppColors.mutedSoft,
            ),
          ],
        ),
      ),
    );
  }
}
