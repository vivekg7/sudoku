import '../models/board.dart';
import 'solve_step.dart';

/// Base interface for all solving strategies.
///
/// Each strategy examines the board and returns a [SolveStep] if it finds
/// an applicable pattern, or `null` if the strategy doesn't apply.
abstract class Strategy {
  /// Try to find one application of this strategy on [board].
  /// Returns a [SolveStep] describing the deduction, or `null`.
  SolveStep? apply(Board board);
}
