import '../solver/solve_step.dart';

/// Result of hint generation.
sealed class HintResult {}

/// A normal hint was found.
class HintFound extends HintResult {
  final Hint hint;
  HintFound(this.hint);
}

/// No hint available (puzzle solved or solver stuck).
class HintNotAvailable extends HintResult {}

/// Candidates are incomplete — the user should fill them first for
/// strategy-aware hints. Contains an optional fallback hint that points
/// to the next placement (skipping elimination-only steps).
class HintNeedsCandidates extends HintResult {
  final Hint? placementHint;
  HintNeedsCandidates({this.placementHint});
}

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
