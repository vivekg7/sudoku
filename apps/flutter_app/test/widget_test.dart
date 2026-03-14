import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SudokuApp());
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Select a difficulty'), findsOneWidget);
  });
}
