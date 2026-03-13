import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cell', () {
    test('box is derived from row and col', () {
      expect(Cell(row: 0, col: 0).box, 0);
      expect(Cell(row: 0, col: 3).box, 1);
      expect(Cell(row: 0, col: 8).box, 2);
      expect(Cell(row: 3, col: 0).box, 3);
      expect(Cell(row: 4, col: 4).box, 4);
      expect(Cell(row: 8, col: 8).box, 8);
    });

    test('defaults to empty with no candidates', () {
      final cell = Cell(row: 0, col: 0);
      expect(cell.isEmpty, true);
      expect(cell.isFilled, false);
      expect(cell.value, 0);
      expect(cell.candidates, isEmpty);
      expect(cell.isGiven, false);
    });

    test('setValue sets value and clears candidates', () {
      final cell = Cell(row: 0, col: 0);
      cell.addCandidate(3);
      cell.addCandidate(5);
      cell.setValue(3);
      expect(cell.value, 3);
      expect(cell.isFilled, true);
      expect(cell.candidates, isEmpty);
    });

    test('clearValue resets to empty', () {
      final cell = Cell(row: 0, col: 0, value: 5);
      cell.clearValue();
      expect(cell.isEmpty, true);
    });

    test('given cells cannot be modified', () {
      final cell = Cell(row: 0, col: 0, value: 7, isGiven: true);
      expect(() => cell.setValue(3), throwsStateError);
      expect(() => cell.clearValue(), throwsStateError);
      expect(cell.value, 7);
    });

    test('toggleCandidate adds and removes', () {
      final cell = Cell(row: 0, col: 0);
      cell.toggleCandidate(4);
      expect(cell.candidates, {4});
      cell.toggleCandidate(4);
      expect(cell.candidates, isEmpty);
    });

    test('candidates ignored on filled cells', () {
      final cell = Cell(row: 0, col: 0);
      cell.setValue(5);
      cell.addCandidate(3);
      cell.toggleCandidate(7);
      expect(cell.candidates, isEmpty);
    });

    test('setCandidates replaces all', () {
      final cell = Cell(row: 0, col: 0);
      cell.addCandidate(1);
      cell.setCandidates({3, 5, 7});
      expect(cell.candidates, {3, 5, 7});
    });

    test('clone produces independent copy', () {
      final cell = Cell(row: 1, col: 2);
      cell.addCandidate(4);
      final copy = cell.clone();
      copy.addCandidate(9);
      expect(cell.candidates, {4});
      expect(copy.candidates, {4, 9});
    });

    test('toString shows value or dot', () {
      expect(Cell(row: 0, col: 0).toString(), '.');
      expect(Cell(row: 0, col: 0, value: 5).toString(), '5');
    });
  });
}
