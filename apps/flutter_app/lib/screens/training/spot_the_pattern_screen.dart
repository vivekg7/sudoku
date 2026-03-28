import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import '../../widgets/guide/walkthrough_board_widget.dart';
import 'spot_the_pattern_results_screen.dart';

// ---------------------------------------------------------------------------
// Challenge data
// ---------------------------------------------------------------------------

class PatternChallenge {
  final List<List<int>> boardValues;
  final List<Set<int>> candidates;
  final List<List<bool>> isGiven;
  final StrategyType correctStrategy;
  final List<StrategyType> options;
  final SolveStep step;

  const PatternChallenge({
    required this.boardValues,
    required this.candidates,
    required this.isGiven,
    required this.correctStrategy,
    required this.options,
    required this.step,
  });
}

// ---------------------------------------------------------------------------
// Strategy pools & sub-families
// ---------------------------------------------------------------------------

const _chillStrategies = {
  StrategyType.hiddenSingle,
  StrategyType.nakedSingle,
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
  StrategyType.jellyfish,
};

const _sprintStrategies = {
  ..._quickStrategies,
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

/// Singles are trivially easy to spot — skip them in Quick and Sprint.
const _singlesOnly = {
  StrategyType.hiddenSingle,
  StrategyType.nakedSingle,
};

const _subFamilies = <String, Set<StrategyType>>{
  'singles': {StrategyType.nakedSingle, StrategyType.hiddenSingle},
  'tuples': {
    StrategyType.nakedPair,
    StrategyType.hiddenPair,
    StrategyType.nakedTriple,
    StrategyType.hiddenTriple,
    StrategyType.nakedQuad,
    StrategyType.hiddenQuad,
  },
  'intersections': {
    StrategyType.pointingPair,
    StrategyType.pointingTriple,
    StrategyType.boxLineReduction,
  },
  'fish': {
    StrategyType.xWing,
    StrategyType.swordfish,
    StrategyType.jellyfish,
  },
  'wings': {StrategyType.xyWing, StrategyType.xyzWing},
  'urs': {
    StrategyType.uniqueRectangleType1,
    StrategyType.uniqueRectangleType2,
    StrategyType.uniqueRectangleType3,
    StrategyType.uniqueRectangleType4,
  },
  'chains': {
    StrategyType.simpleColoring,
    StrategyType.xChain,
    StrategyType.xyChain,
    StrategyType.alternatingInferenceChain,
    StrategyType.forcingChain,
  },
  'advancedSets': {StrategyType.almostLockedSet, StrategyType.sueDeCoq},
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Set<StrategyType> _poolForMode(SpotThePatternMode mode) {
  return switch (mode) {
    SpotThePatternMode.chill => _chillStrategies,
    SpotThePatternMode.quick => _quickStrategies,
    SpotThePatternMode.sprint => _sprintStrategies,
  };
}

/// Whether to skip singles (they're trivial in Quick/Sprint).
bool _skipSingles(SpotThePatternMode mode) =>
    mode != SpotThePatternMode.chill;

/// Difficulty to generate for a given mode.
List<Difficulty> _difficultiesForMode(SpotThePatternMode mode) {
  return switch (mode) {
    SpotThePatternMode.chill => [Difficulty.beginner, Difficulty.easy],
    SpotThePatternMode.quick => [Difficulty.medium],
    SpotThePatternMode.sprint => [
        Difficulty.hard,
        Difficulty.expert,
        Difficulty.master,
      ],
  };
}

/// Returns the sub-family a strategy belongs to, or null.
String? _subFamilyOf(StrategyType s) {
  for (final entry in _subFamilies.entries) {
    if (entry.value.contains(s)) return entry.key;
  }
  return null;
}

/// Returns strategies in the same difficulty tier as [s], within [pool].
Set<StrategyType> _sameTier(StrategyType s, Set<StrategyType> pool) {
  final tier = Solver.classifyDifficulty(s);
  return pool
      .where((t) => t != s && Solver.classifyDifficulty(t) == tier)
      .toSet();
}

/// Returns strategies in the same sub-family as [s], within [pool].
Set<StrategyType> _sameSubFamily(StrategyType s, Set<StrategyType> pool) {
  final family = _subFamilyOf(s);
  if (family == null) return {};
  return pool
      .where((t) => t != s && _subFamilies[family]!.contains(t))
      .toSet();
}

enum _Tightness { wide, sameTier, sameSubFamily }

_Tightness _tightnessForRound(SpotThePatternMode mode, int round) {
  return switch (mode) {
    SpotThePatternMode.chill => round < 5 ? _Tightness.wide : _Tightness.sameTier,
    SpotThePatternMode.quick => round < 3
        ? _Tightness.wide
        : round < 10
            ? _Tightness.sameTier
            : _Tightness.sameSubFamily,
    SpotThePatternMode.sprint => round < 2
        ? _Tightness.wide
        : round < 7
            ? _Tightness.sameTier
            : _Tightness.sameSubFamily,
  };
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SpotThePatternScreen extends StatefulWidget {
  final SpotThePatternMode mode;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const SpotThePatternScreen({
    super.key,
    required this.mode,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  State<SpotThePatternScreen> createState() => _SpotThePatternScreenState();
}

class _SpotThePatternScreenState extends State<SpotThePatternScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final _generator = PuzzleGenerator();
  final _solver = Solver();

  PatternChallenge? _challenge;
  int _score = 0;
  int? _bestStreak;
  bool _gameOver = false;
  bool _loading = true;

  late int _timeAllowedMs;
  late AnimationController _timerController;
  late Stopwatch _totalStopwatch;

  // Repetition avoidance.
  final List<StrategyType> _recentStrategies = [];
  final Map<StrategyType, int> _strategyCounts = {};

  // Round history for results screen.
  final List<(StrategyType, bool)> _roundHistory = [];

  @override
  void initState() {
    super.initState();
    final best = widget.trainingStorage.getBest(
      TrainingStorageService.spotThePatternKey(widget.mode),
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

  Future<void> _generateAndStart() async {
    final challenge = await _generateChallenge();
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _loading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _totalStopwatch.start();
    _timerController.duration = Duration(milliseconds: _timeAllowedMs);
    _timerController.forward(from: 0.0);
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_gameOver) {
      _endGame(null);
    }
  }

  // ── Generation ──────────────────────────────────────────────────────

  Future<PatternChallenge> _generateChallenge() async {
    final pool = _poolForMode(widget.mode);
    final skipSingles = _skipSingles(widget.mode);
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

      // Walk through steps to find a suitable strategy.
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
        if (skipSingles && _singlesOnly.contains(step.strategy)) {
          _applyStep(workBoard, step);
          continue;
        }

        // Check repetition avoidance.
        if (_recentStrategies.contains(step.strategy)) {
          // Allow if we've re-rolled enough already.
          if (attempt < maxAttempts - 5) {
            _applyStep(workBoard, step);
            continue;
          }
        }

        // Frequency balancing: prefer underrepresented strategies.
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

        // Build distractors.
        final distractors = _pickDistractors(step.strategy, _score);
        final options = [step.strategy, ...distractors]..shuffle(_random);

        return PatternChallenge(
          boardValues: boardValues,
          candidates: candidates,
          isGiven: isGiven,
          correctStrategy: step.strategy,
          options: options,
          step: step,
        );
      }
    }

    // Fallback: if we exhausted attempts, relax constraints and try once more.
    return _generateChallengeFallback();
  }

  Future<PatternChallenge> _generateChallengeFallback() async {
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
            step.strategy == StrategyType.wrongValue) {
          _applyStep(workBoard, step);
          continue;
        }

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

        final distractors = _pickDistractors(step.strategy, _score);
        final options = [step.strategy, ...distractors]..shuffle(_random);

        return PatternChallenge(
          boardValues: boardValues,
          candidates: candidates,
          isGiven: isGiven,
          correctStrategy: step.strategy,
          options: options,
          step: step,
        );
      }
    }
  }

  List<StrategyType> _pickDistractors(StrategyType correct, int round) {
    final pool = _poolForMode(widget.mode);
    final tightness = _tightnessForRound(widget.mode, round);

    // Exclude strategies in the same sub-family (may also apply to the board).
    final sameFamily = _sameSubFamily(correct, pool);

    Set<StrategyType> candidates;
    switch (tightness) {
      case _Tightness.sameSubFamily:
        candidates = _sameSubFamily(correct, pool);
        // If sub-family too small (≤2 members), fall back to same tier.
        if (candidates.length < 3) {
          final tierCandidates = _sameTier(correct, pool)
              .difference(sameFamily)
            ..addAll(candidates);
          candidates = tierCandidates;
        }
      case _Tightness.sameTier:
        candidates = _sameTier(correct, pool).difference(sameFamily);
      case _Tightness.wide:
        candidates = pool.where((s) => s != correct).toSet().difference(sameFamily);
    }

    // If still not enough, widen.
    if (candidates.length < 3) {
      final wider = pool.where((s) => s != correct && !sameFamily.contains(s)).toSet();
      candidates = {...candidates, ...wider};
    }
    // Last resort: include sub-family members if absolutely needed.
    if (candidates.length < 3) {
      final all = pool.where((s) => s != correct).toSet();
      candidates = {...candidates, ...all};
    }

    final list = candidates.toList()..shuffle(_random);
    return list.take(3).toList();
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

  // ── Game logic ──────────────────────────────────────────────────────

  void _onOptionTap(StrategyType tapped) {
    if (_gameOver || _challenge == null) return;

    if (tapped == _challenge!.correctStrategy) {
      _roundHistory.add((_challenge!.correctStrategy, true));
      _score++;

      // Track for repetition avoidance.
      _recentStrategies.add(tapped);
      if (_recentStrategies.length > 3) _recentStrategies.removeAt(0);
      _strategyCounts[tapped] = (_strategyCounts[tapped] ?? 0) + 1;

      _timerController.stop();
      _timeAllowedMs = widget.mode.timeForRound(_score);

      setState(() => _loading = true);
      _generateChallenge().then((challenge) {
        if (!mounted || _gameOver) return;
        setState(() {
          _challenge = challenge;
          _loading = false;
        });
        _startTimer();
      });
    } else {
      _roundHistory.add((_challenge!.correctStrategy, false));
      _endGame(tapped);
    }
  }

  Future<void> _endGame(StrategyType? wrongAnswer) async {
    if (_gameOver) return;
    _gameOver = true;
    _timerController.stop();
    _totalStopwatch.stop();

    final score = TrainingScore(
      streak: _score,
      totalTimeMs: _totalStopwatch.elapsedMilliseconds,
      playedAt: DateTime.now(),
    );

    final key = TrainingStorageService.spotThePatternKey(widget.mode);
    widget.trainingStorage.setLastPlayedKey(key);
    final rank = await widget.trainingStorage.addScore(key, score);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SpotThePatternResultsScreen(
        score: score,
        rank: rank,
        mode: widget.mode,
        wrongAnswer: wrongAnswer,
        correctStrategy: _challenge!.correctStrategy,
        challenge: _challenge!,
        roundHistory: _roundHistory,
        settings: widget.settings,
        trainingStorage: widget.trainingStorage,
      ),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animate = widget.settings.animationsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot the Pattern'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loading || _challenge == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Score bar.
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Score: $_score',
                          style: TextStyle(
                            fontSize: 18,
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

                  // Prompt.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Which strategy applies here?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Board.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: WalkthroughBoardWidget(
                        board: _challenge!.boardValues,
                        candidates: _challenge!.candidates,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Timer bar.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedBuilder(
                      animation: _timerController,
                      builder: (context, _) {
                        final progress = _timerController.value;
                        final remaining = 1.0 - progress;
                        Color barColor;
                        if (remaining > 0.5) {
                          barColor = colorScheme.primary;
                        } else if (remaining > 0.25) {
                          barColor = Colors.amber;
                        } else {
                          barColor = Colors.red;
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: remaining,
                            minHeight: 6,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Answer buttons (2×2 grid).
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _optionButton(
                                  _challenge!.options[0], colorScheme, animate),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _optionButton(
                                  _challenge!.options[1], colorScheme, animate),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _optionButton(
                                  _challenge!.options[2], colorScheme, animate),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _optionButton(
                                  _challenge!.options[3], colorScheme, animate),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Streak.
                  Text(
                    '-- streak: $_score --',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Widget _optionButton(
      StrategyType strategy, ColorScheme colorScheme, bool animate) {
    return FilledButton.tonal(
      onPressed: () => _onOptionTap(strategy),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      ),
      child: Text(
        strategy.label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
