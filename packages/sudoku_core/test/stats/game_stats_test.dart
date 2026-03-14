import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('GameStats', () {
    GameStats sample() => GameStats(
          id: 'game-1',
          difficulty: Difficulty.medium,
          solveTimeSeconds: 300,
          completed: true,
          hintsByLevel: {HintLevel.nudge: 2, HintLevel.answer: 1},
          hintsByStrategy: {StrategyType.nakedSingle: 2, StrategyType.xWing: 1},
          playedAt: DateTime(2026, 3, 14),
          puzzleId: 'puzzle-abc',
        );

    test('totalHints sums across levels', () {
      expect(sample().totalHints, 3);
    });

    test('usedHints is true when hints taken', () {
      expect(sample().usedHints, isTrue);
    });

    test('usedHints is false when no hints', () {
      final stats = GameStats(
        id: 'g',
        difficulty: Difficulty.beginner,
        solveTimeSeconds: 60,
        completed: true,
        playedAt: DateTime(2026),
      );
      expect(stats.usedHints, isFalse);
    });

    test('JSON round-trip preserves all fields', () {
      final original = sample();
      final json = original.toJson();
      final restored = GameStats.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.difficulty, original.difficulty);
      expect(restored.solveTimeSeconds, original.solveTimeSeconds);
      expect(restored.completed, original.completed);
      expect(restored.hintsByLevel, original.hintsByLevel);
      expect(restored.hintsByStrategy, original.hintsByStrategy);
      expect(restored.playedAt, original.playedAt);
      expect(restored.puzzleId, original.puzzleId);
    });
  });
}
