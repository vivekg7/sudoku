import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  final strategy = SueDeCoq();

  group('Sue de Coq', () {
    test('finds elimination from box-line intersection', () {
      final board = Board.empty();

      // Box 0 (rows 0-2, cols 0-2) intersecting row 0.
      // Fill (0,2) so only 2 empty cells in intersection.
      board.getCell(0, 2).setValue(9);

      // Intersection cells: (0,0) and (0,1) with 4 total candidates.
      board.getCell(0, 0).setCandidates({1, 2, 3});
      board.getCell(0, 1).setCandidates({1, 2, 4});
      // Union: {1,2,3,4} — 4 candidates for 2 cells (N=2, N+2=4). ✓

      // Rest of row 0 (outside box 0): cols 3-8.
      board.getCell(0, 3).setCandidates({3, 5});
      board.getCell(0, 4).setCandidates({6, 7});
      board.getCell(0, 5).setCandidates({5, 8});
      board.getCell(0, 6).setValue(6);
      board.getCell(0, 7).setValue(7);
      board.getCell(0, 8).setValue(8);

      // Rest of box 0 (outside row 0): rows 1-2, cols 0-2.
      board.getCell(1, 0).setCandidates({4, 5});
      board.getCell(1, 1).setCandidates({6, 7});
      board.getCell(1, 2).setCandidates({5, 8});
      board.getCell(2, 0).setCandidates({7, 8});
      board.getCell(2, 1).setCandidates({5, 6});
      board.getCell(2, 2).setCandidates({8, 7});

      // restLineCands = {3,5,6,7,8}, restBoxCands = {4,5,6,7,8}
      // lineOnly = {1,2,3,4} ∩ {3,5,6,7,8} \ {4,5,6,7,8} = {3} \ {4,5,6,7,8} = {3}
      // boxOnly = {1,2,3,4} ∩ {4,5,6,7,8} \ {3,5,6,7,8} = {4} \ {3,5,6,7,8} = {4}
      // accounted = {3,4}, length 2. ✓

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.sueDeCoq);
      expect(step.eliminations, isNotEmpty);

      final elims = step.eliminations;
      // Should eliminate 3 from rest-of-line and/or 4 from rest-of-box.
      final has3Elim = elims.any((e) => e.value == 3 && e.row == 0);
      final has4Elim = elims.any((e) => e.value == 4 && e.col <= 2 && e.row > 0);
      expect(has3Elim || has4Elim, isTrue);
    });

    test('returns null when no pattern exists', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates({1, 2, 3, 4, 5});
      board.getCell(0, 1).setCandidates({1, 2, 3, 4, 5});

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
