import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';

/// One-time screen shown before [HomeScreen] until [WardrobeStore.completeOnboarding]
/// is called — lets the user name their wardrobe, pick a language and
/// whether they want to see the "šaty" (dresses) category, reusing the exact
/// same controls as the settings sheet for the latter two.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.sectionWardrobeName,
                        style: AppText.mono(size: 9.5, letterSpacing: 1.3, color: AppColors.mutedSoft),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          // Shown in whichever language is picked below, and
                          // used as the name if the field is left blank.
                          hintText: l10n.defaultWardrobeName,
                          hintStyle: AppText.sans(size: 14, color: AppColors.mutedTag),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        style: AppText.sans(size: 14, color: AppColors.ink),
                      ),
                      const SizedBox(height: 22),
                      const SettingsContent(),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => store.completeOnboarding(
                  wardrobeName: _nameController.text.trim().isEmpty
                      ? l10n.defaultWardrobeName
                      : _nameController.text,
                ),
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
