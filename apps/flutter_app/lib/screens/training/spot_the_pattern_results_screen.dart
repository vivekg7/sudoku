import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import '../../widgets/guide/walkthrough_board_widget.dart';
import '../strategy_walkthrough_screen.dart';
import 'spot_the_pattern_screen.dart';

class SpotThePatternResultsScreen extends StatelessWidget {
  final TrainingScore score;
  final int? rank;
  final SpotThePatternMode mode;
  final StrategyType? wrongAnswer;
  final StrategyType correctStrategy;
  final PatternChallenge challenge;
  final List<(StrategyType, bool)> roundHistory;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const SpotThePatternResultsScreen({
    super.key,
    required this.score,
    required this.rank,
    required this.mode,
    required this.wrongAnswer,
    required this.correctStrategy,
    required this.challenge,
    required this.roundHistory,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTimeout = wrongAnswer == null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Spot the Pattern'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Icon.
              Icon(
                isTimeout ? Icons.timer_off_outlined : Icons.close_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 8),

              // Title.
              Text(
                isTimeout ? "Time's up" : 'Wrong!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),

              // Board with pattern highlighted.
              SizedBox(
                height: 280,
                child: WalkthroughBoardWidget(
                  board: challenge.boardValues,
                  candidates: challenge.candidates,
                  highlightCells: challenge.step.involvedCells
                      .map((c) => (c.row, c.col))
                      .toSet(),
                  eliminateCandidates: challenge.step.eliminations
                      .map((e) => (e.row, e.col, e.value))
                      .toSet(),
                ),
              ),
              const SizedBox(height: 16),

              // Correct strategy name.
              Text(
                correctStrategy.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),

              // Strategy intro text.
              if (strategyGuides.containsKey(correctStrategy))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    strategyGuides[correctStrategy]!.intro,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // What you tapped (if wrong answer, not timeout).
              if (wrongAnswer != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, size: 16, color: colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      'You tapped: ${wrongAnswer!.label}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Learn link.
              if (strategyGuides.containsKey(correctStrategy))
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => StrategyWalkthroughScreen(
                      strategy: correctStrategy,
                    ),
                  )),
                  child: Text('Learn ${correctStrategy.label} \u2192'),
                ),
              const SizedBox(height: 16),

              // Score.
              Text(
                '${score.streak}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                'streak',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Rank.
              if (rank != null) ...[
                if (rank == 1)
                  Text(
                    'New Record!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  )
                else
                  Text(
                    '#$rank on the leaderboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 8),
              ],

              // Stats chips.
              Wrap(
                spacing: 12,
                children: [
                  _statChip(
                    context,
                    'Total',
                    _formatTime(score.totalTimeMs),
                  ),
                  if (score.streak > 0)
                    _statChip(
                      context,
                      'Avg/answer',
                      '${score.avgTimePerAnswer.toStringAsFixed(1)}s',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Strategy breakdown.
              if (roundHistory.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Round breakdown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final (strategy, correct) in roundHistory)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: correct
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${correct ? "\u2713" : "\u2717"} ${strategy.label}',
                          style: TextStyle(
                            fontSize: 12,
                            color: correct
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Action buttons.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to Training'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => SpotThePatternScreen(
                          mode: mode,
                          settings: settings,
                          trainingStorage: trainingStorage,
                        ),
                      )),
                      child: const Text('Play Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final mins = seconds ~/ 60;
    final secs = (seconds % 60).toStringAsFixed(0);
    return '${mins}m ${secs}s';
  }
}
