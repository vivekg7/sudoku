import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'number_rush_screen.dart';

class NumberRushResultsScreen extends StatelessWidget {
  final TrainingScore score;
  final int? rank; // 1-based rank, or null if didn't make the board.
  final NumberRushMode mode;
  final int? wrongAnswer;
  final int correctAnswer;
  final List<int?>? challenge; // The house cells (shown if wrong answer).
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const NumberRushResultsScreen({
    super.key,
    required this.score,
    required this.rank,
    required this.mode,
    required this.wrongAnswer,
    required this.correctAnswer,
    required this.challenge,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Rush'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game over header.
                if (wrongAnswer != null)
                  Icon(
                    Icons.close_rounded,
                    size: 48,
                    color: colorScheme.error,
                  )
                else
                  Icon(
                    Icons.timer_off_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                const SizedBox(height: 8),
                Text(
                  wrongAnswer != null ? 'Wrong Answer' : 'Time\'s Up',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                // Streak score.
                Text(
                  '${score.streak}',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score.streak == 1 ? 'correct answer' : 'correct answers',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
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
                    const SizedBox(width: 16),
                    if (score.streak > 0)
                      _statChip(
                        context,
                        label: 'Avg',
                        value:
                            '${score.avgTimePerAnswer.toStringAsFixed(1)}s',
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Wrong answer detail.
                if (wrongAnswer != null && challenge != null) ...[
                  _buildWrongAnswerDetail(context),
                  const SizedBox(height: 24),
                ],

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

  Widget _buildWrongAnswerDetail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCircular = settings.boardLayout == BoardLayout.circular;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: colorScheme.outlineVariant),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'You tapped '),
              TextSpan(
                text: '$wrongAnswer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.error,
                ),
              ),
              const TextSpan(text: ', the answer was '),
              TextSpan(
                text: '$correctAnswer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Show the house with the missing cell highlighted.
        SizedBox(
          width: 180,
          height: 180,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final value = challenge![index];
              final isEmpty = value == null;
              final bg = isEmpty
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerLow;
              final shape = isCircular
                  ? const CircleBorder()
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6));

              return Material(
                color: bg,
                shape: shape,
                child: Center(
                  child: Text(
                    isEmpty ? '$correctAnswer' : '$value',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          isEmpty ? FontWeight.w700 : FontWeight.w400,
                      color: isEmpty
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _playAgain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NumberRushScreen(
          mode: mode,
          settings: settings,
          trainingStorage: trainingStorage,
        ),
      ),
    );
  }

  void _backToTraining(BuildContext context) {
    // Pop back to the training hub (which is two screens back: results → game → hub).
    // Since we used pushReplacement for the results, we just pop once.
    Navigator.of(context).pop();
  }
}
