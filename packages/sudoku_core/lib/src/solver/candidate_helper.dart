import '../models/board.dart';

/// Fills in candidates for all empty cells based on current board state.
/// A candidate is valid if no peer has that value.
void computeCandidates(Board board) {
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final cell = board.getCell(r, c);
      if (cell.isFilled) continue;

      final usedValues = <int>{};
      for (final peer in board.peers(r, c)) {
        if (peer.isFilled) usedValues.add(peer.value);
      }

      final candidates = <int>{};
      for (var v = 1; v <= 9; v++) {
        if (!usedValues.contains(v)) candidates.add(v);
      }
      cell.setCandidates(candidates);
    }
  }
}
