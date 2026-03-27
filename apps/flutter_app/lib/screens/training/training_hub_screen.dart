import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'candidate_fill_screen.dart';
import 'number_rush_screen.dart';
import 'where_does_n_go_screen.dart';

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
  bool _rushLeaderboardExpanded = false;
  bool _nGoLeaderboardExpanded = false;
  bool _fillLeaderboardExpanded = false;
  late NumberRushMode _selectedRushMode;
  late WhereDoesNGoMode _selectedNGoMode;
  late CandidateFillMode _selectedFillMode;

  @override
  void initState() {
    super.initState();
    _selectedRushMode = _pickDefaultRushMode();
    _selectedNGoMode = _pickDefaultNGoMode();
    _selectedFillMode = _pickDefaultFillMode();
    widget.trainingStorage.addListener(_onStorageChanged);
  }

  @override
  void dispose() {
    widget.trainingStorage.removeListener(_onStorageChanged);
    super.dispose();
  }

  void _onStorageChanged() {
    setState(() {
      final lastRush = widget.trainingStorage.lastPlayedMode;
      if (lastRush != null) _selectedRushMode = lastRush;
      final lastNGo = widget.trainingStorage.lastPlayedWhereDoesNGoMode;
      if (lastNGo != null) _selectedNGoMode = lastNGo;
      final lastFill = widget.trainingStorage.lastPlayedCandidateFillMode;
      if (lastFill != null) _selectedFillMode = lastFill;
    });
  }

  NumberRushMode _pickDefaultRushMode() {
    final last = widget.trainingStorage.lastPlayedMode;
    if (last != null) return last;

    NumberRushMode? best;
    int bestStreak = -1;
    for (final mode in NumberRushMode.values) {
      final key = TrainingStorageService.numberRushKey(mode);
      final top = widget.trainingStorage.getBest(key);
      if (top != null && top.streak > bestStreak) {
        bestStreak = top.streak;
        best = mode;
      }
    }
    return best ?? NumberRushMode.quick;
  }

  WhereDoesNGoMode _pickDefaultNGoMode() {
    final last = widget.trainingStorage.lastPlayedWhereDoesNGoMode;
    if (last != null) return last;

    WhereDoesNGoMode? best;
    int bestStreak = -1;
    for (final mode in WhereDoesNGoMode.values) {
      final key = TrainingStorageService.whereDoesNGoKey(mode);
      final top = widget.trainingStorage.getBest(key);
      if (top != null && top.streak > bestStreak) {
        bestStreak = top.streak;
        best = mode;
      }
    }
    return best ?? WhereDoesNGoMode.quick;
  }

  CandidateFillMode _pickDefaultFillMode() {
    final last = widget.trainingStorage.lastPlayedCandidateFillMode;
    if (last != null) return last;

    CandidateFillMode? best;
    int bestStreak = -1;
    for (final mode in CandidateFillMode.values) {
      final key = TrainingStorageService.candidateFillKey(mode);
      final top = widget.trainingStorage.getBest(key);
      if (top != null && top.streak > bestStreak) {
        bestStreak = top.streak;
        best = mode;
      }
    }
    return best ?? CandidateFillMode.quick;
  }

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
            _whereDoesNGoCard(context),
            const SizedBox(height: 12),
            _candidateFillCard(context),
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
              _leaderboardToggle(
                context,
                expanded: _rushLeaderboardExpanded,
                onToggle: () => setState(
                    () => _rushLeaderboardExpanded = !_rushLeaderboardExpanded),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _rushLeaderboardContent(context),
                crossFadeState: _rushLeaderboardExpanded
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

  Widget _leaderboardToggle(
    BuildContext context, {
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onToggle,
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
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rushLeaderboardContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = TrainingStorageService.numberRushKey(_selectedRushMode);
    final scores = widget.trainingStorage.getLeaderboard(key);

    return Column(
      children: [
        const SizedBox(height: 4),
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
          selected: {_selectedRushMode},
          onSelectionChanged: (selected) {
            setState(() => _selectedRushMode = selected.first);
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
              'No scores yet for ${_selectedRushMode.label}.',
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

  Widget _whereDoesNGoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAnyScores = WhereDoesNGoMode.values.any((mode) {
      final key = TrainingStorageService.whereDoesNGoKey(mode);
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
                Icon(Icons.location_searching,
                    color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Where Does N Go?',
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
              'Spot the only cell where a digit can go.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final mode in WhereDoesNGoMode.values) ...[
                  Expanded(
                    child: _nGoModeButton(context, mode),
                  ),
                  if (mode != WhereDoesNGoMode.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            if (hasAnyScores) ...[
              const SizedBox(height: 8),
              _leaderboardToggle(
                context,
                expanded: _nGoLeaderboardExpanded,
                onToggle: () => setState(
                    () => _nGoLeaderboardExpanded = !_nGoLeaderboardExpanded),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _nGoLeaderboardContent(context),
                crossFadeState: _nGoLeaderboardExpanded
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

  Widget _nGoLeaderboardContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = TrainingStorageService.whereDoesNGoKey(_selectedNGoMode);
    final scores = widget.trainingStorage.getLeaderboard(key);

    return Column(
      children: [
        const SizedBox(height: 4),
        SegmentedButton<WhereDoesNGoMode>(
          segments: [
            for (final mode in WhereDoesNGoMode.values)
              ButtonSegment(
                value: mode,
                label: Text(
                  mode.label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          selected: {_selectedNGoMode},
          onSelectionChanged: (selected) {
            setState(() => _selectedNGoMode = selected.first);
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
              'No scores yet for ${_selectedNGoMode.label}.',
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

  Widget _nGoModeButton(BuildContext context, WhereDoesNGoMode mode) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = TrainingStorageService.whereDoesNGoKey(mode);
    final best = widget.trainingStorage.getBest(key);

    return FilledButton.tonal(
      onPressed: () => _startWhereDoesNGo(context, mode),
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

  Widget _candidateFillCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAnyScores = CandidateFillMode.values.any((mode) {
      final key = TrainingStorageService.candidateFillKey(mode);
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
                Icon(Icons.grid_on, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Candidate Fill',
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
              'Mark every candidate in a region — perfectly.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final mode in CandidateFillMode.values) ...[
                  Expanded(
                    child: _fillModeButton(context, mode),
                  ),
                  if (mode != CandidateFillMode.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            if (hasAnyScores) ...[
              const SizedBox(height: 8),
              _leaderboardToggle(
                context,
                expanded: _fillLeaderboardExpanded,
                onToggle: () => setState(
                    () => _fillLeaderboardExpanded = !_fillLeaderboardExpanded),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _fillLeaderboardContent(context),
                crossFadeState: _fillLeaderboardExpanded
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

  Widget _fillModeButton(BuildContext context, CandidateFillMode mode) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = TrainingStorageService.candidateFillKey(mode);
    final best = widget.trainingStorage.getBest(key);

    return FilledButton.tonal(
      onPressed: () => _startCandidateFill(context, mode),
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

  Widget _fillLeaderboardContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = TrainingStorageService.candidateFillKey(_selectedFillMode);
    final scores = widget.trainingStorage.getLeaderboard(key);

    return Column(
      children: [
        const SizedBox(height: 4),
        SegmentedButton<CandidateFillMode>(
          segments: [
            for (final mode in CandidateFillMode.values)
              ButtonSegment(
                value: mode,
                label: Text(
                  mode.label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          selected: {_selectedFillMode},
          onSelectionChanged: (selected) {
            setState(() => _selectedFillMode = selected.first);
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
              'No scores yet for ${_selectedFillMode.label}.',
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

  void _startWhereDoesNGo(BuildContext context, WhereDoesNGoMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhereDoesNGoScreen(
          mode: mode,
          settings: widget.settings,
          trainingStorage: widget.trainingStorage,
        ),
      ),
    );
  }

  void _startCandidateFill(BuildContext context, CandidateFillMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CandidateFillScreen(
          mode: mode,
          settings: widget.settings,
          trainingStorage: widget.trainingStorage,
        ),
      ),
    );
  }
}
