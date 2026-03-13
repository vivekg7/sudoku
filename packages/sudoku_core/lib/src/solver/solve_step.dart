import 'strategy_type.dart';

/// A single candidate elimination: remove [value] from cell at ([row], [col]).
class Elimination {
  final int row;
  final int col;
  final int value;

  const Elimination(this.row, this.col, this.value);

  @override
  bool operator ==(Object other) =>
      other is Elimination &&
      row == other.row &&
      col == other.col &&
      value == other.value;

  @override
  int get hashCode => Object.hash(row, col, value);

  @override
  String toString() => 'Eliminate $value from R${row + 1}C${col + 1}';
}

/// A value placement: set cell at ([row], [col]) to [value].
class Placement {
  final int row;
  final int col;
  final int value;

  const Placement(this.row, this.col, this.value);

  @override
  bool operator ==(Object other) =>
      other is Placement &&
      row == other.row &&
      col == other.col &&
      value == other.value;

  @override
  int get hashCode => Object.hash(row, col, value);

  @override
  String toString() => 'Place $value at R${row + 1}C${col + 1}';
}

/// Describes one logical step the solver found.
class SolveStep {
  /// Which strategy produced this step.
  final StrategyType strategy;

  /// Values placed by this step (typically 0 or 1).
  final List<Placement> placements;

  /// Candidates eliminated by this step.
  final List<Elimination> eliminations;

  /// Cells that are "involved" in the pattern (for highlighting in UI).
  /// E.g., the two cells forming a naked pair.
  final List<({int row, int col})> involvedCells;

  /// Human-readable description of what was found.
  final String description;

  const SolveStep({
    required this.strategy,
    this.placements = const [],
    this.eliminations = const [],
    this.involvedCells = const [],
    this.description = '',
  });

  @override
  String toString() => '${strategy.label}: $description';
}
