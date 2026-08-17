import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'l10n/app_localizations.dart';
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
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
