import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  final strategy = XChain();

  group('X-Chain', () {
    test('finds elimination via 4-link chain', () {
      final board = Board.empty();

      // Build a 4-link chain of conjugate pairs for value 4.
      // Chain: (0,0) -col0- (8,0) -row8- (8,7) -col7- (3,7) -row3- (3,2)
      // 4 links (even) → cells seeing both (0,0) and (3,2) can eliminate 4.

      // Col 0: 4 at (0,0) and (8,0) only.
      board.getCell(0, 0).setCandidates(CandidateSet.of([4, 1]));
      board.getCell(8, 0).setCandidates(CandidateSet.of([4, 2]));

      // Row 8: 4 at (8,0) and (8,7) only.
      board.getCell(8, 7).setCandidates(CandidateSet.of([4, 3]));

      // Col 7: 4 at (8,7) and (3,7) only.
      board.getCell(3, 7).setCandidates(CandidateSet.of([4, 5]));

      // Row 3: 4 at (3,7) and (3,2) only.
      board.getCell(3, 2).setCandidates(CandidateSet.of([4, 6]));

      // Target: (0,2) sees (0,0) via row 0 and (3,2) via col 2.
      board.getCell(0, 2).setCandidates(CandidateSet.of([4, 9]));

      // Prevent (0,2) from creating conjugate pairs (which would short-circuit):
      // Add extra cells with 4 in row 0 and col 2 so there are >2 cells with 4.
      board.getCell(0, 5).setCandidates(CandidateSet.of([4, 8])); // row 0 now has 3 cells with 4
      board.getCell(6, 2).setCandidates(CandidateSet.of([4, 7])); // col 2 now has 3 cells with 4

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.xChain);
      expect(step.eliminations, isNotEmpty);

      final hasElim = step.eliminations
          .any((e) => e.row == 0 && e.col == 2 && e.value == 4);
      expect(hasElim, isTrue);
    });

    test('returns null with insufficient conjugate pairs', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates(CandidateSet.of([4, 1]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([4, 2]));

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
