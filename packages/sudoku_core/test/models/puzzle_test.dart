import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

const _solvedFlat =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

const _puzzleFlat =
    '530070000600195000098000060800060003400803001700020006060000280000419005000080079';

void main() {
  group('Puzzle', () {
    late Puzzle puzzle;

    setUp(() {
      puzzle = Puzzle(
        initialBoard: Board.fromString(_puzzleFlat),
        solution: Board.fromString(_solvedFlat),
        board: Board.fromString(_puzzleFlat),
        difficulty: Difficulty.medium,
      );
    });

    test('isSolved is false on unsolved board', () {
      expect(puzzle.isSolved, false);
    });

    test('isSolved is true when board matches solution', () {
      final solved = Puzzle(
        initialBoard: Board.fromString(_puzzleFlat),
        solution: Board.fromString(_solvedFlat),
        board: Board.fromString(_solvedFlat),
        difficulty: Difficulty.medium,
      );
      expect(solved.isSolved, true);
    });

    test('emptyCellCount counts unfilled cells', () {
      expect(puzzle.emptyCellCount, greaterThan(0));
    });

    test('totalToFill counts non-given cells', () {
      expect(puzzle.totalToFill, greaterThan(0));
      expect(puzzle.totalToFill, puzzle.emptyCellCount);
    });

    test('has default history and createdAt', () {
      expect(puzzle.history.canUndo, false);
      expect(puzzle.createdAt, isNotNull);
    });
  });

  group('Difficulty', () {
    test('has 6 levels', () {
      expect(Difficulty.values.length, 6);
    });

    test('label capitalises name', () {
      expect(Difficulty.beginner.label, 'Beginner');
      expect(Difficulty.master.label, 'Master');
    });

    test('ordering is correct', () {
      expect(Difficulty.beginner.index < Difficulty.master.index, true);
    });
  });
}
