import '../../models/board.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// Forcing Chains: Pick a cell with N candidates. Assume each candidate
/// in turn and propagate (naked/hidden singles only). If all assumptions
/// lead to the same conclusion for some other cell, that conclusion is valid.
class ForcingChain extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Find cells with 2-3 candidates (keep it manageable).
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;
        if (cell.candidates.length < 2 || cell.candidates.length > 3) continue;

        // For each candidate, propagate and record forced values.
        final outcomes = <int, Map<(int, int), int>>{};

        for (final v in cell.candidates) {
          final result = _propagate(board, r, c, v);
          if (result == null) {
            // Contradiction! This candidate is impossible → eliminate it.
            return SolveStep(
              strategy: StrategyType.forcingChain,
              eliminations: [Elimination(r, c, v)],
              involvedCells: [(row: r, col: c)],
              description:
                  'Forcing Chain: assuming $v at R${r + 1}C${c + 1} '
                  'leads to contradiction → eliminate $v',
            );
          }
          outcomes[v] = result;
        }

        // Check if all branches agree on some cell's value.
        if (outcomes.length < 2) continue;

        final firstOutcome = outcomes.values.first;
        for (final entry in firstOutcome.entries) {
          final pos = entry.key;
          final value = entry.value;

          final allAgree = outcomes.values.every(
            (o) => o.containsKey(pos) && o[pos] == value,
          );

          if (allAgree) {
            final targetCell = board.getCell(pos.$1, pos.$2);
            if (targetCell.isFilled) continue;

            // All branches force the same value.
            return SolveStep(
              strategy: StrategyType.forcingChain,
              placements: [Placement(pos.$1, pos.$2, value)],
              involvedCells: [
                (row: r, col: c),
                (row: pos.$1, col: pos.$2),
              ],
              description:
                  'Forcing Chain: all candidates at R${r + 1}C${c + 1} '
                  'force $value at R${pos.$1 + 1}C${pos.$2 + 1}',
            );
          }
        }

        // Check if all branches eliminate a candidate from some cell.
        final firstElims = _getEliminations(board, outcomes.values.first);
        for (final elim in firstElims) {
          final allEliminate = outcomes.values.every((o) {
            // Cell is filled with a different value, or candidate is gone.
            if (o.containsKey((elim.row, elim.col))) {
              return o[(elim.row, elim.col)] != elim.value;
            }
            return false;
          });

          if (allEliminate) {
            return SolveStep(
              strategy: StrategyType.forcingChain,
              eliminations: [elim],
              involvedCells: [(row: r, col: c)],
              description:
                  'Forcing Chain: all candidates at R${r + 1}C${c + 1} '
                  'eliminate ${elim.value} from '
                  'R${elim.row + 1}C${elim.col + 1}',
            );
          }
        }
      }
    }
    return null;
  }

  /// Propagate simple singles from assuming [value] at ([row], [col]).
  /// Returns a map of (row, col) → forced value, or null on contradiction.
  Map<(int, int), int>? _propagate(Board board, int row, int col, int value) {
    final clone = board.clone();
    final forced = <(int, int), int>{};

    // Set the assumed value.
    clone.getCell(row, col).setValue(value);
    forced[(row, col)] = value;

    // Remove candidate from peers.
    for (final peer in clone.peers(row, col)) {
      peer.removeCandidate(value);
    }

    // Iterate until no more singles.
    var changed = true;
    while (changed) {
      changed = false;

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final cell = clone.getCell(r, c);
          if (cell.isFilled) continue;

          // Naked single.
          if (cell.candidates.isEmpty) return null; // contradiction
          if (cell.candidates.length == 1) {
            final v = cell.candidates.first;
            cell.setValue(v);
            forced[(r, c)] = v;
            for (final peer in clone.peers(r, c)) {
              peer.removeCandidate(v);
            }
            changed = true;
            continue;
          }

          // Hidden single in each house.
          for (final v in cell.candidates.toList()) {
            final row2 = clone.getRow(r);
            final col2 = clone.getColumn(c);
            final box2 = clone.getBox(cell.box);

            for (final house in [row2, col2, box2]) {
              final others = house.where(
                (h) =>
                    h.isEmpty &&
                    h.candidates.contains(v) &&
                    !(h.row == r && h.col == c),
              );
              if (others.isEmpty) {
                // v can only go here.
                cell.setValue(v);
                forced[(r, c)] = v;
                for (final peer in clone.peers(r, c)) {
                  peer.removeCandidate(v);
                }
                changed = true;
                break;
              }
            }
            if (cell.isFilled) break;
          }
        }
      }
    }

    // Check for contradictions.
    if (!clone.isValid) return null;

    return forced;
  }

  List<Elimination> _getEliminations(
      Board original, Map<(int, int), int> outcome) {
    final elims = <Elimination>[];
    for (final entry in outcome.entries) {
      final (r, c) = entry.key;
      final cell = original.getCell(r, c);
      if (cell.isFilled) continue;
      for (final v in cell.candidates) {
        if (v != entry.value) {
          elims.add(Elimination(r, c, v));
        }
      }
    }
    return elims;
  }
}
