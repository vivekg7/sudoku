import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'number_rush_screen.dart';

class TrainingHubScreen extends StatefulWidget {
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const TrainingHubScreen({
    super.key,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  State<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends State<TrainingHubScreen> {
  bool _leaderboardExpanded = false;
  NumberRushMode _selectedLeaderboardMode = NumberRushMode.quick;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: ListenableBuilder(
        listenable: widget.trainingStorage,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _numberRushCard(context),
            const SizedBox(height: 12),
            _lockedGameCard(
              context,
              name: 'Strategy Snap',
              description: 'Apply the right strategy to fill one cell.',
            ),
            const SizedBox(height: 12),
            _lockedGameCard(
              context,
              name: 'Candidate Killer',
              description: 'Spot which candidates can be eliminated.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberRushCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAnyScores = NumberRushMode.values.any((mode) {
      final key = TrainingStorageService.numberRushKey(mode);
      return widget.trainingStorage.getLeaderboard(key).isNotEmpty;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Number Rush',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Find the missing number — as fast as you can.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final mode in NumberRushMode.values) ...[
                  Expanded(
                    child: _modeButton(context, mode),
                  ),
                  if (mode != NumberRushMode.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            // Expandable leaderboard.
            if (hasAnyScores) ...[
              const SizedBox(height: 8),
              _leaderboardToggle(context),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _leaderboardContent(context),
                crossFadeState: _leaderboardExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: widget.settings.animationsEnabled
                    ? const Duration(milliseconds: 250)
                    : Duration.zero,
                sizeCurve: Curves.easeOutCubic,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _leaderboardToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () =>
          setState(() => _leaderboardExpanded = !_leaderboardExpanded),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Icon(
              _leaderboardExpanded
                  ? Icons.expand_less
                  : Icons.expand_more,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final key =
        TrainingStorageService.numberRushKey(_selectedLeaderboardMode);
    final scores = widget.trainingStorage.getLeaderboard(key);

    return Column(
      children: [
        const SizedBox(height: 4),
        // Mode tabs.
        SegmentedButton<NumberRushMode>(
          segments: [
            for (final mode in NumberRushMode.values)
              ButtonSegment(
                value: mode,
                label: Text(
                  mode.label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          selected: {_selectedLeaderboardMode},
          onSelectionChanged: (selected) {
            setState(() => _selectedLeaderboardMode = selected.first);
          },
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 8),
        if (scores.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No scores yet for ${_selectedLeaderboardMode.label}.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (var i = 0; i < scores.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            _leaderboardRow(context, i + 1, scores[i]),
          ],
      ],
    );
  }

  Widget _modeButton(BuildContext context, NumberRushMode mode) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = TrainingStorageService.numberRushKey(mode);
    final best = widget.trainingStorage.getBest(key);

    return FilledButton.tonal(
      onPressed: () => _startNumberRush(context, mode),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mode.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (best != null)
            Text(
              '${best.streak}',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _lockedGameCard(
    BuildContext context, {
    required String name,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock_outline,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardRow(
      BuildContext context, int rank, TrainingScore score) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: rank <= 3 ? FontWeight.w700 : FontWeight.w400,
                color: rank <= 3
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${score.streak}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'streak',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            _formatTime(score.totalTimeMs),
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _relativeDate(score.playedAt),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _startNumberRush(BuildContext context, NumberRushMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NumberRushScreen(
          mode: mode,
          settings: widget.settings,
          trainingStorage: widget.trainingStorage,
        ),
      ),
    );
  }
}
