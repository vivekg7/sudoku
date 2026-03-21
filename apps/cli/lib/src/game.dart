import 'dart:io';

import 'package:sudoku_core/sudoku_core.dart';

import 'board_renderer.dart';
import 'game_timer.dart';

/// Interactive Sudoku game session for the CLI.
class Game {
  final Puzzle puzzle;
  final BoardRenderer _renderer = BoardRenderer();
  final GameTimer _timer = GameTimer();
  final HintGenerator _hintGen = HintGenerator();

  int _cursorRow = 0;
  int _cursorCol = 0;
  bool _showCandidates = false;
  int _mistakeCount = 0;

  // Hint state.
  Hint? _currentHint;
  int _hintLayer = 0; // 0 = none shown, 1 = nudge, 2 = strategy, 3 = answer
  final Map<HintLevel, int> _hintCounts = {};
  final Map<StrategyType, int> _hintStrategyCounts = {};

  // Analysis result (printed after game loop exits).
  PuzzleAnalysis? _analysis;

  Game(this.puzzle, {int initialElapsedSeconds = 0}) {
    if (initialElapsedSeconds > 0) {
      _timer.setInitialOffset(initialElapsedSeconds);
    }
  }

  /// Current elapsed seconds (for saving).
  int get elapsedSeconds => _timer.elapsedSeconds;

  /// Runs the interactive game loop.
  void run() {
    _timer.start();
    _printBoard();
    _printHelp();

    while (!puzzle.isSolved) {
      stdout.write('\n> ');
      final line = stdin.readLineSync()?.trim();
      if (line == null || line.isEmpty) continue;

      if (!_handleCommand(line)) break;

      if (puzzle.isSolved) {
        _timer.pause();
        _printBoard();
        print('\nCongratulations! Puzzle solved!');
        print('Time: ${_timer.formatted}');
        print('Hints used: ${_totalHints()}');
        break;
      }
    }
  }

  /// Returns true to continue, false to quit.
  bool _handleCommand(String input) {
    final parts = input.split(RegExp(r'\s+'));
    final cmd = parts[0].toLowerCase();

    switch (cmd) {
      case 'q' || 'quit' || 'exit':
        _timer.pause();
        print('Game paused. Goodbye!');
        return false;

      case 'h' || 'help':
        _printHelp();

      case 's' || 'set':
        _handleSet(parts);

      case 'c' || 'clear':
        _handleClear(parts);

      case 'n' || 'note' || 'candidate':
        _handleNote(parts);

      case 'g' || 'go' || 'select':
        _handleSelect(parts);

      case 'u' || 'undo':
        _handleUndo();

      case 'r' || 'redo':
        _handleRedo();

      case 'hint':
        _handleHint();

      case 'fill':
        _handleFill();

      case 'analyze':
        _handleAnalyze();
        if (puzzle.completionType == CompletionType.analyzed) return false;

      case 'solve':
        _handleSolve();

      case 'candidates':
        _showCandidates = !_showCandidates;
        _printBoard();
        print(_showCandidates
            ? 'Showing candidates.'
            : 'Hiding candidates.');

      case 'timer':
        print('Time: ${_timer.formatted}');

      case 'pause':
        _timer.pause();
        print('Timer paused.');

      case 'resume':
        _timer.start();
        print('Timer resumed.');

      case 'stats':
        _printStats();

      default:
        // Try to parse as "RC V" shorthand (e.g., "35 7" = R3C5 = 7).
        if (!_handleShorthand(input)) {
          print('Unknown command. Type "help" for commands.');
        }
    }

    return true;
  }

  void _handleSet(List<String> parts) {
    if (parts.length < 2) {
      print('Usage: set <value>  (sets value at cursor)');
      print('   or: set <row><col> <value>  (e.g., set 35 7)');
      return;
    }

    int row, col, value;

    if (parts.length >= 3) {
      final pos = _parsePosition(parts[1]);
      if (pos == null) return;
      row = pos.$1;
      col = pos.$2;
      value = int.tryParse(parts[2]) ?? 0;
    } else {
      row = _cursorRow;
      col = _cursorCol;
      value = int.tryParse(parts[1]) ?? 0;
    }

    if (value < 1 || value > 9) {
      print('Value must be 1-9.');
      return;
    }

    final cell = puzzle.board.getCell(row, col);
    if (cell.isGiven) {
      print('Cannot modify a given cell.');
      return;
    }

    // Record move for undo.
    puzzle.history.push(Move(
      row: row,
      col: col,
      type: MoveType.setValue,
      previousValue: cell.value,
      newValue: value,
      previousCandidates: cell.candidates.copy(),
      newCandidates: CandidateSet(),
    ));

    cell.setValue(value);

    // Check for conflicts.
    final conflicts = _findConflicts(row, col, value);
    _cursorRow = row;
    _cursorCol = col;
    _clearHint();
    _printBoard();

    if (conflicts.isNotEmpty) {
      _mistakeCount++;
      print('Warning: conflict with ${conflicts.join(", ")}!');
    }
  }

