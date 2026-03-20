import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

// A solved board string for testing.
const _solvedFlat = '534678912'
    '672195348'
    '198342567'
    '859761423'
    '426853791'
    '713924856'
    '961537284'
    '287419635'
    '345286179';

// A partial board (with some cells empty).
const _partialFlat = '530070000'
    '600195000'
    '098000060'
    '800060003'
    '400803001'
    '700020006'
    '060000280'
    '000419005'
    '000080079';

Puzzle _makePuzzle() {
  final initial = Board.fromString(_partialFlat);
  final solution = Board.fromString(_solvedFlat);
  final board = initial.clone();
  return Puzzle(
    initialBoard: initial,
    solution: solution,
    board: board,
    difficulty: Difficulty.beginner,
  );
}

void main() {
  group('PuzzleEntry', () {
    test('JSON round-trip preserves all fields', () {
      final entry = PuzzleEntry(
        id: 'p-1',
        puzzle: _makePuzzle(),
        bookmarked: true,
        savedAt: DateTime(2026, 3, 14),
      );

      final json = entry.toJson();
      final restored = PuzzleEntry.fromJson(json);

      expect(restored.id, 'p-1');
      expect(restored.bookmarked, isTrue);
      expect(restored.savedAt, DateTime(2026, 3, 14));
      expect(restored.puzzle.difficulty, Difficulty.beginner);
      expect(
        restored.puzzle.initialBoard.toFlatString(),
        entry.puzzle.initialBoard.toFlatString(),
      );
      expect(
        restored.puzzle.solution.toFlatString(),
        entry.puzzle.solution.toFlatString(),
      );
    });

    test('round-trip preserves current board state', () {
      final puzzle = _makePuzzle();
      // Simulate player filling in a cell.
      puzzle.board.getCell(0, 2).setValue(4);

      final entry = PuzzleEntry(id: 'p-2', puzzle: puzzle);
      final json = entry.toJson();
      final restored = PuzzleEntry.fromJson(json);

      expect(restored.puzzle.board.getCell(0, 2).value, 4);
    });

    test('round-trip preserves given status', () {
      final entry = PuzzleEntry(id: 'p-3', puzzle: _makePuzzle());
      final json = entry.toJson();
      final restored = PuzzleEntry.fromJson(json);

      // Cell (0,0) has value 5 in initial board - should be a given.
      expect(restored.puzzle.initialBoard.getCell(0, 0).isGiven, isTrue);
      // Cell (0,2) is empty in initial board - should not be a given.
      expect(restored.puzzle.initialBoard.getCell(0, 2).isGiven, isFalse);
    });
  });

  group('PuzzleStore', () {
    late PuzzleStore store;

    setUp(() {
      store = PuzzleStore();
    });

    test('starts empty', () {
      expect(store.entries, isEmpty);
    });

    test('save and load', () {
      final entry = PuzzleEntry(id: 'p-1', puzzle: _makePuzzle());
      store.save(entry);

      expect(store.entries.length, 1);
      expect(store.load('p-1'), isNotNull);
      expect(store.load('p-1')!.id, 'p-1');
    });

    test('remove', () {
      store.save(PuzzleEntry(id: 'p-1', puzzle: _makePuzzle()));
      store.remove('p-1');

      expect(store.entries, isEmpty);
      expect(store.load('p-1'), isNull);
    });

    test('toggleBookmark', () {
      store.save(PuzzleEntry(id: 'p-1', puzzle: _makePuzzle()));

      expect(store.load('p-1')!.bookmarked, isFalse);

      store.toggleBookmark('p-1');
      expect(store.load('p-1')!.bookmarked, isTrue);

      store.toggleBookmark('p-1');
      expect(store.load('p-1')!.bookmarked, isFalse);
    });

    test('inProgress filters unsolved, non-bookmarked', () {
      store.save(PuzzleEntry(id: 'p-1', puzzle: _makePuzzle()));
      store.save(PuzzleEntry(
        id: 'p-2',
        puzzle: _makePuzzle(),
        bookmarked: true,
      ));

      expect(store.inProgress.length, 1);
      expect(store.inProgress.first.id, 'p-1');
    });

    test('bookmarked filters bookmarked puzzles', () {
      store.save(PuzzleEntry(id: 'p-1', puzzle: _makePuzzle()));
      store.save(PuzzleEntry(
        id: 'p-2',
        puzzle: _makePuzzle(),
        bookmarked: true,
      ));

      expect(store.bookmarked.length, 1);
      expect(store.bookmarked.first.id, 'p-2');
    });

    test('JSON round-trip preserves all entries', () {
      store.save(PuzzleEntry(id: 'p-1', puzzle: _makePuzzle()));
      store.save(PuzzleEntry(
        id: 'p-2',
        puzzle: _makePuzzle(),
        bookmarked: true,
      ));

      final json = store.toJson();
      final restored = PuzzleStore.fromJson(json);

      expect(restored.entries.length, 2);
      expect(restored.load('p-2')!.bookmarked, isTrue);
    });
  });
}
