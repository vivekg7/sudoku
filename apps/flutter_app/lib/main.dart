import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  final settings = SettingsService();
  await Future.wait([storage.init(), settings.init()]);
  runApp(SudokuApp(storage: storage, settings: settings));
}

class SudokuApp extends StatelessWidget {
  final StorageService storage;
  final SettingsService settings;

  const SudokuApp({super.key, required this.storage, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Sudoku',
        debugShowCheckedModeBanner: false,
        themeMode: settings.themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: settings.appColor.seed),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: settings.appColor.seed,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: HomeScreen(storage: storage, settings: settings),
      ),
    );
  }
}
