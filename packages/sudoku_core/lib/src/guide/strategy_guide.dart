import '../models/difficulty.dart';
import '../solver/strategy_type.dart';

/// A complete step-through walkthrough for one solving strategy.
class StrategyGuide {
  /// Which strategy this guide teaches.
  final StrategyType strategy;

  /// Which difficulty tier this strategy belongs to.
  final Difficulty difficulty;

  /// One-sentence description of what the strategy is.
  final String intro;

  /// 9×9 grid of placed digits (0 = empty).
  final List<List<int>> board;

  /// Candidate sets for each cell, stored as a flat list of 81 entries
  /// in row-major order. Each entry is the set of candidate digits for
  /// that cell (empty set for cells with placed digits).
  final List<Set<int>> candidates;

  /// Ordered walkthrough steps. Step 0 is implicit (shows initial board
  /// with [intro] as caption).
  final List<GuideStep> steps;

  const StrategyGuide({
    required this.strategy,
    required this.difficulty,
    required this.intro,
    required this.board,
    required this.candidates,
    required this.steps,
  });
}

/// One step in a strategy walkthrough.
class GuideStep {
  /// What's happening at this step, in plain language.
  final String caption;

  /// Cells to highlight (the pattern being shown).
  final Set<(int, int)> highlightCells;

  /// Specific candidates to accent - (row, col, digit).
  final Set<(int, int, int)> highlightCandidates;

  /// Candidates being eliminated at this step - (row, col, digit).
  final Set<(int, int, int)> eliminateCandidates;

  /// Digits being placed at this step - (row, col, digit).
  final Set<(int, int, int)> placeCells;

  /// Cells to mark as blocked/eliminated (red background).
  final Set<(int, int)> blockedCells;

  /// Cells colored with color A (e.g., blue for Simple Coloring chains).
  final Set<(int, int)> colorACells;

  /// Cells colored with color B (e.g., amber for Simple Coloring chains).
  final Set<(int, int)> colorBCells;

  const GuideStep({
    required this.caption,
    this.highlightCells = const {},
    this.highlightCandidates = const {},
    this.eliminateCandidates = const {},
    this.placeCells = const {},
    this.blockedCells = const {},
    this.colorACells = const {},
    this.colorBCells = const {},
  });
}
