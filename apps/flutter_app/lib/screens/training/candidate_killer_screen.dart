import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'candidate_killer_results_screen.dart';

// ---------------------------------------------------------------------------
// Challenge data
// ---------------------------------------------------------------------------

class KillerChallenge {
  final List<List<int>> boardValues;
  final List<List<bool>> isGiven;
  final List<Set<int>> candidates; // 81 flat sets (solver's candidate grid)
  final SolveStep step; // the strategy step (answer key)
  final Set<(int, int)> highlightCells; // mode-dependent highlighting
  final Set<(int, int)> regionHintCells; // Quick mode: affected houses

  const KillerChallenge({
    required this.boardValues,
    required this.isGiven,
    required this.candidates,
    required this.step,
    this.highlightCells = const {},
    this.regionHintCells = const {},
  });
}

// ---------------------------------------------------------------------------
// Strategy pools (no singles — they produce placements, not eliminations)
// ---------------------------------------------------------------------------

const _chillStrategies = {
  StrategyType.pointingPair,
  StrategyType.pointingTriple,
  StrategyType.boxLineReduction,
  StrategyType.nakedPair,
  StrategyType.hiddenPair,
};

const _quickStrategies = {
  ..._chillStrategies,
  StrategyType.nakedTriple,
  StrategyType.hiddenTriple,
  StrategyType.nakedQuad,
  StrategyType.hiddenQuad,
  StrategyType.xWing,
  StrategyType.swordfish,
};

const _sprintStrategies = {
  ..._quickStrategies,
  StrategyType.jellyfish,
  StrategyType.xyWing,
  StrategyType.xyzWing,
  StrategyType.uniqueRectangleType1,
  StrategyType.uniqueRectangleType2,
  StrategyType.uniqueRectangleType3,
  StrategyType.uniqueRectangleType4,
  StrategyType.simpleColoring,
  StrategyType.xChain,
  StrategyType.xyChain,
  StrategyType.alternatingInferenceChain,
  StrategyType.forcingChain,
  StrategyType.almostLockedSet,
  StrategyType.sueDeCoq,
};

Set<StrategyType> _poolForMode(CandidateKillerMode mode) {
  return switch (mode) {
    CandidateKillerMode.chill => _chillStrategies,
    CandidateKillerMode.quick => _quickStrategies,
    CandidateKillerMode.sprint => _sprintStrategies,
  };
}

