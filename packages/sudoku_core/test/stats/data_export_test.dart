import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

const _solvedFlat = '534678912'
    '672195348'
    '198342567'
    '859761423'
    '426853791'
    '713924856'
    '961537284'
    '287419635'
    '345286179';

const _partialFlat = '530070000'
    '600195000'
    '098000060'
    '800060003'
    '400803001'
    '700020006'
    '060000280'
    '000419005'
    '000080079';

void main() {
  group('DataExport', () {
    test('full round-trip: stats + puzzles', () {
      final stats = StatsStore();
      stats.record(GameStats(
        id: 'g-1',
        difficulty: Difficulty.medium,
        solveTimeSeconds: 250,
        completed: true,
        hintsByLevel: {HintLevel.nudge: 1},
        playedAt: DateTime(2026, 3, 14),
      ));

      final puzzles = PuzzleStore();
      puzzles.save(PuzzleEntry(
        id: 'p-1',
        puzzle: Puzzle(
          initialBoard: Board.fromString(_partialFlat),
          solution: Board.fromString(_solvedFlat),
          board: Board.fromString(_partialFlat),
          difficulty: Difficulty.beginner,
        ),
        bookmarked: true,
      ));

      final export = DataExport(stats: stats, puzzles: puzzles);
      final jsonString = export.toJsonString();

      // Verify it's valid JSON.
      expect(jsonString, contains('"version": 1'));

      // Round-trip.
      final restored = DataExport.fromJsonString(jsonString);

      expect(restored.stats.totalGames, 1);
      expect(restored.stats.games.first.id, 'g-1');
      expect(restored.stats.games.first.difficulty, Difficulty.medium);

      expect(restored.puzzles.entries.length, 1);
      expect(restored.puzzles.load('p-1')!.bookmarked, isTrue);
    });

    test('empty data round-trips', () {
      final export = DataExport(
        stats: StatsStore(),
        puzzles: PuzzleStore(),
      );
      final jsonString = export.toJsonString();
      final restored = DataExport.fromJsonString(jsonString);

      expect(restored.stats.totalGames, 0);
      expect(restored.puzzles.entries, isEmpty);
    });
  });
}
