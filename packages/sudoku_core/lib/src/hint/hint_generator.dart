import '../models/board.dart';
import '../solver/candidate_helper.dart';
import '../solver/solve_step.dart';
import '../solver/solver_engine.dart';
import '../solver/strategy_type.dart';
import 'hint.dart';

/// Generates multi-layer hints for the current board state.
///
/// Uses the [Solver] to find the next logical step, then extracts
/// three progressively detailed hint layers from it.
///
/// Handles two scenarios:
/// - **Candidates incomplete**: prompts the user to fill candidates, with
///   a fallback hint pointing to the next placement.
/// - **Candidates complete**: fast-forwards past steps the user has already
///   applied and returns the next unapplied step.
class HintGenerator {
  final Solver _solver;

  /// Cached solve result to avoid re-solving on every hint request.
  String? _cachedBoardKey;
  List<SolveStep>? _cachedSteps;

  HintGenerator({Solver? solver}) : _solver = solver ?? Solver();

  /// Generates a [HintResult] for the current board state.
  ///
  /// If [solution] and [initialBoard] are provided, checks for wrong
  /// values first. When found, returns a staged hint guiding the player
  /// to the mistake instead of a normal strategy hint.
  HintResult generateHint(
    Board board, {
    Board? solution,
    Board? initialBoard,
  }) {
    // Check for wrong values before normal hint generation.
    if (solution != null && initialBoard != null) {
      final wrongHint = _checkWrongValues(board, solution, initialBoard);
      if (wrongHint != null) return HintFound(wrongHint);
    }

    if (areCandidatesComplete(board)) {
      return _generateWithCandidates(board);
    }
    return _generateWithoutCandidates(board);
  }

  // ---------------------------------------------------------------------------
  // Case 1: Candidates are incomplete
  // ---------------------------------------------------------------------------

  /// Returns [HintNeedsCandidates] with a fallback placement hint (if any).
  HintResult _generateWithoutCandidates(Board board) {
    final steps = _solveAndCache(board);

    // Find the first step that places a value.
    for (final step in steps) {
      if (step.placements.isNotEmpty) {
        final hint = Hint(
          step: step,
          nudge: _buildNudge(step),
          strategyHint: _buildStrategyHint(step),
          answer: _buildAnswer(step),
        );
        return HintNeedsCandidates(placementHint: hint);
      }
    }

    // No placement reachable — still prompt for candidates.
    return HintNeedsCandidates();
  }

  // ---------------------------------------------------------------------------
  // Case 2: Candidates are complete — fast-forward past applied steps
  // ---------------------------------------------------------------------------

  /// Solves the puzzle, skips steps already reflected in the user's board,
  /// and returns the first unapplied step.
  HintResult _generateWithCandidates(Board board) {
    final steps = _solveAndCache(board);

    for (final step in steps) {
      if (_isStepAlreadyApplied(board, step)) continue;

      // This step has unapplied effects — build a hint for it.
      return HintFound(Hint(
        step: step,
        nudge: _buildNudge(step),
        strategyHint: _buildStrategyHint(step),
        answer: _buildAnswer(step, userBoard: board),
      ));
    }

    // All cached steps applied — try a fresh single-step lookup in case
    // the board has progressed beyond the cached solve path.
    final work = board.clone();
    computeCandidates(work);
    final step = _solver.nextStep(work);
    if (step == null) return HintNotAvailable();

    return HintFound(Hint(
      step: step,
      nudge: _buildNudge(step),
      strategyHint: _buildStrategyHint(step),
      answer: _buildAnswer(step),
    ));
  }

