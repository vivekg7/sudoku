import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'where_does_n_go_screen.dart';

class WhereDoesNGoResultsScreen extends StatelessWidget {
  final TrainingScore score;
  final int? rank;
  final WhereDoesNGoMode mode;
  final ({int row, int col})? wrongCell;
  final WhereDoesNGoChallenge challenge;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const WhereDoesNGoResultsScreen({
    super.key,
    required this.score,
    required this.rank,
    required this.mode,
    required this.wrongCell,
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
        title: const Text('Where Does N Go?'),
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
                // Game over header.
                if (wrongCell != null)
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
                  wrongCell != null ? 'Wrong Cell' : 'Time\'s Up',
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

                // Wrong answer board detail.
                _buildBoardDetail(context),
                const SizedBox(height: 24),

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

  Widget _buildBoardDetail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: colorScheme.outlineVariant),
        const SizedBox(height: 8),
        if (wrongCell != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${challenge.targetDigit} goes in R${challenge.targetRow + 1}C${challenge.targetCol + 1}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (wrongCell == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'The answer was R${challenge.targetRow + 1}C${challenge.targetCol + 1}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        // Mini board showing the answer.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
              ),
              itemCount: 81,
              itemBuilder: (context, index) {
                final row = index ~/ 9;
                final col = index % 9;
                final value = challenge.boardValues[row][col];
                final isEmpty = value == 0;
                final isTarget = row == challenge.targetRow &&
                    col == challenge.targetCol;
                final isWrong = wrongCell != null &&
                    row == wrongCell!.row &&
                    col == wrongCell!.col;

                Color bg;
                if (isTarget) {
                  bg = colorScheme.primary.withValues(alpha: 0.2);
                } else if (isWrong) {
                  bg = colorScheme.error.withValues(alpha: 0.2);
                } else {
                  bg = colorScheme.surface;
                }

                String text;
                Color textColor;
                FontWeight fontWeight;
                if (isTarget) {
                  text = '${challenge.targetDigit}';
                  textColor = colorScheme.primary;
                  fontWeight = FontWeight.w700;
                } else if (isEmpty) {
                  text = '';
                  textColor = colorScheme.onSurface;
                  fontWeight = FontWeight.w400;
                } else {
                  text = '$value';
                  textColor = colorScheme.onSurface.withValues(alpha: 0.6);
                  fontWeight = FontWeight.w400;
                }

                final borderSide = BorderSide(
                  color:
                      colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                );
                final thickSide = BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.5),
                  width: 1.0,
                );

                return Container(
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      top: row % 3 == 0 ? thickSide : borderSide,
                      left: col % 3 == 0 ? thickSide : borderSide,
                      bottom: row == 8 ? thickSide : BorderSide.none,
                      right: col == 8 ? thickSide : BorderSide.none,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: fontWeight,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _playAgain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WhereDoesNGoScreen(
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
