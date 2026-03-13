import '../../models/board.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// XYZ-Wing: A pivot cell with candidates {X, Y, Z} sees two pincer cells:
/// one with {X, Z} and one with {Y, Z}. Any cell that sees all three
/// (pivot + both pincers) can have Z eliminated.
class XYZWing extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Find all tri-value cells (exactly 3 candidates) as potential pivots.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final pivot = board.getCell(r, c);
        if (pivot.isFilled || pivot.candidates.length != 3) continue;

        final pivotCands = pivot.candidates.toList()..sort();
        final peers = board.peers(r, c);
        final peerBiCells =
            peers.where((p) => p.isEmpty && p.candidates.length == 2).toList();

        // Try all pairs of bi-value peers.
        for (var i = 0; i < peerBiCells.length; i++) {
          final p1 = peerBiCells[i];
          // p1 must be a subset of pivot's candidates.
          if (!p1.candidates.every((v) => pivot.candidates.contains(v))) {
            continue;
          }

          for (var j = i + 1; j < peerBiCells.length; j++) {
            final p2 = peerBiCells[j];
            if (!p2.candidates.every((v) => pivot.candidates.contains(v))) {
              continue;
            }

            // The union of p1 and p2 candidates must equal pivot's candidates.
            final union = p1.candidates.union(p2.candidates);
            if (union.length != 3 ||
                !union.every((v) => pivot.candidates.contains(v))) {
              continue;
            }

            // Z is the common candidate between p1 and p2.
            final common = p1.candidates.intersection(p2.candidates);
            if (common.length != 1) continue;
            final z = common.first;

            // Eliminate Z from cells that see pivot, p1, AND p2.
            final pivotPeers = board.peers(r, c).toSet();
            final p1Peers = board.peers(p1.row, p1.col).toSet();
            final p2Peers = board.peers(p2.row, p2.col).toSet();
            final commonPeers =
                pivotPeers.intersection(p1Peers).intersection(p2Peers);

            final eliminations = <Elimination>[];
            for (final cell in commonPeers) {
              if (cell == p1 || cell == p2) continue;
              if (cell.candidates.contains(z)) {
                eliminations.add(Elimination(cell.row, cell.col, z));
              }
            }

            if (eliminations.isEmpty) continue;

            return SolveStep(
              strategy: StrategyType.xyzWing,
              eliminations: eliminations,
              involvedCells: [
                (row: r, col: c),
                (row: p1.row, col: p1.col),
                (row: p2.row, col: p2.col),
              ],
              description:
                  'XYZ-Wing: pivot R${r + 1}C${c + 1} '
                  '{${pivotCands.join(",")}}, pincers '
                  'R${p1.row + 1}C${p1.col + 1} and '
                  'R${p2.row + 1}C${p2.col + 1} → eliminate $z',
            );
          }
        }
      }
    }
    return null;
  }
}