  void _handleClear(List<String> parts) {
    int row, col;

    if (parts.length >= 2) {
      final pos = _parsePosition(parts[1]);
      if (pos == null) return;
      row = pos.$1;
      col = pos.$2;
    } else {
      row = _cursorRow;
      col = _cursorCol;
    }

    final cell = puzzle.board.getCell(row, col);
    if (cell.isGiven) {
      print('Cannot modify a given cell.');
      return;
    }
    if (cell.isEmpty) {
      print('Cell is already empty.');
      return;
    }

    puzzle.history.push(Move(
      row: row,
      col: col,
      type: MoveType.clearValue,
      previousValue: cell.value,
      newValue: 0,
      previousCandidates: cell.candidates.copy(),
    ));

    cell.clearValue();
    _clearHint();
    _printBoard();
  }

  void _handleNote(List<String> parts) {
    if (parts.length < 2) {
      print('Usage: note <value>  (toggles candidate at cursor)');
      print('   or: note <row><col> <value>');
      return;
    }

    int row, col, value;

    if (parts.length >= 3) {
      final pos = _parsePosition(parts[1]);
      if (pos == null) return;
      row = pos.$1;
      col = pos.$2;
      value = int.tryParse(parts[2]) ?? 0;
    } else {
      row = _cursorRow;
      col = _cursorCol;
      value = int.tryParse(parts[1]) ?? 0;
    }

    if (value < 1 || value > 9) {
      print('Value must be 1-9.');
      return;
    }

    final cell = puzzle.board.getCell(row, col);
    if (cell.isGiven || cell.isFilled) {
      print('Cannot add notes to a filled cell.');
      return;
    }

    final prevCandidates = cell.candidates.copy();
    cell.toggleCandidate(value);
    final newCandidates = cell.candidates.copy();

    puzzle.history.push(Move(
      row: row,
      col: col,
      type: cell.candidates.contains(value)
          ? MoveType.addCandidate
          : MoveType.removeCandidate,
      previousCandidates: prevCandidates,
      newCandidates: newCandidates,
    ));

    _cursorRow = row;
    _cursorCol = col;
    if (!_showCandidates) _showCandidates = true;
    _printBoard();
  }

  void _handleSelect(List<String> parts) {
    if (parts.length < 2) {
      print('Usage: go <row><col>  (e.g., go 35 = row 3, col 5)');
      return;
    }

    final pos = _parsePosition(parts[1]);
    if (pos == null) return;

    _cursorRow = pos.$1;
    _cursorCol = pos.$2;
    _printBoard();
  }

  void _handleUndo() {
    final moves = puzzle.history.undo();
    if (moves == null) {
      print('Nothing to undo.');
      return;
    }

    for (final move in moves.reversed) {
      final cell = puzzle.board.getCell(move.row, move.col);
      if (move.previousValue != 0) {
        cell.setValue(move.previousValue);
      } else {
        cell.clearValue();
      }
      cell.setCandidates(move.previousCandidates);

      for (final (r, c, v) in move.removedPeerCandidates) {
        puzzle.board.getCell(r, c).addCandidate(v);
      }
    }

    _cursorRow = moves.first.row;
    _cursorCol = moves.first.col;
    _printBoard();
    print('Undone.');
  }

  void _handleRedo() {
    final moves = puzzle.history.redo();
    if (moves == null) {
      print('Nothing to redo.');
      return;
    }

    for (final move in moves) {
      final cell = puzzle.board.getCell(move.row, move.col);
      if (move.newValue != 0) {
        cell.setValue(move.newValue);
      } else {
        cell.clearValue();
      }
      cell.setCandidates(move.newCandidates);

      for (final (r, c, v) in move.removedPeerCandidates) {
        puzzle.board.getCell(r, c).removeCandidate(v);
      }
    }

    _cursorRow = moves.last.row;
    _cursorCol = moves.last.col;
    _printBoard();
    print('Redone.');
  }

