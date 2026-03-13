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
  final Set<int> previousCandidates;

  /// Candidates after the move.
  final Set<int> newCandidates;

  const Move({
    required this.row,
    required this.col,
    required this.type,
    this.previousValue = 0,
    this.newValue = 0,
    this.previousCandidates = const {},
    this.newCandidates = const {},
  });

  @override
  String toString() =>
      'Move($type, R${row + 1}C${col + 1}, $previousValue→$newValue)';
}
