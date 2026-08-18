import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'l10n/app_localizations.dart';
import 'onboarding_screen.dart';
import 'theme.dart';
import 'wardrobe_store.dart';

void main() {
  runApp(const SatnikApp());
}

class SatnikApp extends StatelessWidget {
  const SatnikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WardrobeStore()..load(),
      child: Consumer<WardrobeStore>(
        builder: (context, store, _) => MaterialApp(
          title: 'Outfits',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          locale: store.localeCode == null ? null : Locale(store.localeCode!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Before `load()` resolves, stay on a bare background rather than
          // flashing onboarding (or the home screen) with pre-load defaults.
          home: !store.loaded
              ? const Scaffold(backgroundColor: AppColors.background)
              : store.onboardingDone
              ? const HomeScreen()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}
