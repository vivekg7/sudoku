import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// XY-Wing: A pivot cell with candidates {X, Y} sees two pincer cells:
/// one with {X, Z} and one with {Y, Z}. Any cell that sees both pincers
/// can have Z eliminated.
class XYWing extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Find all bi-value cells (exactly 2 candidates).
    final biCells = <Cell>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isEmpty && cell.candidates.length == 2) {
          biCells.add(cell);
        }
      }
    }

    for (final pivot in biCells) {
      final pivotCands = pivot.candidates.toList();
      final x = pivotCands[0];
      final y = pivotCands[1];

      final peers = board.peers(pivot.row, pivot.col);
      final peerBiCells =
          peers.where((c) => c.isEmpty && c.candidates.length == 2).toList();

      // Find pincer1 with {X, Z} and pincer2 with {Y, Z}.
      for (var i = 0; i < peerBiCells.length; i++) {
        final p1 = peerBiCells[i];
        if (!p1.candidates.contains(x)) continue;
        final z1 = p1.candidates.firstWhere((v) => v != x);
        if (z1 == y) continue; // would be {X, Y} again

        for (var j = i + 1; j < peerBiCells.length; j++) {
          final p2 = peerBiCells[j];
          if (!p2.candidates.contains(y)) continue;
          final z2 = p2.candidates.firstWhere((v) => v != y);
          if (z2 != z1) continue; // Z must match

          final z = z1;

          // Eliminate Z from cells that see both pincers.
          final p1Peers = board.peers(p1.row, p1.col).toSet();
          final p2Peers = board.peers(p2.row, p2.col).toSet();
          final commonPeers = p1Peers.intersection(p2Peers);

          final eliminations = <Elimination>[];
          for (final cell in commonPeers) {
            if (cell == pivot) continue;
            if (cell.candidates.contains(z)) {
              eliminations.add(Elimination(cell.row, cell.col, z));
            }
          }

          if (eliminations.isEmpty) continue;

          return SolveStep(
            strategy: StrategyType.xyWing,
            eliminations: eliminations,
            involvedCells: [
              (row: pivot.row, col: pivot.col),
              (row: p1.row, col: p1.col),
              (row: p2.row, col: p2.col),
            ],
            description:
                'XY-Wing: pivot R${pivot.row + 1}C${pivot.col + 1} '
                '{$x,$y}, pincers R${p1.row + 1}C${p1.col + 1} '
                '{$x,$z} and R${p2.row + 1}C${p2.col + 1} {$y,$z} '
                '→ eliminate $z',
          );
        }
      }
    }
    return null;
  }
}
