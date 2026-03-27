import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'candidate_fill_screen.dart';

/// Describes a single candidate error.
class _CandidateError {
  final int row;
  final int col;
  final int digit;
  final bool isMissed; // true = missed, false = phantom
  final String reason;

  const _CandidateError({
    required this.row,
    required this.col,
    required this.digit,
    required this.isMissed,
    required this.reason,
  });
}

class CandidateFillResultsScreen extends StatelessWidget {
  final TrainingScore score;
  final int? rank;
  final CandidateFillMode mode;
  final bool timedOut;
  final CandidateFillChallenge challenge;
  final Map<(int, int), Set<int>> playerCandidates;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const CandidateFillResultsScreen({
    super.key,
    required this.score,
    required this.rank,
    required this.mode,
    required this.timedOut,
    required this.challenge,
    required this.playerCandidates,
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

  /// Compute all errors between player candidates and correct candidates.
  List<_CandidateError> _computeErrors() {
    final errors = <_CandidateError>[];

    for (final cell in challenge.emptyCells) {
      final (row, col) = cell;
      final correct = challenge.correctCandidates[cell]!;
      final player = playerCandidates[cell] ?? {};

      // Missed candidates (correct but player didn't enter).
      for (final digit in correct) {
        if (!player.contains(digit)) {
          errors.add(_CandidateError(
            row: row,
            col: col,
            digit: digit,
            isMissed: true,
            reason: _buildMissedReason(digit, row, col),
          ));
        }
      }

      // Phantom candidates (player entered but incorrect).
      for (final digit in player) {
        if (!correct.contains(digit)) {
          errors.add(_CandidateError(
            row: row,
            col: col,
            digit: digit,
            isMissed: false,
            reason: _buildPhantomReason(digit, row, col),
          ));
        }
      }
    }

    return errors;
  }

  String _buildMissedReason(int digit, int row, int col) {
    return 'You missed $digit in R${row + 1}C${col + 1} — '
        'no $digit in row ${row + 1}, column ${col + 1}, or box ${_boxIndex(row, col) + 1}.';
  }

  String _buildPhantomReason(int digit, int row, int col) {
    // Find which house already contains this digit.
    final board = challenge.boardValues;

    // Check row.
    for (int c = 0; c < 9; c++) {
      if (board[row][c] == digit) {
        return '$digit can\'t go in R${row + 1}C${col + 1} — '
            '$digit is already in row ${row + 1}.';
      }
    }
    // Check column.
    for (int r = 0; r < 9; r++) {
      if (board[r][col] == digit) {
        return '$digit can\'t go in R${row + 1}C${col + 1} — '
            '$digit is already in column ${col + 1}.';
      }
    }
    // Check box.
    final boxR = (row ~/ 3) * 3;
    final boxC = (col ~/ 3) * 3;
    for (int r = boxR; r < boxR + 3; r++) {
      for (int c = boxC; c < boxC + 3; c++) {
        if (board[r][c] == digit) {
          return '$digit can\'t go in R${row + 1}C${col + 1} — '
              '$digit is already in box ${_boxIndex(row, col) + 1}.';
        }
      }
    }
    return '$digit is not a valid candidate for R${row + 1}C${col + 1}.';
  }

  int _boxIndex(int row, int col) => (row ~/ 3) * 3 + (col ~/ 3);

  /// Count total correct, missed, phantom candidates.
  ({int total, int correct, int missed, int phantom}) _computeSummary() {
    int total = 0;
    int correct = 0;
    int missed = 0;
    int phantom = 0;

    for (final cell in challenge.emptyCells) {
      final correctSet = challenge.correctCandidates[cell]!;
      final playerSet = playerCandidates[cell] ?? {};

      total += correctSet.length;
      for (final d in correctSet) {
        if (playerSet.contains(d)) {
          correct++;
        } else {
          missed++;
        }
      }
      for (final d in playerSet) {
        if (!correctSet.contains(d)) {
          phantom++;
        }
      }
    }

    return (total: total, correct: correct, missed: missed, phantom: phantom);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNewRecord = rank == 1;
    final madeBoard = rank != null;
    final errors = timedOut ? <_CandidateError>[] : _computeErrors();
    final summary = _computeSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Fill'),
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
                if (timedOut)
                  Icon(
                    Icons.timer_off_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  )
                else
                  Icon(
                    Icons.close_rounded,
                    size: 48,
                    color: colorScheme.error,
                  ),
                const SizedBox(height: 8),
                Text(
                  timedOut ? 'Time\'s Up' : 'Not Quite Right',
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
                  score.streak == 1 ? 'perfect region' : 'perfect regions',
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

                // Error breakdown.
                if (!timedOut && errors.isNotEmpty) ...[
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  // Summary line.
                  Text(
                    '${summary.missed} missed, ${summary.phantom} phantom — '
                    '${summary.correct} of ${summary.total} candidates correct '
                    '(${summary.total > 0 ? (summary.correct * 100 ~/ summary.total) : 0}%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Mini board with error overlay.
                  _buildErrorBoard(context),
                  const SizedBox(height: 12),
                  // Per-error explanations.
                  ...errors.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              e.isMissed
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              size: 16,
                              color: e.isMissed
                                  ? Colors.green
                                  : colorScheme.error,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.reason,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                ],

                // Timed out — show correct candidates.
                if (timedOut) ...[
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s what the candidates should be:',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCorrectBoard(context),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 8),

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

  /// Mini board showing errors: correct candidates normal, missed in green,
  /// phantoms in red with strikethrough.
  Widget _buildErrorBoard(BuildContext context) {
    return _buildMiniBoardWithCandidates(
      context,
      candidatesFor: (row, col) {
        final pos = (row, col);
        if (!challenge.emptyCells.contains(pos)) return null;

        final correct = challenge.correctCandidates[pos]!;
        final player = playerCandidates[pos] ?? {};

        // Build a map of digit → color for display.
        final allDigits = {...correct, ...player};
        return allDigits;
      },
      digitColor: (row, col, digit) {
        final pos = (row, col);
        final correct = challenge.correctCandidates[pos]!;
        final player = playerCandidates[pos] ?? {};

        if (correct.contains(digit) && player.contains(digit)) {
          // Correct.
          return null; // Default color.
        } else if (correct.contains(digit) && !player.contains(digit)) {
          // Missed.
          return Colors.green;
        } else {
          // Phantom.
          return Theme.of(context).colorScheme.error;
        }
      },
    );
  }

  /// Mini board showing correct candidates for timeout case.
  Widget _buildCorrectBoard(BuildContext context) {
    return _buildMiniBoardWithCandidates(
      context,
      candidatesFor: (row, col) {
        final pos = (row, col);
        if (!challenge.emptyCells.contains(pos)) return null;
        return challenge.correctCandidates[pos]!;
      },
      digitColor: (row, col, digit) => null,
    );
  }

  Widget _buildMiniBoardWithCandidates(
    BuildContext context, {
    required Set<int>? Function(int row, int col) candidatesFor,
    required Color? Function(int row, int col, int digit) digitColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
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
            final isInRegion = challenge.regionCells.contains((row, col));
            final candidates = candidatesFor(row, col);

            Color bg;
            if (isInRegion) {
              bg = colorScheme.primary.withValues(alpha: 0.08);
            } else {
              bg = colorScheme.surface;
            }

            Widget content;
            if (candidates != null && candidates.isNotEmpty) {
              // Show candidates as mini grid.
              content = Padding(
                padding: const EdgeInsets.all(0.5),
                child: GridView.count(
                  crossAxisCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: List.generate(9, (i) {
                    final digit = i + 1;
                    if (!candidates.contains(digit)) {
                      return const SizedBox.shrink();
                    }
                    final color = digitColor(row, col, digit);
                    return Center(
                      child: Text(
                        '$digit',
                        style: TextStyle(
                          fontSize: 5.5,
                          fontWeight: FontWeight.w500,
                          color: color ??
                              colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          decoration: color ==
                                  colorScheme.error
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colorScheme.error,
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
                      color: colorScheme.onSurface.withValues(
                          alpha: isInRegion ? 0.7 : 0.4),
                    ),
                  ),
                ),
              );
            } else {
              content = const SizedBox.shrink();
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
              child: content,
            );
          },
        ),
      ),
    );
  }

  void _playAgain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CandidateFillScreen(
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
