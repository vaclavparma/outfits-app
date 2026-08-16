import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
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
      child: MaterialApp(
        title: 'Šatník',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
