import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku/main.dart';
import 'package:sudoku/services/storage_service.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    final storage = StorageService();
    await storage.init();
    await tester.pumpWidget(SudokuApp(storage: storage));
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Select a difficulty'), findsOneWidget);
  });
}
