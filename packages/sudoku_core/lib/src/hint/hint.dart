import '../solver/solve_step.dart';

/// The level of detail a hint reveals.
enum HintLevel {
  /// A vague nudge - region and digit only.
  /// e.g., "Look for 3 in box 4"
  nudge,

  /// Strategy name and region.
  /// e.g., "Try using X-Wing on rows 2 and 7"
  strategy,

  /// The exact answer.
  /// e.g., "Place 3 at R4C5" or "Eliminate 7 from R2C3"
  answer,
}

/// A multi-layer hint derived from a [SolveStep].
///
/// Each layer reveals progressively more information. The UI should
/// present layers one at a time, requiring deliberate action to reveal
/// the next level.
class Hint {
  /// The underlying solve step this hint is based on.
  final SolveStep step;

  /// Layer 1: a vague directional nudge.
  final String nudge;

  /// Layer 2: the strategy and where to apply it.
  final String strategyHint;

  /// Layer 3: the exact action to take.
  final String answer;

  const Hint({
    required this.step,
    required this.nudge,
    required this.strategyHint,
    required this.answer,
  });

  /// Returns the hint text for the given [level].
  String textForLevel(HintLevel level) {
    return switch (level) {
      HintLevel.nudge => nudge,
      HintLevel.strategy => strategyHint,
      HintLevel.answer => answer,
    };
  }
}
