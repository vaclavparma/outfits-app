import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';

/// One-time screen shown before [HomeScreen] until [WardrobeStore.completeOnboarding]
/// is called — lets the user pick a language and whether they want to see
/// the "šaty" (dresses) category, reusing the exact same controls as the
/// settings sheet.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = context.read<WardrobeStore>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/icon/app_icon.png', width: 56, height: 56),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.onboardingTitle,
                style: AppText.sans(size: 22, weight: FontWeight.w600, color: AppColors.ink),
              ),
              const SizedBox(height: 12),
              Text(l10n.onboardingSubtitle, style: AppText.sans(size: 13, color: AppColors.mutedTag, height: 1.4)),
              const SizedBox(height: 56),
              Expanded(child: SingleChildScrollView(child: SettingsContent())),
              GestureDetector(
                onTap: store.completeOnboarding,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(24)),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.onboardingContinue,
                    style: AppText.sans(size: 13, weight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
