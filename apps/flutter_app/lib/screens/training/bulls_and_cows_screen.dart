import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'bulls_and_cows_results_screen.dart';

/// A single guess and its result.
class BullsAndCowsGuess {
  final List<int> digits;
  final int bulls;
  final int cows;
  final bool timedOut;

  const BullsAndCowsGuess({
    required this.digits,
    required this.bulls,
    required this.cows,
    this.timedOut = false,
  });
}

class BullsAndCowsScreen extends StatefulWidget {
  final BullsAndCowsMode mode;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const BullsAndCowsScreen({
    super.key,
    required this.mode,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  State<BullsAndCowsScreen> createState() => _BullsAndCowsScreenState();
}

class _BullsAndCowsScreenState extends State<BullsAndCowsScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final _scrollController = ScrollController();

  late List<int> _secret;
  final List<BullsAndCowsGuess> _guesses = [];
  final List<int> _currentInput = [];
  bool _solved = false;
  bool _gameOver = false;

  // Timer state.
  AnimationController? _timerController;
  late Stopwatch _totalStopwatch;

  // Best score for display.
  int? _bestGuesses;

  @override
  void initState() {
    super.initState();
    _secret = _generateSecret();
    _totalStopwatch = Stopwatch()..start();

    final best = widget.trainingStorage.getBest(
      TrainingStorageService.bullsAndCowsKey(widget.mode),
    );
    _bestGuesses = best?.streak;

    if (widget.mode.hasTimer) {
      _timerController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.mode.timerMs),
      );
      _timerController!.addStatusListener(_onTimerStatus);
      _timerController!.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _timerController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_gameOver && !_solved) {
      _onTimeout();
    }
  }

  List<int> _generateSecret() {
    if (widget.mode.allowRepeats) {
      return List.generate(4, (_) => _random.nextInt(10));
    }
    final digits = List.generate(10, (i) => i)..shuffle(_random);
    return digits.sublist(0, 4);
  }

  ({int bulls, int cows}) _evaluate(List<int> guess) {
    int bulls = 0;
    // Count occurrences of each digit in secret and guess.
    final secretCounts = List.filled(10, 0);
    final guessCounts = List.filled(10, 0);

    for (int i = 0; i < 4; i++) {
      if (guess[i] == _secret[i]) {
        bulls++;
      } else {
        secretCounts[_secret[i]]++;
        guessCounts[guess[i]]++;
      }
    }

    int cows = 0;
    for (int d = 0; d < 10; d++) {
      cows += min(secretCounts[d], guessCounts[d]);
    }

    return (bulls: bulls, cows: cows);
  }

  void _onDigitTap(int digit) {
    if (_gameOver || _solved) return;
    if (_currentInput.length >= 4) return;

    // In no-repeat modes, prevent duplicate digits in current guess.
    if (!widget.mode.allowRepeats && _currentInput.contains(digit)) return;

    setState(() {
      _currentInput.add(digit);
    });
  }

  void _onBackspace() {
    if (_gameOver || _solved) return;
    if (_currentInput.isEmpty) return;

    setState(() {
      _currentInput.removeLast();
    });
  }

  void _onSubmit() {
    if (_gameOver || _solved) return;
    if (_currentInput.length != 4) return;

    final guess = List<int>.from(_currentInput);
    final result = _evaluate(guess);

    setState(() {
      _guesses.add(BullsAndCowsGuess(
        digits: guess,
        bulls: result.bulls,
        cows: result.cows,
      ));
      _currentInput.clear();
    });

    // Scroll to bottom after adding guess.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    if (result.bulls == 4) {
      _onSolved();
      return;
    }

    if (_guesses.length >= widget.mode.maxGuesses) {
      _endGame(solved: false);
      return;
    }

    // Reset timer for next guess.
    _timerController?.forward(from: 0.0);
  }

  void _onTimeout() {
    // Forfeit the current guess — counts as a wasted turn with no hint.
    setState(() {
      _guesses.add(const BullsAndCowsGuess(
        digits: [],
        bulls: 0,
        cows: 0,
        timedOut: true,
      ));
      _currentInput.clear();
    });

    if (_guesses.length >= widget.mode.maxGuesses) {
      _endGame(solved: false);
      return;
    }

    // Reset timer for next guess.
    _timerController?.forward(from: 0.0);
  }

  void _onSolved() {
    _timerController?.stop();
    _totalStopwatch.stop();
    setState(() {
      _solved = true;
    });

    // Brief delay before showing results.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _navigateToResults(solved: true);
    });
  }

  void _endGame({required bool solved}) async {
    _timerController?.stop();
    _totalStopwatch.stop();
    setState(() {
      _gameOver = true;
    });

    // Brief delay before showing results.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _navigateToResults(solved: solved);
    });
  }

  void _navigateToResults({required bool solved}) async {
    final guessCount = _guesses.where((g) => !g.timedOut).length;
    final score = TrainingScore(
      streak: guessCount, // Reuse streak field for guess count.
      totalTimeMs: _totalStopwatch.elapsedMilliseconds,
      playedAt: DateTime.now(),
    );

    final key = TrainingStorageService.bullsAndCowsKey(widget.mode);
    widget.trainingStorage.setLastPlayedKey(key);

    final int? rank;
    if (solved) {
      rank = await widget.trainingStorage.addScore(
        key,
        score,
        compareFn: TrainingScore.compareLowerBetter,
      );
    } else {
      await widget.trainingStorage.save();
      rank = null;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BullsAndCowsResultsScreen(
          score: score,
          rank: rank,
          mode: widget.mode,
          solved: solved,
          secret: _secret,
          guesses: _guesses,
          settings: widget.settings,
          trainingStorage: widget.trainingStorage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulls & Cows'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timerController?.stop();
            _totalStopwatch.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header row.
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Guess ${_guesses.length + 1} of ${widget.mode.maxGuesses}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (_bestGuesses != null)
                    Text(
                      'Best: $_bestGuesses',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // Timer bar (only for timed modes).
            if (widget.mode.hasTimer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _timerController!,
                  builder: (context, _) {
                    final progress = _timerController!.value;
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

            const SizedBox(height: 8),

            // Prompt.
            Text(
              'Guess the 4-digit number',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            // Guess history + current input.
            Expanded(
              child: _buildGuessHistory(context),
            ),

            // Number pad.
            _buildNumberPad(context),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildGuessHistory(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      itemCount: _guesses.length + (_solved || _gameOver ? 0 : 1),
      itemBuilder: (context, index) {
        if (index < _guesses.length) {
          return _buildGuessRow(context, index, _guesses[index]);
        }
        // Current input row.
        return _buildCurrentInputRow(context);
      },
    );
  }

  Widget _buildGuessRow(
      BuildContext context, int index, BullsAndCowsGuess guess) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSolved = guess.bulls == 4 && !guess.timedOut;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSolved
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (guess.timedOut)
            Expanded(
              child: Text(
                '— timed out —',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            )
          else ...[
            // Digit display.
            for (int i = 0; i < guess.digits.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _digitDisplay(context, guess.digits[i],
                  highlight: isSolved),
            ],
            const Spacer(),
            // Bulls.
            Text(
              '${guess.bulls}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade600,
              ),
            ),
            Text(
              'B',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(width: 10),
            // Cows.
            Text(
              '${guess.cows}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.amber.shade700,
              ),
            ),
            Text(
              'C',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentInputRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${_guesses.length + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ),
          for (int i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            if (i < _currentInput.length)
              _digitDisplay(context, _currentInput[i], highlight: true)
            else
              _emptySlot(context),
          ],
        ],
      ),
    );
  }

  Widget _digitDisplay(BuildContext context, int digit,
      {bool highlight = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$digit',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _emptySlot(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Text(
        '',
        style: TextStyle(
          fontSize: 18,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildNumberPad(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          // Row 1: 1-5.
          Row(
            children: [
              for (int i = 1; i <= 5; i++) ...[
                Expanded(child: _padButton(context, i)),
                if (i < 5) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: 6-9, 0.
          Row(
            children: [
              for (int i = 6; i <= 9; i++) ...[
                Expanded(child: _padButton(context, i)),
                const SizedBox(width: 6),
              ],
              Expanded(child: _padButton(context, 0)),
            ],
          ),
          const SizedBox(height: 6),
          // Row 3: backspace + submit.
          Row(
            children: [
              Expanded(child: _backspaceButton(context)),
              const SizedBox(width: 6),
              Expanded(child: _submitButton(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _padButton(BuildContext context, int digit) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = _currentInput.length >= 4 ||
        (!widget.mode.allowRepeats && _currentInput.contains(digit)) ||
        _solved ||
        _gameOver;

    return Material(
      color: isDisabled
          ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled ? null : () => _onDigitTap(digit),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            '$digit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDisabled
                  ? colorScheme.onSurface.withValues(alpha: 0.3)
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspaceButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = _currentInput.isEmpty || _solved || _gameOver;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled ? null : _onBackspace,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            Icons.backspace_outlined,
            color: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.3)
                : colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = _currentInput.length != 4 || _solved || _gameOver;

    return Material(
      color: isDisabled
          ? colorScheme.primary.withValues(alpha: 0.3)
          : colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled ? null : _onSubmit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            Icons.check_rounded,
            color: isDisabled
                ? colorScheme.onPrimary.withValues(alpha: 0.5)
                : colorScheme.onPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
