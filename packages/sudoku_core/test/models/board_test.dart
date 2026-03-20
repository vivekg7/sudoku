import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

// A valid solved board for testing.
const _solvedFlat =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

// A valid puzzle (unsolved) - some cells zeroed out.
const _puzzleFlat =
    '530070000600195000098000060800060003400803001700020006060000280000419005000080079';

void main() {
  group('Board', () {
    test('empty board is all zeros', () {
      final board = Board.empty();
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(board.getCell(r, c).isEmpty, true);
        }
      }
    });

    test('fromString parses correctly', () {
      final board = Board.fromString(_solvedFlat);
      expect(board.getCell(0, 0).value, 5);
      expect(board.getCell(0, 0).isGiven, true);
      expect(board.getCell(8, 8).value, 9);
    });

    test('fromString with dots for empties', () {
      final dotStr = _puzzleFlat.replaceAll('0', '.');
      final board = Board.fromString(dotStr);
      expect(board.getCell(0, 2).isEmpty, true); // '0' → '.' at position 2
      expect(board.getCell(0, 0).value, 5);
    });

    test('getRow returns 9 cells', () {
      final board = Board.fromString(_solvedFlat);
      final row = board.getRow(0);
      expect(row.length, 9);
      expect(row.map((c) => c.value).toList(), [5, 3, 4, 6, 7, 8, 9, 1, 2]);
    });

    test('getColumn returns 9 cells', () {
      final board = Board.fromString(_solvedFlat);
      final col = board.getColumn(0);
      expect(col.length, 9);
      expect(col.map((c) => c.value).toList(), [5, 6, 1, 8, 4, 7, 9, 2, 3]);
    });

    test('getBox returns 9 cells', () {
      final board = Board.fromString(_solvedFlat);
      final box = board.getBox(0);
      expect(box.length, 9);
      expect(box.map((c) => c.value).toList(), [5, 3, 4, 6, 7, 2, 1, 9, 8]);
    });

    test('peers returns 20 unique cells', () {
      final board = Board.empty();
      final p = board.peers(4, 4);
      expect(p.length, 20);
      // Should not include the cell itself
      expect(p.any((c) => c.row == 4 && c.col == 4), false);
    });

    test('peers returns correct cells for every position', () {
      final board = Board.empty();
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final p = board.peers(r, c);
          expect(p.length, 20, reason: 'peers($r,$c) should have 20 cells');

          // No duplicates.
          final coords = p.map((cell) => (cell.row, cell.col)).toSet();
          expect(coords.length, 20,
              reason: 'peers($r,$c) should have no duplicates');

          // Does not include self.
          expect(coords.contains((r, c)), false,
              reason: 'peers($r,$c) should not include self');

          // Every peer shares a row, column, or box.
          for (final cell in p) {
            final sameRow = cell.row == r;
            final sameCol = cell.col == c;
            final sameBox =
                (cell.row ~/ 3 == r ~/ 3) && (cell.col ~/ 3 == c ~/ 3);
            expect(sameRow || sameCol || sameBox, true,
                reason:
                    'peers($r,$c): cell (${cell.row},${cell.col}) shares no unit');
          }

          // Every cell that shares a unit IS in the peer list.
          for (var rr = 0; rr < 9; rr++) {
            for (var cc = 0; cc < 9; cc++) {
              if (rr == r && cc == c) continue;
              final sameRow = rr == r;
              final sameCol = cc == c;
              final sameBox =
                  (rr ~/ 3 == r ~/ 3) && (cc ~/ 3 == c ~/ 3);
              if (sameRow || sameCol || sameBox) {
                expect(coords.contains((rr, cc)), true,
                    reason:
                        'peers($r,$c) should include ($rr,$cc)');
              }
            }
          }
        }
      }
    });

    test('isValid on solved board', () {
      final board = Board.fromString(_solvedFlat);
      expect(board.isValid, true);
    });

    test('isSolved on solved board', () {
      final board = Board.fromString(_solvedFlat);
      expect(board.isSolved, true);
    });

    test('isSolved false on unsolved board', () {
      final board = Board.fromString(_puzzleFlat);
      expect(board.isSolved, false);
    });

    test('isValid detects duplicate in row', () {
      final board = Board.empty();
      board.getCell(0, 0).setValue(5);
      board.getCell(0, 1).setValue(5);
      expect(board.isValid, false);
    });

    test('isValid detects duplicate in column', () {
      final board = Board.empty();
      board.getCell(0, 0).setValue(3);
      board.getCell(1, 0).setValue(3);
      expect(board.isValid, false);
    });

    test('isValid detects duplicate in box', () {
      final board = Board.empty();
      board.getCell(0, 0).setValue(7);
      board.getCell(1, 1).setValue(7);
      expect(board.isValid, false);
    });

    test('toFlatString round-trips', () {
      final board = Board.fromString(_solvedFlat);
      expect(board.toFlatString(), _solvedFlat);
    });

    test('clone produces independent copy', () {
      final board = Board.fromString(_puzzleFlat);
      final copy = board.clone();
      // Modify copy on an empty cell - original should be unchanged
      copy.getCell(0, 2).setValue(4);
      expect(board.getCell(0, 2).isEmpty, true);
      expect(copy.getCell(0, 2).value, 4);
    });

    test('toString produces human-readable grid', () {
      final board = Board.fromString(_solvedFlat);
      final str = board.toString();
      expect(str, contains('5 3 4'));
      expect(str, contains('------'));
    });
  });
}
