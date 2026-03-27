import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'candidate_fill_results_screen.dart';

/// Data for a single Candidate Fill challenge.
class CandidateFillChallenge {
  /// The 9x9 board values (0 = empty).
  final List<List<int>> boardValues;

  /// Which cells are givens.
  final List<List<bool>> isGiven;

  /// The house type of the target region.
  final HouseType houseType;

  /// The house index (0-8).
  final int houseIndex;

  /// Set of (row, col) for cells in the target region.
  final Set<(int, int)> regionCells;

  /// Set of (row, col) for empty cells in the target region.
  final Set<(int, int)> emptyCells;

  /// Correct candidates for each empty cell: (row, col) → {digits}.
  final Map<(int, int), Set<int>> correctCandidates;

  CandidateFillChallenge({
    required this.boardValues,
    required this.isGiven,
    required this.houseType,
    required this.houseIndex,
    required this.regionCells,
    required this.emptyCells,
    required this.correctCandidates,
  });
}

class CandidateFillScreen extends StatefulWidget {
  final CandidateFillMode mode;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const CandidateFillScreen({
    super.key,
    required this.mode,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  State<CandidateFillScreen> createState() => _CandidateFillScreenState();
}

class _CandidateFillScreenState extends State<CandidateFillScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final _generator = PuzzleGenerator();
  final _solver = Solver();

  CandidateFillChallenge? _challenge;
  int _score = 0;
  int? _bestStreak;
  bool _gameOver = false;
  bool _loading = true;

  // Timer state.
  late int _timeAllowedMs;
  late AnimationController _timerController;
  late Stopwatch _totalStopwatch;

  // Player's candidate entries: (row, col) → {digits}.
  final Map<(int, int), Set<int>> _playerCandidates = {};

  // Input state.
  int? _activeNumber; // Number-first mode.
  (int, int)? _selectedCell; // Cell-first mode.

  // Prevent consecutive same region.
  HouseType? _lastHouseType;
  int? _lastHouseIndex;

  @override
  void initState() {
    super.initState();
    final best = widget.trainingStorage.getBest(
      TrainingStorageService.candidateFillKey(widget.mode),
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
      _endGame(timedOut: true);
    }
  }

  Future<void> _generateAndStart() async {
    final challenge = await _generateChallenge();
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _loading = false;
      _playerCandidates.clear();
      _activeNumber = null;
      _selectedCell = null;
      for (final cell in challenge.emptyCells) {
        _playerCandidates[cell] = {};
      }
    });
    _totalStopwatch.start();
    _timerController.duration = Duration(milliseconds: _timeAllowedMs);
    _timerController.forward(from: 0.0);
  }

  Future<CandidateFillChallenge> _generateChallenge() async {
    while (true) {
      final puzzle = _generator.generate(
        _random.nextBool() ? Difficulty.beginner : Difficulty.easy,
      );
      if (puzzle == null) continue;

      final board = puzzle.initialBoard.clone();
      computeCandidates(board);
      final result = _solver.solve(board);

      // Advance the board based on mode to control fill level.
      final workBoard = puzzle.initialBoard.clone();
      computeCandidates(workBoard);

      // Solve some steps to fill the board more for easier modes.
      final stepsToApply = switch (widget.mode) {
        CandidateFillMode.chill => (result.steps.length * 0.6).round(),
        CandidateFillMode.quick => (result.steps.length * 0.4).round(),
        CandidateFillMode.sprint => (result.steps.length * 0.2).round(),
      };

      for (int i = 0; i < stepsToApply && i < result.steps.length; i++) {
        _applyStep(workBoard, result.steps[i]);
      }

      // Pick a random target region.
      final houseTypes = widget.mode.houseTypes;
      final houseType = houseTypes[_random.nextInt(houseTypes.length)];

      // Try random house indices.
      final indices = List.generate(9, (i) => i)..shuffle(_random);
      for (final houseIndex in indices) {
        // Skip if same as last round.
        if (houseType == _lastHouseType && houseIndex == _lastHouseIndex) {
          continue;
        }

        final regionCells = _getRegionCells(houseType, houseIndex);
        final emptyCells = <(int, int)>{};

        for (final (r, c) in regionCells) {
          if (workBoard.getCell(r, c).isEmpty) {
            emptyCells.add((r, c));
          }
        }

        // Check empty cell count is in range.
        if (emptyCells.length < widget.mode.minEmptyCells ||
            emptyCells.length > widget.mode.maxEmptyCells) {
          continue;
        }

        // Ensure every empty cell has at least 2 candidates.
        bool allValid = true;
        final correctCandidates = <(int, int), Set<int>>{};
        for (final (r, c) in emptyCells) {
          final candidates = _computeCandidatesForCell(workBoard, r, c);
          if (candidates.length < 2) {
            allValid = false;
            break;
          }
          correctCandidates[(r, c)] = candidates;
        }
        if (!allValid) continue;

        _lastHouseType = houseType;
        _lastHouseIndex = houseIndex;

        // Snapshot the board.
        final boardValues = List.generate(
          9,
          (r) => List.generate(9, (c) => workBoard.getCell(r, c).value),
        );
        final isGiven = List.generate(
          9,
          (r) => List.generate(9, (c) => workBoard.getCell(r, c).isGiven),
        );

        return CandidateFillChallenge(
          boardValues: boardValues,
          isGiven: isGiven,
          houseType: houseType,
          houseIndex: houseIndex,
          regionCells: regionCells,
          emptyCells: emptyCells,
          correctCandidates: correctCandidates,
        );
      }
      // No suitable region found — try another puzzle.
    }
  }

  Set<(int, int)> _getRegionCells(HouseType type, int index) {
    final cells = <(int, int)>{};
    switch (type) {
      case HouseType.box:
        final startRow = (index ~/ 3) * 3;
        final startCol = (index % 3) * 3;
        for (int r = startRow; r < startRow + 3; r++) {
          for (int c = startCol; c < startCol + 3; c++) {
            cells.add((r, c));
          }
        }
      case HouseType.row:
        for (int c = 0; c < 9; c++) {
          cells.add((index, c));
        }
      case HouseType.column:
        for (int r = 0; r < 9; r++) {
          cells.add((r, index));
        }
    }
    return cells;
  }

  Set<int> _computeCandidatesForCell(Board board, int row, int col) {
    final candidates = <int>{1, 2, 3, 4, 5, 6, 7, 8, 9};
    // Remove digits in same row.
    for (int c = 0; c < 9; c++) {
      final v = board.getCell(row, c).value;
      if (v != 0) candidates.remove(v);
    }
    // Remove digits in same column.
    for (int r = 0; r < 9; r++) {
      final v = board.getCell(r, col).value;
      if (v != 0) candidates.remove(v);
    }
    // Remove digits in same box.
    final boxR = (row ~/ 3) * 3;
    final boxC = (col ~/ 3) * 3;
    for (int r = boxR; r < boxR + 3; r++) {
      for (int c = boxC; c < boxC + 3; c++) {
        final v = board.getCell(r, c).value;
        if (v != 0) candidates.remove(v);
      }
    }
    return candidates;
  }

  void _applyStep(Board board, SolveStep step) {
    for (final p in step.placements) {
      board.getCell(p.row, p.col).setValue(p.value);
      for (final peer in board.peers(p.row, p.col)) {
        peer.removeCandidate(p.value);
      }
    }
    for (final e in step.eliminations) {
      board.getCell(e.row, e.col).removeCandidate(e.value);
    }
  }

  void _clearSelection() {
    setState(() {
      _activeNumber = null;
      _selectedCell = null;
    });
  }

  void _onCellTap(int row, int col) {
    if (_gameOver || _loading) return;
    final challenge = _challenge!;
    final pos = (row, col);

    // Tapping a non-target cell clears selection / numpad mode.
    if (!challenge.emptyCells.contains(pos)) {
      _clearSelection();
      return;
    }

    if (_activeNumber != null) {
      // Number-first mode: toggle this number in the tapped cell.
      setState(() {
        final candidates = _playerCandidates[pos]!;
        if (candidates.contains(_activeNumber!)) {
          candidates.remove(_activeNumber!);
        } else {
          candidates.add(_activeNumber!);
        }
      });
    } else {
      // Cell-first mode: select/deselect the cell.
      setState(() {
        if (_selectedCell == pos) {
          _selectedCell = null;
        } else {
          _selectedCell = pos;
        }
      });
    }
  }

  void _onNumberTap(int value) {
    if (_gameOver || _loading) return;

    if (_selectedCell != null) {
      // Cell-first mode: toggle candidate in the selected cell.
      setState(() {
        final candidates = _playerCandidates[_selectedCell!]!;
        if (candidates.contains(value)) {
          candidates.remove(value);
        } else {
          candidates.add(value);
        }
      });
    } else {
      // Number-first mode: toggle active number.
      setState(() {
        if (_activeNumber == value) {
          _activeNumber = null;
        } else {
          _activeNumber = value;
        }
      });
    }
  }

  void _onSubmit() {
    if (_gameOver || _loading) return;
    final challenge = _challenge!;

    // Check if all candidates match.
    bool allCorrect = true;
    for (final cell in challenge.emptyCells) {
      final player = _playerCandidates[cell] ?? {};
      final correct = challenge.correctCandidates[cell]!;
      if (!player.containsAll(correct) || !correct.containsAll(player)) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      setState(() {
        _score++;
        _timeAllowedMs = widget.mode.timeForRound(_score);
        _loading = true;
      });
      _generateNextChallenge();
    } else {
      _endGame(timedOut: false);
    }
  }

  Future<void> _generateNextChallenge() async {
    _timerController.stop();
    final challenge = await _generateChallenge();
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _loading = false;
      _playerCandidates.clear();
      _activeNumber = null;
      _selectedCell = null;
      for (final cell in challenge.emptyCells) {
        _playerCandidates[cell] = {};
      }
    });
    _timerController.duration = Duration(milliseconds: _timeAllowedMs);
    _timerController.forward(from: 0.0);
  }

  void _endGame({required bool timedOut}) async {
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

    final key = TrainingStorageService.candidateFillKey(widget.mode);
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
        builder: (_) => CandidateFillResultsScreen(
          score: score,
          rank: rank,
          mode: widget.mode,
          timedOut: timedOut,
          challenge: _challenge!,
          playerCandidates: Map.fromEntries(
            _playerCandidates.entries
                .map((e) => MapEntry(e.key, Set<int>.from(e.value))),
          ),
          settings: widget.settings,
          trainingStorage: widget.trainingStorage,
        ),
      ),
    );
  }

  String _buildPrompt() {
    final challenge = _challenge!;
    final houseLabel = switch (challenge.houseType) {
      HouseType.box => 'Box ${challenge.houseIndex + 1}',
      HouseType.row => 'Row ${challenge.houseIndex + 1}',
      HouseType.column => 'Column ${challenge.houseIndex + 1}',
    };
    return 'Fill candidates for $houseLabel';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Fill'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timerController.stop();
            _totalStopwatch.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: GestureDetector(
        onTap: _clearSelection,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
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

            // Number pad + Submit.
            _buildNumberPad(context),

            // Streak label.
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
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
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              final pos = (row, col);
              final value = challenge.boardValues[row][col];
              final isEmpty = value == 0;
              final isInRegion = challenge.regionCells.contains(pos);
              final isTargetEmpty = challenge.emptyCells.contains(pos);
              final isSelected = _selectedCell == pos;
              final given = challenge.isGiven[row][col];

              // Background color.
              Color bg;
              if (isSelected) {
                bg = colorScheme.primaryContainer;
              } else if (isInRegion) {
                bg = colorScheme.primary.withValues(alpha: 0.1);
              } else {
                bg = colorScheme.surface;
              }

              // Dim non-region cells slightly.
              final double textOpacity = isInRegion ? 1.0 : 0.4;

              // Cell content.
              Widget cellContent;
              if (isTargetEmpty) {
                // Show player's candidates as a 3x3 mini grid.
                final candidates = _playerCandidates[pos] ?? {};
                cellContent = _buildCandidateGrid(
                    context, candidates, isSelected);
              } else if (isEmpty) {
                cellContent = const SizedBox.shrink();
              } else {
                cellContent = Center(
                  child: FittedBox(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            given ? FontWeight.w600 : FontWeight.w400,
                        color: colorScheme.onSurface
                            .withValues(alpha: textOpacity),
                      ),
                    ),
                  ),
                );
              }

              // Borders.
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

              return GestureDetector(
                onTap: () => _onCellTap(row, col),
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

  Widget _buildCandidateGrid(
      BuildContext context, Set<int> candidates, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: List.generate(9, (i) {
          final digit = i + 1;
          final isPresent = candidates.contains(digit);
          final isActive = _activeNumber == digit;

          return Center(
            child: Text(
              isPresent ? '$digit' : '',
              style: TextStyle(
                fontSize: 7,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumberPad(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          // Row 1: digits 1-5.
          Row(
            children: [
              for (int i = 1; i <= 5; i++) ...[
                Expanded(child: _digitButton(context, i)),
                if (i < 5) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: digits 6-9 + submit.
          Row(
            children: [
              for (int i = 6; i <= 9; i++) ...[
                Expanded(child: _digitButton(context, i)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: _submitButton(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _digitButton(BuildContext context, int value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _activeNumber == value;

    return Material(
      color: isActive
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onNumberTap(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _onSubmit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            Icons.check_rounded,
            color: colorScheme.onPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
