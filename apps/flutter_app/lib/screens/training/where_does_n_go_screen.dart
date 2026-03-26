import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'where_does_n_go_results_screen.dart';

/// A single "Where Does N Go?" challenge.
class WhereDoesNGoChallenge {
  /// The 9x9 board values (0 = empty).
  final List<List<int>> boardValues;

  /// Which cells are givens (part of the original puzzle).
  final List<List<bool>> isGiven;

  /// The digit the player must place.
  final int targetDigit;

  /// The target cell (row, col).
  final int targetRow;
  final int targetCol;

  /// The house type that contains the hidden single (for prompt).
  final HouseType houseType;

  /// The house index (0-8) for the prompt.
  final int houseIndex;

  WhereDoesNGoChallenge({
    required this.boardValues,
    required this.isGiven,
    required this.targetDigit,
    required this.targetRow,
    required this.targetCol,
    required this.houseType,
    required this.houseIndex,
  });
}

class WhereDoesNGoScreen extends StatefulWidget {
  final WhereDoesNGoMode mode;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const WhereDoesNGoScreen({
    super.key,
    required this.mode,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  State<WhereDoesNGoScreen> createState() => _WhereDoesNGoScreenState();
}

class _WhereDoesNGoScreenState extends State<WhereDoesNGoScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final _generator = PuzzleGenerator();
  final _solver = Solver();

  WhereDoesNGoChallenge? _challenge;
  int _score = 0;
  int? _bestStreak;
  bool _gameOver = false;
  bool _loading = true;

  // Timer state.
  late int _timeAllowedMs;
  late AnimationController _timerController;
  late Stopwatch _totalStopwatch;

  // Prevent consecutive same digit.
  int _lastDigit = 0;

  @override
  void initState() {
    super.initState();
    final best = widget.trainingStorage.getBest(
      TrainingStorageService.whereDoesNGoKey(widget.mode),
    );
    _bestStreak = best?.streak;
    _timeAllowedMs = widget.mode.timeForRound(0);

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _timeAllowedMs),
    );
    _timerController.addStatusListener(_onTimerStatus);

