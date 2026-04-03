import '../models/board.dart';
import '../models/candidate_set.dart';

/// Returns `true` if every empty cell has at least one candidate.
///
/// Used to detect whether the user has filled in pencil marks. If any
/// empty cell has zero candidates, candidates are considered incomplete.
bool areCandidatesComplete(Board board) {
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final cell = board.getCell(r, c);
      if (cell.isEmpty && cell.candidates.isEmpty) return false;
    }
  }
  return true;
}

/// Fills in candidates for all empty cells based on current board state.
/// A candidate is valid if no peer has that value.
void computeCandidates(Board board) {
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final cell = board.getCell(r, c);
      if (cell.isFilled) continue;

      // Build a bitmask of values used by peers.
      var usedBits = 0;
      for (final peer in board.peers(r, c)) {
        if (peer.isFilled) usedBits |= 1 << peer.value;
      }

      // Candidates = all digits 1-9 not in usedBits.
      // Bits 1-9 all set = 0x3FE.
      final candidateBits = 0x3FE & ~usedBits;
      cell.setCandidates(CandidateSet(candidateBits));
    }
  }
}
