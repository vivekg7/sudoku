import 'dart:math';

import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('PuzzleGenerator', () {
    late PuzzleGenerator generator;

    setUp(() {
      // Fixed seed for reproducible tests.
      generator = PuzzleGenerator(random: Random(42));
    });

    test('generates a valid beginner puzzle', () {
      final puzzle = generator.generate(Difficulty.beginner);

      expect(puzzle, isNotNull);
      expect(puzzle!.difficulty, Difficulty.beginner);
      expect(puzzle.solution.isSolved, isTrue);
      expect(puzzle.initialBoard.isValid, isTrue);
      expect(puzzle.board.isValid, isTrue);
    });

    test('generates a valid easy puzzle', () {
      final puzzle = generator.generate(Difficulty.easy);

      expect(puzzle, isNotNull);
      expect(puzzle!.difficulty, Difficulty.easy);
      expect(puzzle.solution.isSolved, isTrue);
    });

    test('generated puzzle has a unique solution', () {
      final puzzle = generator.generate(Difficulty.beginner);
      expect(puzzle, isNotNull);

      final testBoard = puzzle!.initialBoard.clone();
      computeCandidates(testBoard);
      final solutions = Backtracking.countSolutions(testBoard, limit: 2);

      expect(solutions, equals(1));
    });

    test('generated puzzle solution matches solver result', () {
      final puzzle = generator.generate(Difficulty.beginner);
      expect(puzzle, isNotNull);

      final solver = Solver();
      final result = solver.solve(puzzle!.initialBoard);

      expect(result.isSolved, isTrue);
    });

    test('initial board has givens marked correctly', () {
      final puzzle = generator.generate(Difficulty.beginner);
      expect(puzzle, isNotNull);

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final cell = puzzle!.initialBoard.getCell(r, c);
          if (cell.isFilled) {
            expect(cell.isGiven, isTrue,
                reason: 'Filled cell at ($r,$c) should be a given');
          }
        }
      }
    });

    test('puzzle board starts as a copy of initial board', () {
      final puzzle = generator.generate(Difficulty.beginner);
      expect(puzzle, isNotNull);

      expect(
        puzzle!.board.toFlatString(),
        equals(puzzle.initialBoard.toFlatString()),
      );
    });

    test('puzzle has rotational symmetry in givens', () {
      final puzzle = generator.generate(Difficulty.beginner);
      expect(puzzle, isNotNull);

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final cell = puzzle!.initialBoard.getCell(r, c);
          final mirror = puzzle.initialBoard.getCell(8 - r, 8 - c);
          expect(
            cell.isFilled,
            equals(mirror.isFilled),
            reason:
                'Symmetry broken: ($r,$c) is ${cell.isFilled ? "filled" : "empty"} '
                'but (${8 - r},${8 - c}) is ${mirror.isFilled ? "filled" : "empty"}',
          );
        }
      }
    });

    test('generateBatch returns requested number of puzzles', () {
      final puzzles = generator.generateBatch(3, Difficulty.beginner);

      expect(puzzles.length, equals(3));
      for (final puzzle in puzzles) {
        expect(puzzle.difficulty, Difficulty.beginner);
        expect(puzzle.solution.isSolved, isTrue);
      }
    });

    test('different seeds produce different puzzles', () {
      final gen1 = PuzzleGenerator(random: Random(1));
      final gen2 = PuzzleGenerator(random: Random(2));

      final p1 = gen1.generate(Difficulty.beginner);
      final p2 = gen2.generate(Difficulty.beginner);

      expect(p1, isNotNull);
      expect(p2, isNotNull);
      // Extremely unlikely to be identical with different seeds.
      expect(
        p1!.solution.toFlatString(),
        isNot(equals(p2!.solution.toFlatString())),
      );
    });

    test('generated puzzle has reasonable number of givens', () {
      final puzzle = generator.generate(Difficulty.beginner);
      expect(puzzle, isNotNull);

      var givenCount = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (puzzle!.initialBoard.getCell(r, c).isFilled) givenCount++;
        }
      }

      // A valid puzzle typically has 17–36 givens.
      expect(givenCount, greaterThanOrEqualTo(17));
      expect(givenCount, lessThanOrEqualTo(50));
    });
  });
}
