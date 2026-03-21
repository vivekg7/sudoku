import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';
import 'services/training_storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  final settings = SettingsService();
  final trainingStorage = TrainingStorageService();
  await Future.wait([storage.init(), settings.init(), trainingStorage.init()]);
  runApp(SudokuApp(
    storage: storage,
    settings: settings,
    trainingStorage: trainingStorage,
  ));
}

class SudokuApp extends StatelessWidget {
  final StorageService storage;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const SudokuApp({
    super.key,
    required this.storage,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Sudoku',
        debugShowCheckedModeBanner: false,
        themeMode: settings.appThemeMode.flutterThemeMode,
        theme: buildAppTheme(settings.appColor.seed, Brightness.light),
        darkTheme: buildAppTheme(
          settings.appColor.seed,
          Brightness.dark,
          amoled: settings.appThemeMode.isAmoled,
        ),
        home: HomeScreen(
          storage: storage,
          settings: settings,
          trainingStorage: trainingStorage,
        ),
      ),
    );
  }
}