    _totalStopwatch = Stopwatch();
    _generateAndStart();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_gameOver) {
      _endGame(null);
    }
  }

  Future<void> _generateAndStart() async {
    final challenge = await _generateChallenge();
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _loading = false;
    });
    _totalStopwatch.start();
    _timerController.duration = Duration(milliseconds: _timeAllowedMs);
    _timerController.forward(from: 0.0);
  }

  Future<WhereDoesNGoChallenge> _generateChallenge() async {
    // Keep trying until we find a valid hidden single challenge.
    while (true) {
      final puzzle = _generator.generate(
        _random.nextBool() ? Difficulty.beginner : Difficulty.easy,
      );
      if (puzzle == null) continue;

      final board = puzzle.initialBoard.clone();
      computeCandidates(board);
      final result = _solver.solve(board);

      // Walk through solve steps on a fresh board to find a hidden single.
      final workBoard = puzzle.initialBoard.clone();
      computeCandidates(workBoard);

      for (final step in result.steps) {
        if (step.strategy == StrategyType.hiddenSingle &&
            step.placements.isNotEmpty) {
          final placement = step.placements.first;
          final digit = placement.value;

          // Skip if same digit as last round.
          if (digit == _lastDigit) {
            // Apply this step and continue looking.
            _applyStep(workBoard, step);
            continue;
          }

          // For Sprint mode: verify this digit has only one hidden single
          // placement on the entire board.
          if (widget.mode == WhereDoesNGoMode.sprint) {
            if (_hasOtherPlacement(workBoard, digit, placement.row,
                placement.col)) {
              _applyStep(workBoard, step);
              continue;
            }
          }

          // Determine which house the hidden single belongs to.
          final houseInfo = _extractHouseInfo(step.description);

          _lastDigit = digit;

          // Snapshot the board state.
          final boardValues = List.generate(
            9,
            (r) => List.generate(
              9,
              (c) => workBoard.getCell(r, c).value,
            ),
          );
          final isGiven = List.generate(
            9,
            (r) => List.generate(
              9,
              (c) => workBoard.getCell(r, c).isGiven,
            ),
          );

          return WhereDoesNGoChallenge(
            boardValues: boardValues,
            isGiven: isGiven,
            targetDigit: digit,
            targetRow: placement.row,
            targetCol: placement.col,
            houseType: houseInfo.type,
            houseIndex: houseInfo.index,
          );
        }

        // Apply non-hidden-single steps to advance the board.
        _applyStep(workBoard, step);
      }
      // No suitable hidden single found in this puzzle — try another.
    }
  }

  void _applyStep(Board board, SolveStep step) {
    for (final p in step.placements) {
      board.getCell(p.row, p.col).setValue(p.value);
      // Update candidates for peers.
      for (final peer in board.peers(p.row, p.col)) {
        peer.removeCandidate(p.value);
      }
    }
    for (final e in step.eliminations) {
      board.getCell(e.row, e.col).removeCandidate(e.value);
    }
  }

  /// Check if digit has another naked/hidden single placement elsewhere.
  bool _hasOtherPlacement(Board board, int digit, int skipRow, int skipCol) {
    // Check all empty cells: is there another cell where this digit is a
    // naked single or hidden single?
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (r == skipRow && c == skipCol) continue;
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;

        // Naked single: only one candidate.
        if (cell.candidates.length == 1 &&
            cell.candidates.contains(digit)) {
          return true;
        }

        // Hidden single in any house containing this cell.
        if (cell.candidates.contains(digit)) {
          if (_isHiddenSingleInHouse(board, digit, r, c)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _isHiddenSingleInHouse(Board board, int digit, int row, int col) {
    // Check row.
    bool onlyInRow = true;
    for (int c = 0; c < 9; c++) {
      if (c == col) continue;
      final cell = board.getCell(row, c);
      if (cell.isEmpty && cell.candidates.contains(digit)) {
        onlyInRow = false;
        break;
      }
    }
    if (onlyInRow) return true;

    // Check column.
    bool onlyInCol = true;
    for (int r = 0; r < 9; r++) {
      if (r == row) continue;
      final cell = board.getCell(r, col);
      if (cell.isEmpty && cell.candidates.contains(digit)) {
        onlyInCol = false;
        break;
      }
    }
    if (onlyInCol) return true;

    // Check box.
    final boxR = (row ~/ 3) * 3;
    final boxC = (col ~/ 3) * 3;
    bool onlyInBox = true;
    for (int r = boxR; r < boxR + 3; r++) {
      for (int c = boxC; c < boxC + 3; c++) {
        if (r == row && c == col) continue;
        final cell = board.getCell(r, c);
        if (cell.isEmpty && cell.candidates.contains(digit)) {
          onlyInBox = false;
          break;
        }
      }
      if (!onlyInBox) break;
    }
    if (onlyInBox) return true;

    return false;
  }

  ({HouseType type, int index}) _extractHouseInfo(String description) {
    // Description format: "N can only go in RxCy in <house>"
    // e.g. "5 can only go in R2C3 in row 2"
    // e.g. "5 can only go in R2C3 in box 5"
    // e.g. "5 can only go in R2C3 in column 3"
    final lower = description.toLowerCase();
    if (lower.contains('box')) {
      final match = RegExp(r'box\s+(\d)').firstMatch(lower);
      final idx = match != null ? int.parse(match.group(1)!) - 1 : 0;
      return (type: HouseType.box, index: idx);
    } else if (lower.contains('column')) {
      final match = RegExp(r'column\s+(\d)').firstMatch(lower);
      final idx = match != null ? int.parse(match.group(1)!) - 1 : 0;
      return (type: HouseType.column, index: idx);
    } else {
      final match = RegExp(r'row\s+(\d)').firstMatch(lower);
      final idx = match != null ? int.parse(match.group(1)!) - 1 : 0;
      return (type: HouseType.row, index: idx);
    }
  }

  void _onCellTap(int row, int col) {
    if (_gameOver || _loading) return;
    final challenge = _challenge!;

    // Only allow tapping empty cells.
    if (challenge.boardValues[row][col] != 0) return;

    if (row == challenge.targetRow && col == challenge.targetCol) {
      // Correct!
      setState(() {
        _score++;
        _timeAllowedMs = widget.mode.timeForRound(_score);
        _loading = true;
      });
      _generateNextChallenge();
    } else {
      // Wrong!
      _endGame((row: row, col: col));
    }
  }

  Future<void> _generateNextChallenge() async {
    _timerController.stop();
    final challenge = await _generateChallenge();
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _loading = false;
    });
    _timerController.duration = Duration(milliseconds: _timeAllowedMs);
    _timerController.forward(from: 0.0);
  }

  void _endGame(({int row, int col})? wrongCell) async {
    _timerController.stop();
    _totalStopwatch.stop();
    setState(() {
      _gameOver = true;
    });

    final score = TrainingScore(
      streak: _score,
      totalTimeMs: _totalStopwatch.elapsedMilliseconds,
      playedAt: DateTime.now(),
    );

    final key = TrainingStorageService.whereDoesNGoKey(widget.mode);
    widget.trainingStorage.setLastPlayedKey(key);

    final int? rank;
    if (_score > 0) {
      rank = await widget.trainingStorage.addScore(key, score);
    } else {
      await widget.trainingStorage.save();
      rank = null;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WhereDoesNGoResultsScreen(
          score: score,
          rank: rank,
          mode: widget.mode,
          wrongCell: wrongCell,
          challenge: _challenge!,
          settings: widget.settings,
          trainingStorage: widget.trainingStorage,
        ),
      ),
    );
  }

  String _buildPrompt() {
    final challenge = _challenge!;
    final digit = challenge.targetDigit;

    if (widget.mode == WhereDoesNGoMode.sprint) {
      return 'Where does $digit go?';
    }

    final houseLabel = switch (challenge.houseType) {
      HouseType.box => 'Box ${challenge.houseIndex + 1}',
      HouseType.row => 'Row ${challenge.houseIndex + 1}',
      HouseType.column => 'Column ${challenge.houseIndex + 1}',
    };
    return 'Where does $digit go in $houseLabel?';
  }

  /// Returns the set of cells to highlight for the target house (Chill mode).
  Set<(int, int)> _highlightedCells() {
    if (!widget.mode.highlightHouse || _challenge == null) return {};
    final c = _challenge!;
    final cells = <(int, int)>{};
    switch (c.houseType) {
      case HouseType.box:
        final startRow = (c.houseIndex ~/ 3) * 3;
        final startCol = (c.houseIndex % 3) * 3;
        for (int r = startRow; r < startRow + 3; r++) {
          for (int cc = startCol; cc < startCol + 3; cc++) {
            cells.add((r, cc));
          }
        }
      case HouseType.row:
        for (int cc = 0; cc < 9; cc++) {
          cells.add((c.houseIndex, cc));
        }
      case HouseType.column:
        for (int r = 0; r < 9; r++) {
          cells.add((r, c.houseIndex));
        }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Where Does N Go?'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timerController.stop();
            _totalStopwatch.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score row.
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: $_score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (_bestStreak != null)
                    Text(
                      'Best: $_bestStreak',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // Timer bar.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _timerController,
                builder: (context, _) {
                  final progress = _timerController.value;
                  final remaining = 1.0 - progress;

                  final Color barColor;
                  if (remaining > 0.5) {
                    barColor = colorScheme.primary;
                  } else if (remaining > 0.25) {
                    barColor = Color.lerp(
                      Colors.amber,
                      colorScheme.primary,
                      (remaining - 0.25) / 0.25,
                    )!;
                  } else {
                    barColor = Color.lerp(
                      Colors.red,
                      Colors.amber,
                      remaining / 0.25,
                    )!;
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: remaining,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: barColor,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Prompt.
            if (_challenge != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _buildPrompt(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 8),

            // Board.
            Expanded(
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : _buildBoard(context),
              ),
            ),

            // Streak label.
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'streak: $_score',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCircular = widget.settings.boardLayout == BoardLayout.circular;
    final highlighted = _highlightedCells();
    final challenge = _challenge!;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              final row = index ~/ 9;
              final col = index % 9;
              final value = challenge.boardValues[row][col];
              final isEmpty = value == 0;
              final isHighlighted = highlighted.contains((row, col));
              final given = challenge.isGiven[row][col];

              Color bg;
              if (isHighlighted) {
                bg = colorScheme.primary.withValues(alpha: 0.1);
              } else {
                bg = colorScheme.surface;
              }

              final textColor = given
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.7);

              final cellContent = isEmpty
                  ? const SizedBox.shrink()
                  : Center(
                      child: FittedBox(
                        child: Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                given ? FontWeight.w600 : FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                      ),
                    );

              // Add box borders for classic layout.
              final borderSide = BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              );
              final thickSide = BorderSide(
                color: colorScheme.outline,
                width: 1.5,
              );

              final border = Border(
                top: row % 3 == 0 ? thickSide : borderSide,
                left: col % 3 == 0 ? thickSide : borderSide,
                bottom: row == 8 ? thickSide : BorderSide.none,
                right: col == 8 ? thickSide : BorderSide.none,
              );

              if (isCircular) {
                return GestureDetector(
                  onTap: isEmpty ? () => _onCellTap(row, col) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      border: border,
                    ),
                    child: cellContent,
                  ),
                );
              }

              return GestureDetector(
                onTap: isEmpty ? () => _onCellTap(row, col) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    border: border,
                  ),
                  child: cellContent,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
