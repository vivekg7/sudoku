import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'number_rush_results_screen.dart';

/// A single Number Rush challenge: a house with one missing digit.
class _RushChallenge {
  final HouseType houseType;
  final List<int?> cells; // 9 cells, one is null (the missing one).
  final int answer;

  _RushChallenge({
    required this.houseType,
    required this.cells,
    required this.answer,
  });
}

class NumberRushScreen extends StatefulWidget {
  final NumberRushMode mode;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const NumberRushScreen({
    super.key,
    required this.mode,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  State<NumberRushScreen> createState() => _NumberRushScreenState();
}

class _NumberRushScreenState extends State<NumberRushScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late _RushChallenge _challenge;
  int _score = 0;
  int? _bestStreak;
  int? _wrongAnswer;
  bool _gameOver = false;

  // Timer state.
  late int _timeAllowedMs;
  late AnimationController _timerController;

  // For total time tracking.
  late Stopwatch _totalStopwatch;

  // Prevent consecutive same answer.
  int _lastAnswer = 0;

  @override
  void initState() {
    super.initState();
    final best =
        widget.trainingStorage.getBest(
          TrainingStorageService.numberRushKey(widget.mode),
        );
    _bestStreak = best?.streak;
    _timeAllowedMs = widget.mode.timeForRound(0);

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _timeAllowedMs),
    );
    _timerController.addStatusListener(_onTimerStatus);

    _totalStopwatch = Stopwatch();
    _nextChallenge();
    _startTimer();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
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

  void _nextChallenge() {
    final types = widget.mode.houseTypes;
    final type = types[_random.nextInt(types.length)];
    final digits = List.generate(9, (i) => i + 1)..shuffle(_random);
    // Pick which index to remove, ensuring answer differs from last.
    int removeIndex = _random.nextInt(9);
    int answer = digits[removeIndex];
    if (answer == _lastAnswer) {
      // Pick a different index.
      removeIndex = (removeIndex + 1 + _random.nextInt(8)) % 9;
      answer = digits[removeIndex];
    }
    _lastAnswer = answer;

    final cells = List<int?>.from(digits);
    cells[removeIndex] = null;

    _challenge = _RushChallenge(
      houseType: type,
      cells: cells,
      answer: answer,
    );
  }

  void _onNumberTap(int value) {
    if (_gameOver) return;
    if (value == _challenge.answer) {
      setState(() {
        _score++;
        _timeAllowedMs = widget.mode.timeForRound(_score);
        _nextChallenge();
      });
      _timerController.duration = Duration(milliseconds: _timeAllowedMs);
      _timerController.forward(from: 0.0);
    } else {
      _endGame(value);
    }
  }

  void _endGame(int? wrongAnswer) {
    _timerController.stop();
    _totalStopwatch.stop();
    setState(() {
      _gameOver = true;
      _wrongAnswer = wrongAnswer;
    });

    final score = TrainingScore(
      streak: _score,
      totalTimeMs: _totalStopwatch.elapsedMilliseconds,
      playedAt: DateTime.now(),
    );

    final key = TrainingStorageService.numberRushKey(widget.mode);
    // Only record scores with at least 1 correct answer.
    final rankFuture = _score > 0
        ? widget.trainingStorage.addScore(key, score)
        : Future<int?>.value(null);

    rankFuture.then((rank) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NumberRushResultsScreen(
            score: score,
            rank: rank,
            mode: widget.mode,
            wrongAnswer: _wrongAnswer,
            correctAnswer: _challenge.answer,
            challenge: _wrongAnswer != null ? _challenge.cells : null,
            settings: widget.settings,
            trainingStorage: widget.trainingStorage,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animationsEnabled = widget.settings.animationsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Rush'),
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
                  final progress = _timerController.value; // 0→1 as time runs
                  final remaining = 1.0 - progress;

                  // Color: accent → yellow → red.
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
                      backgroundColor:
                          colorScheme.surfaceContainerHighest,
                      color: barColor,
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // House display.
            _buildHouse(context),

            const Spacer(),

            // Number pad.
            _buildNumberPad(context, animationsEnabled),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHouse(BuildContext context) {
    if (_challenge.houseType == HouseType.box) {
      return _buildBoxHouse(context);
    }
    return _buildLinearHouse(context);
  }

  Widget _buildBoxHouse(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCircular = widget.settings.boardLayout == BoardLayout.circular;

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final value = _challenge.cells[index];
            return _buildCell(context, value, isCircular, colorScheme);
          },
        ),
      ),
    );
  }

  Widget _buildLinearHouse(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCircular = widget.settings.boardLayout == BoardLayout.circular;
    final label =
        _challenge.houseType == HouseType.row ? 'Row' : 'Column';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < 9; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildCell(
                            context,
                            _challenge.cells[i],
                            isCircular,
                            colorScheme,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    int? value,
    bool isCircular,
    ColorScheme colorScheme,
  ) {
    final isEmpty = value == null;
    final bg = isEmpty
        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerLow;

    final shape = isCircular
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

    return Material(
      color: bg,
      shape: shape,
      child: Center(
        child: isEmpty
            ? Text(
                '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              )
            : Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
      ),
    );
  }

  Widget _buildNumberPad(BuildContext context, bool animationsEnabled) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCircular = widget.settings.boardLayout == BoardLayout.circular;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (var i = 1; i <= 9; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: _rushNumberButton(
                        context, i, isCircular, colorScheme),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rushNumberButton(
    BuildContext context,
    int value,
    bool isCircular,
    ColorScheme colorScheme,
  ) {
    final color = colorScheme.surfaceContainerLow;
    final textColor = colorScheme.onSurface;

    final label = Text(
      '$value',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
    );

    final Widget button;
    if (isCircular) {
      button = AspectRatio(
        aspectRatio: 1.0,
        child: Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            canRequestFocus: false,
            customBorder: const CircleBorder(),
            onTap: _gameOver ? null : () => _onNumberTap(value),
            child: Center(child: label),
          ),
        ),
      );
    } else {
      button = Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(8),
          onTap: _gameOver ? null : () => _onNumberTap(value),
          child: SizedBox(height: 48, child: Center(child: label)),
        ),
      );
    }

    return button;
  }
}