  void _handleHint() {
    if (_currentHint == null || _hintLayer >= 3) {
      // Generate a new hint.
      _currentHint = _hintGen.generate(puzzle.board);
      _hintLayer = 0;

      if (_currentHint == null) {
        print('No hint available - the board may be in an invalid state.');
        return;
      }
    }

    _hintLayer++;
    final level = HintLevel.values[_hintLayer - 1];
    final text = _currentHint!.textForLevel(level);

    // Track hint usage.
    _hintCounts[level] = (_hintCounts[level] ?? 0) + 1;
    final strategy = _currentHint!.step.strategy;
    _hintStrategyCounts[strategy] =
        (_hintStrategyCounts[strategy] ?? 0) + 1;

    print('Hint (${level.name}): $text');

    if (_hintLayer >= 3) {
      // Show involved cells.
      final cells = _currentHint!.step.involvedCells;
      if (cells.isNotEmpty) {
        final highlights = cells.toSet();
        print('');
        print(_renderer.render(puzzle.board,
            selectedRow: _cursorRow,
            selectedCol: _cursorCol,
            highlights: highlights));
      }
      print('Type "hint" again for the next step.');
    }
  }

  void _handleSolve() {
    stdout.write('Show the solution? This ends the game. (y/n): ');
    final answer = stdin.readLineSync()?.trim().toLowerCase();
    if (answer != 'y') {
      print('Cancelled.');
      return;
    }

    // Fill in the solution.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = puzzle.board.getCell(r, c);
        if (cell.isEmpty) {
          cell.setValue(puzzle.solution.getCell(r, c).value);
        }
      }
    }

    _timer.pause();
    _printBoard();
    print('\nSolution revealed. Time: ${_timer.formatted}');
  }

  void _printBoard() {
    // Clear screen for a cleaner experience.
    print('\x1B[2J\x1B[H');
    print('Sudoku - ${puzzle.difficulty.label}    Time: ${_timer.formatted}'
        '    Empty: ${puzzle.emptyCellCount}');
    if (puzzle.quoteId != null) {
      final quote = QuoteRepository.instance.getById(puzzle.quoteId!);
      if (quote != null) {
        print('"${quote.text}" - ${quote.author}');
      }
    }
    print('');
    print(_renderer.render(
      puzzle.board,
      selectedRow: _cursorRow,
      selectedCol: _cursorCol,
      showCandidates: _showCandidates,
    ));
  }

  void _printHelp() {
    print('Commands:');
    print('  go <RC>           Select cell (e.g., go 35 = row 3, col 5)');
    print('  set <value>       Set value at cursor');
    print('  set <RC> <value>  Set value at cell (e.g., set 35 7)');
    print('  <RC> <value>      Shorthand for set (e.g., 35 7)');
    print('  clear [RC]        Clear cell value');
    print('  note <value>      Toggle candidate at cursor');
    print('  note <RC> <value> Toggle candidate at cell');
    print('  undo / redo       Undo or redo last move');
    print('  hint              Progressive hint (nudge -> strategy -> answer)');
    print('  fill              Auto-fill all candidate notes');
    print('  candidates        Toggle candidate display');
    print('  analyze           Analyze puzzle (reveals solution)');
    print('  solve             Reveal the solution');
    print('  timer             Show elapsed time');
    print('  pause / resume    Pause or resume timer');
    print('  stats             Show game stats');
    print('  quit              Exit game');
  }

  void _printStats() {
    print('--- Game Stats ---');
    print('Difficulty: ${puzzle.difficulty.label}');
    print('Time: ${_timer.formatted}');
    print('Cells remaining: ${puzzle.emptyCellCount}');
    print('Mistakes: $_mistakeCount');
    print('Hints used: ${_totalHints()}');
    if (_hintCounts.isNotEmpty) {
      for (final e in _hintCounts.entries) {
        print('  ${e.key.name}: ${e.value}');
      }
    }
    if (_hintStrategyCounts.isNotEmpty) {
      print('Hints by strategy:');
      for (final e in _hintStrategyCounts.entries) {
        print('  ${e.key.label}: ${e.value}');
      }
    }
    print('Moves: ${puzzle.history.undoCount}');
  }

  int _totalHints() =>
      _hintCounts.values.fold(0, (sum, c) => sum + c);

  void _handleFill() {
    final board = puzzle.board;
    final moves = <Move>[];

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;

        var usedBits = 0;
        for (final peer in board.peers(r, c)) {
          if (peer.isFilled) usedBits |= 1 << peer.value;
        }
        final candidateBits = 0x3FE & ~usedBits;
        final newCandidates = CandidateSet(candidateBits);
        final prevCandidates = cell.candidates.copy();

        if (newCandidates == prevCandidates) continue;

        moves.add(Move(
          row: r,
          col: c,
          type: MoveType.setCandidates,
          previousCandidates: prevCandidates,
          newCandidates: newCandidates,
        ));

        cell.setCandidates(newCandidates);
      }
    }

    if (moves.isEmpty) {
      print('All candidates already filled.');
      return;
    }

    puzzle.history.pushAll(moves);
    _clearHint();
    if (!_showCandidates) _showCandidates = true;
    _printBoard();
    print('Filled candidates for ${moves.length} cells.');
  }

  void _handleAnalyze() {
    stdout.write('Analyze this puzzle? This ends the game. (y/n): ');
    final answer = stdin.readLineSync()?.trim().toLowerCase();
    if (answer != 'y') {
      print('Cancelled.');
      return;
    }

    // Fill all empty cells with solution.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = puzzle.board.getCell(r, c);
        if (cell.isEmpty) {
          cell.setValue(puzzle.solution.getCell(r, c).value);
        }
      }
    }

    puzzle.completionType = CompletionType.analyzed;
    _timer.pause();

    // Generate analysis.
    if (puzzle.solveResult != null) {
      _analysis = PuzzleAnalyzer.analyze(puzzle);
      _printAnalysis(_analysis!);
    }
  }

  void _printAnalysis(PuzzleAnalysis analysis) {
    print('\n--- Puzzle Analysis ---');
    print('Difficulty: ${analysis.difficulty.label} '
        '(score: ${analysis.scoreBreakdown.totalScore})');
    print('Hardest strategy: ${analysis.hardestStrategy.label}');
    print('Total steps: ${analysis.steps.length}');
    print('');

    print('Strategies used:');
    for (final sc in analysis.strategyCounts) {
      print('  ${sc.strategy.label}: ${sc.count}x');
    }

    if (analysis.bottlenecks.isNotEmpty) {
      print('');
      print('Bottleneck cells:');
      for (final b in analysis.bottlenecks) {
        print('  R${b.row + 1}C${b.col + 1} = ${b.value} '
            '(${b.strategy.label})');
      }
    }

    final sb = analysis.scoreBreakdown;
    print('');
    print('Score breakdown:');
    print('  Hardest strategy weight: ${sb.hardestWeight} x3 = ${sb.hardestContribution}');
    print('  Advanced techniques: ${sb.advancedTotal} /4 = ${sb.advancedContribution}');
    print('  Given penalty (${sb.givenCount} givens): ${sb.givenPenalty}');
    print('  Step penalty (${sb.stepCount} steps): ${sb.stepPenalty}');
    print('  Total: ${sb.totalScore}');
  }

  /// Analysis result, available after [_handleAnalyze] is called.
  PuzzleAnalysis? get analysis => _analysis;

  void _clearHint() {
    _currentHint = null;
    _hintLayer = 0;
  }

  (int, int)? _parsePosition(String s) {
    if (s.length != 2) {
      print('Position must be 2 digits: row (1-9) and column (1-9).');
      return null;
    }
    final row = int.tryParse(s[0]);
    final col = int.tryParse(s[1]);
    if (row == null || col == null || row < 1 || row > 9 || col < 1 || col > 9) {
      print('Invalid position. Use digits 1-9 for row and column.');
      return null;
    }
    return (row - 1, col - 1);
  }

  bool _handleShorthand(String input) {
    final parts = input.split(RegExp(r'\s+'));
    if (parts.length == 2 && parts[0].length == 2) {
      final pos = _parsePosition(parts[0]);
      final value = int.tryParse(parts[1]);
      if (pos != null && value != null) {
        _handleSet(['set', parts[0], parts[1]]);
        return true;
      }
    }
    return false;
  }

  List<String> _findConflicts(int row, int col, int value) {
    final conflicts = <String>[];
    final board = puzzle.board;

    for (final c in board.getRow(row)) {
      if (c.col != col && c.value == value) {
        conflicts.add('R${row + 1}C${c.col + 1}');
      }
    }
    for (final c in board.getColumn(col)) {
      if (c.row != row && c.value == value) {
        conflicts.add('R${c.row + 1}C${col + 1}');
      }
    }
    final box = board.getBox(board.getCell(row, col).box);
    for (final c in box) {
      if ((c.row != row || c.col != col) && c.value == value) {
        if (!conflicts.contains('R${c.row + 1}C${c.col + 1}')) {
          conflicts.add('R${c.row + 1}C${c.col + 1}');
        }
      }
    }
    return conflicts;
  }

  /// Builds a [GameStats] from the current session.
  GameStats toGameStats() => GameStats(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        difficulty: puzzle.difficulty,
        solveTimeSeconds: _timer.elapsedSeconds,
        completed: puzzle.isSolved &&
            puzzle.completionType != CompletionType.analyzed,
        hintsByLevel: Map.of(_hintCounts),
        hintsByStrategy: Map.of(_hintStrategyCounts),
        playedAt: DateTime.now(),
        puzzleId: puzzle.initialBoard.toFlatString(),
        mistakeCount: _mistakeCount,
        completionType: puzzle.completionType?.name,
        boardLayout: 'cli',
        assistLevel: 'none',
      );
}
