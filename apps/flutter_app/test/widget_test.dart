import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku/main.dart';
import 'package:sudoku/services/settings_service.dart';
import 'package:sudoku/services/storage_service.dart';
import 'package:sudoku/services/training_storage_service.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    final storage = StorageService();
    final settings = SettingsService();
    final trainingStorage = TrainingStorageService();
    await Future.wait([
      storage.init(),
      settings.init(),
      trainingStorage.init(),
    ]);
    await tester.pumpWidget(SudokuApp(
      storage: storage,
      settings: settings,
      trainingStorage: trainingStorage,
    ));
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Select a difficulty'), findsOneWidget);
  });
}
