import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'bulls_and_cows_screen.dart';

class BullsAndCowsResultsScreen extends StatelessWidget {
  final TrainingScore score;
  final int? rank;
  final BullsAndCowsMode mode;
  final bool solved;
  final List<int> secret;
  final List<BullsAndCowsGuess> guesses;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const BullsAndCowsResultsScreen({
    super.key,
    required this.score,
    required this.rank,
    required this.mode,
    required this.solved,
    required this.secret,
    required this.guesses,
    required this.settings,
    required this.trainingStorage,
  });

  String _formatTime(int ms) {
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final mins = seconds ~/ 60;
    final secs = (seconds % 60).toStringAsFixed(0);
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNewRecord = rank == 1;
    final madeBoard = rank != null;
    final guessCount = guesses.where((g) => !g.timedOut).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulls & Cows'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header icon.
                if (solved)
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  )
                else
                  Icon(
                    Icons.close_rounded,
                    size: 48,
                    color: colorScheme.error,
                  ),
                const SizedBox(height: 8),
                Text(
                  solved ? 'Cracked it!' : 'Not this time',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                // Main score / secret reveal.
                if (solved) ...[
                  Text(
                    '$guessCount',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guessCount == 1 ? 'guess' : 'guesses',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  // Reveal the secret number.
                  Text(
                    'The number was',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < secret.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${secret[i]}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // Leaderboard rank.
                if (isNewRecord)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'New Record!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                else if (madeBoard)
                  Text(
                    '#$rank on the leaderboard',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 20),

                // Stats row.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip(
                      context,
                      label: 'Total',
                      value: _formatTime(score.totalTimeMs),
                    ),
                    if (guessCount > 0) ...[
                      const SizedBox(width: 16),
                      _statChip(
                        context,
                        label: 'Avg/guess',
                        value: _formatTime(score.totalTimeMs ~/ guessCount),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Guess history.
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  'Guess History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(guesses.length, (i) {
                  final guess = guesses[i];
                  return _buildHistoryRow(context, i, guess);
                }),
                const SizedBox(height: 16),

                // Action buttons.
                SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: () => _playAgain(context),
                    child: const Text('Play Again'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: () => _backToTraining(context),
                    child: const Text('Back to Training'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(
      BuildContext context, int index, BullsAndCowsGuess guess) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFinal = index == guesses.length - 1 && solved;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isFinal
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${index + 1}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (guess.timedOut)
            Expanded(
              child: Text(
                '— timed out —',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            )
          else ...[
            for (int i = 0; i < guess.digits.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Text(
                '${guess.digits[i]}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
            const Spacer(),
            Text(
              '${guess.bulls}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade600,
              ),
            ),
            Text(
              'B ',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade600,
              ),
            ),
            Text(
              '${guess.cows}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.amber.shade700,
              ),
            ),
            Text(
              'C',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _playAgain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BullsAndCowsScreen(
          mode: mode,
          settings: settings,
          trainingStorage: trainingStorage,
        ),
      ),
    );
  }

  void _backToTraining(BuildContext context) {
    Navigator.of(context).pop();
  }
}
