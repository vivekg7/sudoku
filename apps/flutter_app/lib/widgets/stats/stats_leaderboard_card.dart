import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'stats_card.dart';

/// Top 10 fastest completions with assist-level segmented filter.
class StatsLeaderboardCard extends StatefulWidget {
  final StatsStore store;
  final Difficulty difficulty;

  const StatsLeaderboardCard({
    super.key,
    required this.store,
    required this.difficulty,
  });

  @override
  State<StatsLeaderboardCard> createState() => _StatsLeaderboardCardState();
}

class _StatsLeaderboardCardState extends State<StatsLeaderboardCard> {
  String? _assistFilter; // null = all

  static const _assistLevels = ['none', 'basic', 'standard', 'full'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scores = widget.store.topScores(
      difficulty: widget.difficulty,
      assistLevel: _assistFilter,
    );

    return StatsCard(
      title: 'Leaderboard',
      children: [
        SegmentedButton<String?>(
          segments: [
            const ButtonSegment(
              value: null,
              label: Text('All', maxLines: 1, softWrap: false, overflow: TextOverflow.fade),
            ),
            for (final level in _assistLevels)
              ButtonSegment(
                value: level,
                label: Text(
                  level[0].toUpperCase() + level.substring(1),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
          ],
          selected: {_assistFilter},
          onSelectionChanged: (selection) {
            setState(() => _assistFilter = selection.first);
          },
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 12),
        if (scores.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No scores yet',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          for (var i = 0; i < scores.length; i++)
            _LeaderboardEntry(
              rank: i + 1,
              game: scores[i],
              isPersonalBest: i == 0,
            ),
      ],
    );
  }
}

class _LeaderboardEntry extends StatelessWidget {
  final int rank;
  final GameStats game;
  final bool isPersonalBest;

  const _LeaderboardEntry({
    required this.rank,
    required this.game,
    required this.isPersonalBest,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: isPersonalBest
          ? BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: _rankBadge(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatTime(game.solveTimeSeconds),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            _formatDate(game.playedAt),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          _hintChip(context),
        ],
      ),
    );
  }

  Widget _rankBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (rank <= 3) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: rank == 1
              ? colorScheme.primary
              : rank == 2
                  ? colorScheme.tertiary
                  : colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: rank == 1
                ? colorScheme.onPrimary
                : rank == 2
                    ? colorScheme.onTertiary
                    : colorScheme.onSecondary,
          ),
        ),
      );
    }
    return Text(
      '$rank',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  Widget _hintChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!game.usedHints) {
      return Icon(
        Icons.emoji_events_outlined,
        size: 18,
        color: colorScheme.primary,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${game.totalHints}',
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