  /// Returns `true` if all effects of [step] are already reflected on [board].
  bool _isStepAlreadyApplied(Board board, SolveStep step) {
    for (final p in step.placements) {
      final cell = board.getCell(p.row, p.col);
      if (cell.value != p.value) return false;
    }

    for (final e in step.eliminations) {
      final cell = board.getCell(e.row, e.col);
      if (cell.isFilled) continue; // cell was filled — elimination is moot
      if (cell.candidates.contains(e.value)) return false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Solve result caching
  // ---------------------------------------------------------------------------

  /// Solves the puzzle and caches the result keyed by the board's value state.
  List<SolveStep> _solveAndCache(Board board) {
    final key = board.toFlatString();
    if (key == _cachedBoardKey && _cachedSteps != null) {
      return _cachedSteps!;
    }

    var result = _solver.solve(board, useBacktracking: false);
    if (!result.isSolved) {
      result = _solver.solve(board, useBacktracking: true);
    }

    _cachedBoardKey = key;
    _cachedSteps = result.steps;
    return result.steps;
  }

  // ---------------------------------------------------------------------------
  // Wrong-value detection (unchanged)
  // ---------------------------------------------------------------------------

  Hint? _checkWrongValues(Board board, Board solution, Board initialBoard) {
    final wrongCells = <({int row, int col, int value})>[];

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isGiven || cell.isEmpty) continue;
        if (cell.value != solution.getCell(r, c).value) {
          wrongCells.add((row: r, col: c, value: cell.value));
        }
      }
    }

    if (wrongCells.isEmpty) return null;

    final step = SolveStep(
      strategy: StrategyType.wrongValue,
      involvedCells: [for (final w in wrongCells) (row: w.row, col: w.col)],
      removals: [for (final w in wrongCells) Removal(w.row, w.col, w.value)],
      description: wrongCells.length == 1
          ? 'R${wrongCells.first.row + 1}C${wrongCells.first.col + 1} has the wrong value'
          : '${wrongCells.length} cells have wrong values',
    );

