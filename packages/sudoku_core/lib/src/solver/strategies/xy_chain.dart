import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';
import '../strategy_utils.dart';

/// XY-Chain: A chain of bi-value cells where each consecutive pair
/// shares a candidate (weak link) and the other candidate is the
/// strong link within the cell. If a cell sees both endpoints of the
/// chain, it can eliminate the candidate that the endpoints agree on.
class XYChain extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Collect all bi-value cells.
    final biCells = <Cell>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isEmpty && cell.candidates.length == 2) {
          biCells.add(cell);
        }
      }
    }

    if (biCells.length < 3) return null;

    // Build adjacency: two bi-value cells are linked if they are peers
    // and share exactly one candidate.
    final peers = <Cell, List<Cell>>{};
    for (final cell in biCells) {
      peers[cell] = biCells.where((other) {
        if (other == cell) return false;
        if (!isPeer(cell.row, cell.col, other.row, other.col)) return false;
        return cell.candidates.intersection(other.candidates).length == 1;
      }).toList();
    }

    // DFS from each cell to find chains where the first candidate of
    // the start equals the last candidate of the end.
    for (final start in biCells) {
      final startCands = start.candidates.toList();

      for (final startValue in startCands) {
        // startValue is the "free" end of the chain at the start.
        // We need to find a chain ending with startValue as the free end too.
        final otherValue =
            startCands[0] == startValue ? startCands[1] : startCands[0];

        // DFS: track current cell, the candidate we entered with (the
        // shared one), and visited cells.
        final result = _dfs(
          board,
          start,
          otherValue, // the candidate we "use" to link to next
          {start},
          [start],
          startValue,
          peers,
        );
        if (result != null) return result;
      }
    }
    return null;
  }

  SolveStep? _dfs(
    Board board,
    Cell current,
    int exitCandidate, // candidate used to link to the next cell
    Set<Cell> visited,
    List<Cell> chain,
    int targetValue, // what the chain endpoint's free value must be
    Map<Cell, List<Cell>> peers,
  ) {
    for (final next in peers[current] ?? <Cell>[]) {
      if (visited.contains(next)) continue;

      // The shared candidate between current and next.
      final shared =
          current.candidates.intersection(next.candidates);
      if (shared.length != 1) continue;
      if (shared.first != exitCandidate) continue;

      // The free candidate of next (the one not shared with current).
      final nextCands = next.candidates.toList();
      final freeValue = nextCands[0] == exitCandidate
          ? nextCands[1]
          : nextCands[0];

      final newChain = [...chain, next];

      // Check if chain is long enough and endpoints match.
      if (newChain.length >= 3 && freeValue == targetValue) {
        // Found a valid XY-Chain. Eliminate targetValue from cells
        // that see both endpoints.
        final start = chain.first;
        final eliminations = <Elimination>[];

        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            final cell = board.getCell(r, c);
            if (cell.isFilled || !cell.candidates.contains(targetValue)) {
              continue;
            }
            if (cell == start || cell == next) continue;
            if (visited.contains(cell)) continue;

            if (isPeer(r, c, start.row, start.col) &&
                isPeer(r, c, next.row, next.col)) {
              eliminations.add(Elimination(r, c, targetValue));
            }
          }
        }

        if (eliminations.isNotEmpty) {
          return SolveStep(
            strategy: StrategyType.xyChain,
            eliminations: eliminations,
            involvedCells:
                newChain.map((c) => (row: c.row, col: c.col)).toList(),
            description:
                'XY-Chain: ${newChain.map((c) => 'R${c.row + 1}C${c.col + 1}').join('→')} '
                '→ eliminate $targetValue',
          );
        }
      }

      // Continue searching deeper (limit depth to avoid explosion).
      if (newChain.length < 8) {
        final result = _dfs(
          board,
          next,
          freeValue, // exit via the free candidate
          {...visited, next},
          newChain,
          targetValue,
          peers,
        );
        if (result != null) return result;
      }
    }
    return null;
  }

}