List<Difficulty> _difficultiesForMode(CandidateKillerMode mode) {
  return switch (mode) {
    CandidateKillerMode.chill => [Difficulty.easy],
    CandidateKillerMode.quick => [Difficulty.medium],
    CandidateKillerMode.sprint => [
        Difficulty.hard,
        Difficulty.expert,
        Difficulty.master,
      ],
  };
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CandidateKillerScreen extends StatefulWidget {
  final CandidateKillerMode mode;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const CandidateKillerScreen({
    super.key,
    required this.mode,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  State<CandidateKillerScreen> createState() => _CandidateKillerScreenState();
}

class _CandidateKillerScreenState extends State<CandidateKillerScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final _generator = PuzzleGenerator();
  final _solver = Solver();

  KillerChallenge? _challenge;
  int _score = 0;
  int? _bestStreak;
  bool _gameOver = false;
  bool _loading = true;
  bool _showingInterstitial = false;

  // Timer state.
  late int _timeAllowedMs;
  late AnimationController _timerController;
  late Stopwatch _totalStopwatch;

  // Player's marked eliminations: set of (row, col, digit).
  final Set<(int, int, int)> _markedEliminations = {};

  // Input state.
  int? _activeNumber;
  (int, int)? _selectedCell;

  // Repetition avoidance.
  final List<StrategyType> _recentStrategies = [];
  final Map<StrategyType, int> _strategyCounts = {};

  // Round history for results: (strategy, foundCount, totalCount).
  final List<(StrategyType, int, int)> _roundHistory = [];

  // Interstitial state.
  Set<(int, int, int)> _missedEliminations = {};

  @override
  void initState() {
    super.initState();
    final best = widget.trainingStorage.getBest(
      TrainingStorageService.candidateKillerKey(widget.mode),
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
    if (status == AnimationStatus.completed && !_gameOver && !_showingInterstitial) {
      _endGame(phantom: false, timedOut: true);
    }
  }

  Future<void> _generateAndStart() async {
    final challenge = await _generateChallenge();
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _loading = false;
      _markedEliminations.clear();
      _activeNumber = null;
      _selectedCell = null;
      _showingInterstitial = false;
    });
    _totalStopwatch.start();
    _timerController.duration = Duration(milliseconds: _timeAllowedMs);
    _timerController.forward(from: 0.0);
  }

  // ── Generation ──────────────────────────────────────────────────────

  Future<KillerChallenge> _generateChallenge() async {
    final pool = _poolForMode(widget.mode);
    final difficulties = _difficultiesForMode(widget.mode);

    const maxAttempts = 30;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final difficulty = difficulties[_random.nextInt(difficulties.length)];
      final puzzle = _generator.generate(difficulty);
      if (puzzle == null) continue;

      final solveResult = _solver.solve(puzzle.initialBoard);
      if (!solveResult.isSolved) continue;
      if (solveResult.steps.any((s) => s.strategy == StrategyType.backtracking)) {
        continue;
      }

      final workBoard = puzzle.initialBoard.clone();
      computeCandidates(workBoard);

      for (final step in solveResult.steps) {
        if (step.strategy == StrategyType.backtracking ||
            step.strategy == StrategyType.wrongValue) {
          _applyStep(workBoard, step);
          continue;
        }
        if (!pool.contains(step.strategy)) {
          _applyStep(workBoard, step);
          continue;
        }
        // Must have eliminations (not just placements).
        if (step.eliminations.isEmpty) {
          _applyStep(workBoard, step);
          continue;
        }

        // Repetition avoidance.
        if (_recentStrategies.contains(step.strategy) && attempt < maxAttempts - 5) {
          _applyStep(workBoard, step);
          continue;
        }

        // Frequency balancing.
        final count = _strategyCounts[step.strategy] ?? 0;
        final avgCount = _strategyCounts.isEmpty
            ? 0
            : _strategyCounts.values.reduce((a, b) => a + b) /
                _strategyCounts.length;
        if (count > avgCount + 1 && attempt < maxAttempts - 5) {
          _applyStep(workBoard, step);
          continue;
        }

        // Found a match! Snapshot board state.
        return _snapshotChallenge(workBoard, puzzle, step);
      }
    }

    // Fallback: relax all constraints.
    return _generateChallengeFallback();
  }

  Future<KillerChallenge> _generateChallengeFallback() async {
    final pool = _poolForMode(widget.mode);
    final difficulties = _difficultiesForMode(widget.mode);

    while (true) {
      final difficulty = difficulties[_random.nextInt(difficulties.length)];
      final puzzle = _generator.generate(difficulty);
      if (puzzle == null) continue;

      final solveResult = _solver.solve(puzzle.initialBoard);
      if (!solveResult.isSolved) continue;

      final workBoard = puzzle.initialBoard.clone();
      computeCandidates(workBoard);

      for (final step in solveResult.steps) {
        if (!pool.contains(step.strategy) ||
            step.strategy == StrategyType.backtracking ||
            step.strategy == StrategyType.wrongValue ||
            step.eliminations.isEmpty) {
          _applyStep(workBoard, step);
          continue;
        }
        return _snapshotChallenge(workBoard, puzzle, step);
      }
    }
  }

  KillerChallenge _snapshotChallenge(Board workBoard, Puzzle puzzle, SolveStep step) {
    final boardValues = List.generate(
      9,
      (r) => List.generate(9, (c) => workBoard.getCell(r, c).value),
    );
    final isGiven = List.generate(
      9,
      (r) => List.generate(9, (c) => puzzle.initialBoard.getCell(r, c).isFilled),
    );
    final candidates = List.generate(81, (i) {
      final r = i ~/ 9;
      final c = i % 9;
      final cell = workBoard.getCell(r, c);
      return cell.isEmpty ? Set<int>.from(cell.candidates.toList()) : <int>{};
    });

    // Build highlighting based on mode.
    Set<(int, int)> highlightCells = {};
    Set<(int, int)> regionHintCells = {};

    if (widget.mode == CandidateKillerMode.chill) {
      // Highlight pattern cells.
      highlightCells = step.involvedCells.map((c) => (c.row, c.col)).toSet();
    } else if (widget.mode == CandidateKillerMode.quick) {
      // Highlight affected houses (rows/cols/boxes containing eliminations).
      regionHintCells = _computeRegionHint(step.eliminations);
    }

    return KillerChallenge(
      boardValues: boardValues,
      isGiven: isGiven,
      candidates: candidates,
      step: step,
      highlightCells: highlightCells,
      regionHintCells: regionHintCells,
    );
  }

  Set<(int, int)> _computeRegionHint(List<Elimination> eliminations) {
    // Find all rows, columns, and boxes that contain elimination cells.
    final rows = <int>{};
    final cols = <int>{};
    final boxes = <int>{};
    for (final e in eliminations) {
      rows.add(e.row);
      cols.add(e.col);
      boxes.add((e.row ~/ 3) * 3 + (e.col ~/ 3));
    }

    // Highlight cells in affected houses.
    final cells = <(int, int)>{};

    // If eliminations span ≤2 rows, highlight those rows.
    if (rows.length <= 2) {
      for (final r in rows) {
        for (int c = 0; c < 9; c++) {
          cells.add((r, c));
        }
      }
    }
    // If eliminations span ≤2 columns, highlight those columns.
    if (cols.length <= 2) {
      for (final c in cols) {
        for (int r = 0; r < 9; r++) {
          cells.add((r, c));
        }
      }
    }
    // If eliminations span ≤2 boxes, highlight those boxes.
    if (boxes.length <= 2) {
      for (final b in boxes) {
        final startR = (b ~/ 3) * 3;
        final startC = (b % 3) * 3;
        for (int r = startR; r < startR + 3; r++) {
          for (int c = startC; c < startC + 3; c++) {
            cells.add((r, c));
          }
        }
      }
    }

    // Fallback: if nothing matched (eliminations too spread), highlight all
    // elimination cells directly.
    if (cells.isEmpty) {
      for (final e in eliminations) {
        cells.add((e.row, e.col));
      }
    }

    return cells;
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

  // ── Input ───────────────────────────────────────────────────────────

  void _clearSelection() {
    setState(() {
      _activeNumber = null;
      _selectedCell = null;
    });
  }

  void _onCellTap(int row, int col) {
    if (_gameOver || _loading || _showingInterstitial) return;

    // Only empty cells with candidates are tappable.
    final idx = row * 9 + col;
    if (_challenge!.candidates[idx].isEmpty) {
      _clearSelection();
      return;
    }

    if (_activeNumber != null) {
      // Digit-first: toggle this digit in the tapped cell.
      final cellCandidates = _challenge!.candidates[idx];
      if (!cellCandidates.contains(_activeNumber!)) return; // digit not in cell
      setState(() {
        final mark = (row, col, _activeNumber!);
        if (_markedEliminations.contains(mark)) {
          _markedEliminations.remove(mark);
        } else {
          _markedEliminations.add(mark);
        }
      });
    } else {
      // Cell-first: select/deselect.
      setState(() {
        final pos = (row, col);
        if (_selectedCell == pos) {
          _selectedCell = null;
        } else {
          _selectedCell = pos;
        }
      });
    }
  }

  void _onNumberTap(int value) {
    if (_gameOver || _loading || _showingInterstitial) return;

    if (_selectedCell != null) {
      // Cell-first: toggle digit in selected cell.
      final (row, col) = _selectedCell!;
      final idx = row * 9 + col;
      final cellCandidates = _challenge!.candidates[idx];
      if (!cellCandidates.contains(value)) return; // digit not in cell
      setState(() {
        final mark = (row, col, value);
        if (_markedEliminations.contains(mark)) {
          _markedEliminations.remove(mark);
        } else {
          _markedEliminations.add(mark);
        }
      });
    } else {
      // Digit-first: toggle active number.
      setState(() {
        if (_activeNumber == value) {
          _activeNumber = null;
        } else {
          _activeNumber = value;
        }
      });
    }
  }

  // ── Submit & Validation ─────────────────────────────────────────────

  void _onSubmit() {
    if (_gameOver || _loading || _showingInterstitial) return;
    if (_markedEliminations.isEmpty) return;

    final correctSet = _challenge!.step.eliminations
        .map((e) => (e.row, e.col, e.value))
        .toSet();

    // Check for phantoms (player marked something wrong).
    for (final mark in _markedEliminations) {
      if (!correctSet.contains(mark)) {
        // Phantom elimination — game over.
        _roundHistory.add((
          _challenge!.step.strategy,
          _markedEliminations.where((m) => correctSet.contains(m)).length,
          correctSet.length,
        ));
        _endGame(phantom: true, timedOut: false);
        return;
      }
    }

    // All marks are valid. Check if perfect or partial.
    final found = _markedEliminations.length;
    final total = correctSet.length;

    // Track repetition avoidance.
    final strategy = _challenge!.step.strategy;
    _recentStrategies.add(strategy);
    if (_recentStrategies.length > 3) _recentStrategies.removeAt(0);
    _strategyCounts[strategy] = (_strategyCounts[strategy] ?? 0) + 1;

    _roundHistory.add((strategy, found, total));
    _score++;
    _timeAllowedMs = widget.mode.timeForRound(_score);

    if (found == total) {
      // Perfect — next round immediately.
      _timerController.stop();
      setState(() => _loading = true);
      _generateChallenge().then((challenge) {
        if (!mounted || _gameOver) return;
        setState(() {
          _challenge = challenge;
          _loading = false;
          _markedEliminations.clear();
          _activeNumber = null;
          _selectedCell = null;
        });
        _timerController.duration = Duration(milliseconds: _timeAllowedMs);
        _timerController.forward(from: 0.0);
      });
    } else {
      // Partial — show interstitial with missed eliminations.
      _timerController.stop();
      _missedEliminations = correctSet.difference(_markedEliminations);
      setState(() => _showingInterstitial = true);
    }
  }

  void _continueFromInterstitial() {
    setState(() {
      _showingInterstitial = false;
      _loading = true;
      _missedEliminations = {};
    });
    _generateChallenge().then((challenge) {
      if (!mounted || _gameOver) return;
      setState(() {
        _challenge = challenge;
        _loading = false;
        _markedEliminations.clear();
        _activeNumber = null;
        _selectedCell = null;
      });
      _timerController.duration = Duration(milliseconds: _timeAllowedMs);
      _timerController.forward(from: 0.0);
    });
  }

  // ── End Game ────────────────────────────────────────────────────────

  Future<void> _endGame({required bool phantom, required bool timedOut}) async {
    if (_gameOver) return;
    _gameOver = true;
    _timerController.stop();
    _totalStopwatch.stop();

    final score = TrainingScore(
      streak: _score,
      totalTimeMs: _totalStopwatch.elapsedMilliseconds,
      playedAt: DateTime.now(),
    );

    final key = TrainingStorageService.candidateKillerKey(widget.mode);
    widget.trainingStorage.setLastPlayedKey(key);

    final int? rank;
    if (_score > 0) {
      rank = await widget.trainingStorage.addScore(key, score);
    } else {
      await widget.trainingStorage.save();
      rank = null;
    }

    if (!mounted) return;

    final correctSet = _challenge!.step.eliminations
        .map((e) => (e.row, e.col, e.value))
        .toSet();

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => CandidateKillerResultsScreen(
        score: score,
        rank: rank,
        mode: widget.mode,
        phantom: phantom,
        timedOut: timedOut,
        challenge: _challenge!,
        markedEliminations: Set.from(_markedEliminations),
        correctEliminations: correctSet,
        roundHistory: List.from(_roundHistory),
        settings: widget.settings,
        trainingStorage: widget.trainingStorage,
      ),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────

  String _buildPrompt() {
    if (_challenge == null) return '';
    return 'Find the eliminations from ${_challenge!.step.strategy.label}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Killer'),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                    final remaining = 1.0 - _timerController.value;
                    final Color barColor;
                    if (remaining > 0.5) {
                      barColor = colorScheme.primary;
                    } else if (remaining > 0.25) {
                      barColor = Color.lerp(
                          Colors.amber, colorScheme.primary, (remaining - 0.25) / 0.25)!;
                    } else {
                      barColor = Color.lerp(Colors.red, Colors.amber, remaining / 0.25)!;
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

              // Interstitial banner.
              if (_showingInterstitial)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'You missed ${_missedEliminations.length} more elimination${_missedEliminations.length == 1 ? '' : 's'}.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              // Board.
              Expanded(
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : _buildBoard(context),
                ),
              ),

              // Numpad or Continue button.
              if (_showingInterstitial)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _continueFromInterstitial,
                      child: const Text('Continue'),
                    ),
                  ),
                )
              else
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
              final cellCandidates = challenge.candidates[index];
              final isSelected = _selectedCell == pos;
              final given = challenge.isGiven[row][col];
              final isHighlighted = challenge.highlightCells.contains(pos);
              final isRegionHint = challenge.regionHintCells.contains(pos);

              // Background color.
              Color bg;
              if (isSelected) {
                bg = colorScheme.primaryContainer;
              } else if (isHighlighted) {
                bg = colorScheme.primary.withValues(alpha: 0.12);
              } else if (isRegionHint) {
                bg = colorScheme.primary.withValues(alpha: 0.06);
              } else {
                bg = colorScheme.surface;
              }

              // Cell content.
              Widget cellContent;
              if (isEmpty && cellCandidates.isNotEmpty) {
                cellContent = _buildCandidateGrid(context, row, col, cellCandidates);
              } else if (!isEmpty) {
                cellContent = Center(
                  child: FittedBox(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: given ? FontWeight.w600 : FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              } else {
                cellContent = const SizedBox.shrink();
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
                  decoration: BoxDecoration(color: bg, border: border),
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
      BuildContext context, int row, int col, Set<int> cellCandidates) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: List.generate(9, (i) {
          final digit = i + 1;
          if (!cellCandidates.contains(digit)) return const SizedBox.shrink();

          final isMarked = _markedEliminations.contains((row, col, digit));
          final isMissed = _showingInterstitial &&
              _missedEliminations.contains((row, col, digit));
          final isActive = _activeNumber == digit && !_showingInterstitial;

          Color textColor;
          TextDecoration? decoration;

          if (isMarked && _showingInterstitial) {
            // During interstitial: player's correct marks shown in green.
            textColor = Colors.green;
            decoration = null;
          } else if (isMarked) {
            // During gameplay: marked for elimination.
            textColor = colorScheme.error;
            decoration = TextDecoration.lineThrough;
          } else if (isMissed) {
            // Interstitial: missed eliminations in amber.
            textColor = Colors.amber.shade700;
            decoration = null;
          } else if (isActive) {
            textColor = colorScheme.primary;
            decoration = null;
          } else {
            textColor = colorScheme.onSurface.withValues(alpha: 0.7);
            decoration = null;
          }

          return Center(
            child: Text(
              '$digit',
              style: TextStyle(
                fontSize: 7,
                fontWeight: (isActive || isMarked || isMissed)
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: textColor,
                decoration: decoration,
                decorationColor: textColor,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumberPad(BuildContext context) {
    final hasMarks = _markedEliminations.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 1; i <= 5; i++) ...[
                Expanded(child: _digitButton(context, i)),
                if (i < 5) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 6; i <= 9; i++) ...[
                Expanded(child: _digitButton(context, i)),
                const SizedBox(width: 6),
              ],
              Expanded(child: _submitButton(context, enabled: hasMarks)),
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
              color: isActive ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context, {required bool enabled}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: enabled
          ? colorScheme.primary
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? _onSubmit : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            Icons.check_rounded,
            color: enabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
      ),
    );
  }
}
