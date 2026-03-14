import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  final strategy = ForcingChain();

  group('Forcing Chain', () {
    test('finds forced value when all branches agree', () {
      final board = Board.empty();

      // Cell (0,0) has {1,2}. If we set 1, all peers lose 1.
      // Cell (0,1) has {1} only → setting (0,0)=1 removes 1 from (0,1) → empty → contradiction.
      // So candidate 1 at (0,0) leads to contradiction → eliminate 1.
      board.getCell(0, 0).setCandidates(CandidateSet.of([1, 2]));
      board.getCell(0, 1).setCandidates(CandidateSet.of([1])); // only candidate is 1

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.forcingChain);

      // Should eliminate 1 from (0,0) due to contradiction.
      expect(step.eliminations, isNotEmpty);
      final elim = step.eliminations.first;
      expect(elim.row, 0);
      expect(elim.col, 0);
      expect(elim.value, 1);
    });

    test('returns null when no forcing chain exists', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates(CandidateSet.of([1, 2, 3, 4]));
      board.getCell(0, 1).setCandidates(CandidateSet.of([5, 6, 7, 8]));

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
