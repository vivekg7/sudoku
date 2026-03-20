import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

import 'strategy_test_helper.dart';

void main() {
  group('NakedSingle', () {
    final strategy = NakedSingle();

    test('finds cell with only one candidate', () {
      // Almost-complete row 1: only R1C9 is empty, must be 2.
      final board = boardWithCandidates(
        '534678910' // R1: missing 2 at col 8 (index 8)
        '672195348'
        '198342567'
        '859761423'
        '426853791'
        '713924856'
        '961537284'
        '287419635'
        '345286179',
      );

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.nakedSingle);
      expect(step.placements.length, 1);
      expect(step.placements.first.row, 0);
      expect(step.placements.first.col, 8);
      expect(step.placements.first.value, 2);
    });

    test('returns null when no naked single exists', () {
      // A puzzle with many empty cells - no naked singles at start.
      final board = boardWithCandidates(
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000',
      );

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
