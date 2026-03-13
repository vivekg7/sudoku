import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('computeCandidates', () {
    test('fills correct candidates for empty cells', () {
      final board = Board.fromString(
        '530070000'
        '600195000'
        '098000060'
        '800060003'
        '400803001'
        '700020006'
        '060000280'
        '000419005'
        '000080079',
      );
      computeCandidates(board);

      // R1C3 (row 0, col 2) is empty. Row has 5,3,7. Col has 9,8.
      // Box 0 has 5,6,9,8. So candidates should exclude {5,3,7,6,9,8}.
      final cell = board.getCell(0, 2);
      expect(cell.candidates, isNotEmpty);
      expect(cell.candidates, isNot(contains(5)));
      expect(cell.candidates, isNot(contains(3)));
      expect(cell.candidates, isNot(contains(7)));
    });

    test('does not touch filled cells', () {
      final board = Board.fromString(
        '534678912'
        '672195348'
        '198342567'
        '859761423'
        '426853791'
        '713924856'
        '961537284'
        '287419635'
        '345286179',
      );
      computeCandidates(board);

      // All cells are filled — no candidates anywhere.
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(board.getCell(r, c).candidates, isEmpty);
        }
      }
    });
  });
}
