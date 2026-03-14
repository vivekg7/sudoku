import '../hint/hint.dart';
import '../models/difficulty.dart';
import '../solver/strategy_type.dart';

/// Stats recorded for a single completed (or abandoned) game.
class GameStats {
  /// Unique identifier for the game.
  final String id;

  /// Puzzle difficulty.
  final Difficulty difficulty;

  /// Total solve time in seconds.
  final int solveTimeSeconds;

  /// Whether the player completed the puzzle.
  final bool completed;

  /// Hints taken, broken down by layer.
  final Map<HintLevel, int> hintsByLevel;

  /// Hints taken, broken down by strategy type.
  final Map<StrategyType, int> hintsByStrategy;

  /// When the game was played.
  final DateTime playedAt;

  /// The puzzle's initial board as an 81-char flat string (for identification).
  final String puzzleId;

  const GameStats({
    required this.id,
    required this.difficulty,
    required this.solveTimeSeconds,
    required this.completed,
    this.hintsByLevel = const {},
    this.hintsByStrategy = const {},
    required this.playedAt,
    this.puzzleId = '',
  });

  /// Total number of hints taken across all layers.
  int get totalHints =>
      hintsByLevel.values.fold(0, (sum, count) => sum + count);

  /// Whether any hints were used.
  bool get usedHints => totalHints > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'difficulty': difficulty.name,
        'solveTimeSeconds': solveTimeSeconds,
        'completed': completed,
        'hintsByLevel': {
          for (final e in hintsByLevel.entries) e.key.name: e.value,
        },
        'hintsByStrategy': {
          for (final e in hintsByStrategy.entries) e.key.name: e.value,
        },
        'playedAt': playedAt.toIso8601String(),
        'puzzleId': puzzleId,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        id: json['id'] as String,
        difficulty: Difficulty.values.byName(json['difficulty'] as String),
        solveTimeSeconds: json['solveTimeSeconds'] as int,
        completed: json['completed'] as bool,
        hintsByLevel: {
          for (final e
              in (json['hintsByLevel'] as Map<String, dynamic>).entries)
            HintLevel.values.byName(e.key): e.value as int,
        },
        hintsByStrategy: {
          for (final e
              in (json['hintsByStrategy'] as Map<String, dynamic>).entries)
            StrategyType.values.byName(e.key): e.value as int,
        },
        playedAt: DateTime.parse(json['playedAt'] as String),
        puzzleId: (json['puzzleId'] as String?) ?? '',
      );
}
