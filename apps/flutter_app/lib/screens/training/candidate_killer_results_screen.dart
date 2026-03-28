import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import '../strategy_walkthrough_screen.dart';
import 'candidate_killer_screen.dart';

class CandidateKillerResultsScreen extends StatelessWidget {
  final TrainingScore score;
  final int? rank;
  final CandidateKillerMode mode;
  final bool phantom; // true = wrong elimination, false = timeout only
  final bool timedOut;
  final KillerChallenge challenge;
  final Set<(int, int, int)> markedEliminations;
  final Set<(int, int, int)> correctEliminations;
  final List<(StrategyType, int, int)> roundHistory; // (strategy, found, total)
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const CandidateKillerResultsScreen({
    super.key,
    required this.score,
    required this.rank,
    required this.mode,
    required this.phantom,
    required this.timedOut,
    required this.challenge,
    required this.markedEliminations,
    required this.correctEliminations,
    required this.roundHistory,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strategy = challenge.step.strategy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Killer'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header icon.
                Icon(
                  timedOut ? Icons.timer_off_outlined : Icons.close_rounded,
                  size: 48,
                  color: timedOut
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  timedOut ? "Time's Up" : 'Wrong Elimination',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                // Mini board with error overlay.
                _buildErrorBoard(context),
                const SizedBox(height: 16),

                // Strategy name.
                Text(
                  strategy.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),

                // Step description.
                if (challenge.step.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      challenge.step.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),

                // Strategy intro.
                if (strategyGuides.containsKey(strategy))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      strategyGuides[strategy]!.intro,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Learn link.
                if (strategyGuides.containsKey(strategy))
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => StrategyWalkthroughScreen(strategy: strategy),
                    )),
                    child: Text('Learn ${strategy.label} \u2192'),
                  ),
                const SizedBox(height: 16),

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
                  score.streak == 1 ? 'round' : 'rounds',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Leaderboard rank.
                if (rank == 1)
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
                else if (rank != null)
                  Text(
                    '#$rank on the leaderboard',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 16),

                // Stats.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip(context,
                        label: 'Total', value: _formatTime(score.totalTimeMs)),
                    const SizedBox(width: 16),
                    if (score.streak > 0)
                      _statChip(context,
                          label: 'Avg',
                          value:
                              '${score.avgTimePerAnswer.toStringAsFixed(1)}s'),
                  ],
                ),
                const SizedBox(height: 20),

                // Round breakdown.
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
                      for (final (strategy, found, total) in roundHistory)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: found == total
                                ? Colors.green.withValues(alpha: 0.1)
                                : found > 0
                                    ? Colors.amber.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            found == total
                                ? '\u2713 ${strategy.label}'
                                : found > 0
                                    ? '\u21BB ${strategy.label} ($found/$total)'
                                    : '\u2717 ${strategy.label}',
                            style: TextStyle(
                              fontSize: 12,
                              color: found == total
                                  ? Colors.green.shade700
                                  : found > 0
                                      ? Colors.amber.shade800
                                      : Colors.red.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Action buttons.
                SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => CandidateKillerScreen(
                        mode: mode,
                        settings: settings,
                        trainingStorage: trainingStorage,
                      ),
                    )),
                    child: const Text('Play Again'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildErrorBoard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
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
            final cellCandidates = challenge.candidates[index];
            final isHighlighted = challenge.step.involvedCells
                .any((c) => c.row == row && c.col == col);

            Color bg;
            if (isHighlighted) {
              bg = colorScheme.primary.withValues(alpha: 0.1);
            } else {
              bg = colorScheme.surface;
            }

            Widget content;
            if (value == 0 && cellCandidates.isNotEmpty) {
              content = Padding(
                padding: const EdgeInsets.all(0.5),
                child: GridView.count(
                  crossAxisCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: List.generate(9, (i) {
                    final digit = i + 1;
                    if (!cellCandidates.contains(digit)) {
                      return const SizedBox.shrink();
                    }

                    final mark = (row, col, digit);
                    final isCorrectElim = correctEliminations.contains(mark);
                    final isPlayerMarked = markedEliminations.contains(mark);

                    Color textColor;
                    TextDecoration? decoration;

                    if (isPlayerMarked && isCorrectElim) {
                      // Correct mark.
                      textColor = Colors.green;
                      decoration = null;
                    } else if (isPlayerMarked && !isCorrectElim) {
                      // Phantom.
                      textColor = colorScheme.error;
                      decoration = TextDecoration.lineThrough;
                    } else if (!isPlayerMarked && isCorrectElim) {
                      // Missed.
                      textColor = Colors.amber.shade700;
                      decoration = null;
                    } else {
                      // Normal candidate.
                      textColor =
                          colorScheme.onSurface.withValues(alpha: 0.5);
                      decoration = null;
                    }

                    return Center(
                      child: Text(
                        '$digit',
                        style: TextStyle(
                          fontSize: 5.5,
                          fontWeight: (isCorrectElim || isPlayerMarked)
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
            } else if (value != 0) {
              content = Center(
                child: FittedBox(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            } else {
              content = const SizedBox.shrink();
            }

            final borderSide = BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
              child: content,
            );
          },
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context,
      {required String label, required String value}) {
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

  String _formatTime(int ms) {
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final mins = seconds ~/ 60;
    final secs = (seconds % 60).toStringAsFixed(0);
    return '${mins}m ${secs}s';
  }
}
