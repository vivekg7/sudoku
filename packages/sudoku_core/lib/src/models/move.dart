import 'candidate_set.dart';

/// The type of action a move represents.
enum MoveType {
  setValue,
  clearValue,
  addCandidate,
  removeCandidate,
  setCandidates,
}

/// A single reversible action on a cell.
class Move {
  final int row;
  final int col;
  final MoveType type;

  /// The value before the move (for undo).
  final int previousValue;

  /// The value after the move.
  final int newValue;

  /// Candidates before the move (for undo).
  final CandidateSet previousCandidates;

  /// Candidates after the move.
  final CandidateSet newCandidates;

  /// Candidates auto-removed from peer cells (for undo).
  /// Each entry is (row, col, value).
  final List<(int, int, int)> removedPeerCandidates;

  Move({
    required this.row,
    required this.col,
    required this.type,
    this.previousValue = 0,
    this.newValue = 0,
    CandidateSet? previousCandidates,
    CandidateSet? newCandidates,
    this.removedPeerCandidates = const [],
  })  : previousCandidates = previousCandidates ?? CandidateSet(),
        newCandidates = newCandidates ?? CandidateSet();

  @override
  String toString() =>
      'Move($type, R${row + 1}C${col + 1}, $previousValue→$newValue)';
}