    return Hint(
      step: step,
      nudge: _buildWrongValueNudge(),
      strategyHint: _buildWrongValueStrategyHint(wrongCells),
      answer: _buildWrongValueAnswer(wrongCells),
    );
  }

  String _buildWrongValueNudge() {
    return "Your puzzle can't be solved from here \u2014 "
        'a filled cell has the wrong value';
  }

  String _buildWrongValueStrategyHint(
    List<({int row, int col, int value})> wrongCells,
  ) {
    final boxes = wrongCells.map((w) => (w.row ~/ 3) * 3 + w.col ~/ 3).toSet();
    final boxLabels = (boxes.toList()..sort()).map((b) => '${b + 1}');
    return 'Check the cells you filled in '
        'box${boxes.length > 1 ? 'es' : ''} ${boxLabels.join(' and ')}';
  }

  String _buildWrongValueAnswer(
    List<({int row, int col, int value})> wrongCells,
  ) {
    final parts = [
      for (final w in wrongCells) 'R${w.row + 1}C${w.col + 1}',
    ];
    return '${parts.join(' and ')} ${wrongCells.length == 1 ? 'is' : 'are'} wrong';
  }

  // ---------------------------------------------------------------------------
  // Hint text builders
  // ---------------------------------------------------------------------------

  /// Layer 1: A vague directional nudge.
  String _buildNudge(SolveStep step) {
    if (step.placements.isNotEmpty) {
      final p = step.placements.first;
      // Use the house from the strategy description when available
      // (e.g., hidden single reports "in row 1" or "in column 3").
      final region = _extractHouse(step.description) ??
          _mostSpecificRegion(p.row, p.col);
      return 'Look for ${p.value} in $region';
    }

    if (step.eliminations.isNotEmpty) {
      final region = _describeNudgeRegion(step);
      return 'Take a closer look at $region';
    }

    return 'Look at the board carefully';
  }

  /// Layer 2: Strategy name and the region where it applies.
  String _buildStrategyHint(SolveStep step) {
    final strategyName = step.strategy.label;

    if (step.involvedCells.isEmpty) {
      return 'Try using $strategyName';
    }

    final regionDesc = _describeInvolvedRegion(step);
    return 'Try using $strategyName $regionDesc';
  }

  /// Layer 3: The exact action to take.
  ///
  /// When [userBoard] is provided, already-applied placements and
  /// eliminations are filtered out so the answer only shows what
  /// the user still needs to do.
  String _buildAnswer(SolveStep step, {Board? userBoard}) {
    final parts = <String>[];

    for (final p in step.placements) {
      if (userBoard != null &&
          userBoard.getCell(p.row, p.col).value == p.value) {
        continue;
      }
      parts.add('Place ${p.value} at R${p.row + 1}C${p.col + 1}');
    }

    for (final e in step.eliminations) {
      if (userBoard != null) {
        final cell = userBoard.getCell(e.row, e.col);
        if (cell.isFilled || !cell.candidates.contains(e.value)) continue;
      }
      parts.add('Eliminate ${e.value} from R${e.row + 1}C${e.col + 1}');
    }

    if (parts.isEmpty) return step.description;
    return parts.join('; ');
  }

  /// Extracts a house name ("row N", "column N", "box N") from a strategy
  /// description string, or returns `null` if none is found.
  ///
  /// Strategy descriptions use patterns like "... in row 1" or "... in box 5",
  /// so this reliably picks up the house the strategy identified.
  static final _housePattern = RegExp(r'(row|column|box) (\d)');

  String? _extractHouse(String description) {
    final match = _housePattern.firstMatch(description);
    if (match == null) return null;
    return '${match.group(1)} ${match.group(2)}';
  }

  /// Returns the best single region name for an elimination-only step,
  /// based on the involved cells. Prefers a shared row/column/box when
  /// cells span multiple boxes (e.g., hidden pair in a column).
  String _describeNudgeRegion(SolveStep step) {
    final cells = step.involvedCells.isNotEmpty
        ? step.involvedCells
        : [(row: step.eliminations.first.row, col: step.eliminations.first.col)];

    final rows = cells.map((c) => c.row).toSet();
    final cols = cells.map((c) => c.col).toSet();
    final boxes = cells.map((c) => (c.row ~/ 3) * 3 + c.col ~/ 3).toSet();

    if (boxes.length == 1) return 'box ${boxes.first + 1}';
    if (rows.length == 1) return 'row ${rows.first + 1}';
    if (cols.length == 1) return 'column ${cols.first + 1}';

    // Fallback: use the box of the first cell.
    final box = (cells.first.row ~/ 3) * 3 + cells.first.col ~/ 3;
    return 'box ${box + 1}';
  }

  /// Returns the most specific single region name for a cell.
  String _mostSpecificRegion(int row, int col) {
    final box = (row ~/ 3) * 3 + col ~/ 3;
    return 'box ${box + 1}';
  }

  /// Describes where the involved cells are located.
  String _describeInvolvedRegion(SolveStep step) {
    final cells = step.involvedCells;
    if (cells.isEmpty) return '';

    final rows = cells.map((c) => c.row).toSet();
    final cols = cells.map((c) => c.col).toSet();
    final boxes = cells.map((c) => (c.row ~/ 3) * 3 + c.col ~/ 3).toSet();

    if (boxes.length == 1) {
      return 'in box ${boxes.first + 1}';
    }

    if (rows.length <= 3 && rows.length < cols.length) {
      final rowLabels = (rows.toList()..sort()).map((r) => '${r + 1}');
      return 'on row${rows.length > 1 ? 's' : ''} ${rowLabels.join(' and ')}';
    }

    if (cols.length <= 3) {
      final colLabels = (cols.toList()..sort()).map((c) => '${c + 1}');
      return 'on column${cols.length > 1 ? 's' : ''} ${colLabels.join(' and ')}';
    }

    final boxLabels = (boxes.toList()..sort()).map((b) => '${b + 1}');
    return 'in boxes ${boxLabels.join(' and ')}';
  }
}
