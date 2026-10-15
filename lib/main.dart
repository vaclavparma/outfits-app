import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'l10n/app_localizations.dart';
import 'onboarding_screen.dart';
import 'reminders.dart';
import 'theme.dart';
import 'wardrobe_store.dart';

/// The most the system text size setting enlarges text in the app.
const maxTextScale = 2.0;

void main() {
  runApp(const SatnikApp());
}

class SatnikApp extends StatelessWidget {
  const SatnikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final store = WardrobeStore();
        store.load().then((_) {
          ReminderSync.start(store);
          // Colors for items that don't have them yet, in the background.
          store.detectMissingColors();
        });
        return store;
      },
      child: Consumer<WardrobeStore>(
        builder: (context, store, _) {
          // Depends on the system setting too, so this reruns when it flips
          // (e.g. automatic dark mode in the evening) while the app is open.
          final dark = switch (store.themeMode) {
            ThemeMode.light => false,
            ThemeMode.dark => true,
            ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
          };
          _applyPalette(context, dark ? AppPalette.dark : AppPalette.light);

          return MaterialApp(
            title: 'Outfits',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            // AppColors switch instantly; don't let Theme-derived colors
            // cross-fade on their own schedule next to them.
            themeAnimationDuration: Duration.zero,
            locale: store.localeCode == null ? null : Locale(store.localeCode!),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              // The system text size applies everywhere, up to double —
              // enough to read comfortably (the 200% Apple asks for), while
              // dense spots (the calendar, the tab bar) still hold together.
              child: MediaQuery.withClampedTextScaling(maxScaleFactor: maxTextScale, child: child!),
            ),
            // Before `load()` resolves, stay on a bare background rather than
            // flashing onboarding (or the home screen) with pre-load defaults.
            home: !store.loaded
                ? Scaffold(backgroundColor: AppColors.background)
                : store.onboardingDone
                ? const HomeScreen()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

/// Swaps [AppColors.current] and, if that changed anything, rebuilds every
/// widget below [context] in place — state (open screens, scroll positions,
/// half-typed text) is kept; widgets just re-read their colors. Most don't
/// depend on Theme, so nothing else would tell them to.
///
/// Called while [context]'s element is building, which is exactly when the
/// framework allows marking its descendants dirty (it's how inherited
/// widgets notify dependents).
void _applyPalette(BuildContext context, AppPalette palette) {
  if (identical(AppColors.current, palette)) return;
  AppColors.current = palette;
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}
