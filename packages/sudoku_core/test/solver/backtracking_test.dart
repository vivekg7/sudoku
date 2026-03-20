import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

import 'strategy_test_helper.dart';

void main() {
  group('Backtracking', () {
    final strategy = Backtracking();

    test('solves a near-complete puzzle', () {
      // A valid sudoku with just a few cells missing.
      final flat =
          '534678912'
          '672195348'
          '198342567'
          '859761423'
          '426853791'
          '713924856'
          '961537284'
          '287419635'
          '345286170'; // (8,8) = 0 → missing 9
      final board = boardWithCandidates(flat);

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.backtracking);
      expect(step.placements, hasLength(1));
      expect(step.placements.first.row, 8);
      expect(step.placements.first.col, 8);
      expect(step.placements.first.value, 9);
    });

    test('returns null for already solved board', () {
      final flat =
          '534678912'
          '672195348'
          '198342567'
          '859761423'
          '426853791'
          '713924856'
          '961537284'
          '287419635'
          '345286179';
      final board = Board.fromString(flat);

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });

  group('countSolutions', () {
    test('returns 1 for a valid puzzle with unique solution', () {
      final flat =
          '530070000'
          '600195000'
          '098000060'
          '800060003'
          '400803001'
          '700020006'
          '060000280'
          '000419005'
          '000080079';
      final board = boardWithCandidates(flat);

      final count = Backtracking.countSolutions(board);
      expect(count, 1);
    });

    test('returns 0 for an invalid board', () {
      // Take a nearly solved board and place a conflicting value to make
      // it unsolvable. Two missing cells but conflicting constraints.
      final flat =
          '534678912'
          '672195348'
          '198342567'
          '859761423'
          '426853791'
          '713924856'
          '961537284'
          '287419630' // (7,8) missing - should be 5
          '345286070'; // (8,6) missing - should be 1, (8,8) missing - should be 9
      final board = boardWithCandidates(flat);
      // Force (7,8) to an invalid value to create contradiction.
      board.getCell(7, 8).setValue(1); // conflicts: 1 already in col 8 at (4,8)
      // Now (8,6) and (8,8) can't be filled consistently.
      computeCandidates(board);

      final count = Backtracking.countSolutions(board);
      expect(count, 0);
    });
  });
}
