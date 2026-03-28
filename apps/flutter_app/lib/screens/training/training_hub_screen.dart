import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../../services/training_storage_service.dart';
import 'bulls_and_cows_screen.dart';
import 'candidate_fill_screen.dart';
import 'candidate_killer_screen.dart';
import 'number_rush_screen.dart';
import 'spot_the_pattern_screen.dart';
import 'where_does_n_go_screen.dart';

/// A single mode entry for a training game card.
class _GameMode {
  final String label;
  final String storageKey;
  final VoidCallback onStart;

  const _GameMode({
    required this.label,
    required this.storageKey,
    required this.onStart,
  });
}

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
  // Per-game state: leaderboard expanded + selected mode index.
  final Map<String, bool> _leaderboardExpanded = {};
  final Map<String, int> _selectedModeIndex = {};

  @override
  void initState() {
    super.initState();
    widget.trainingStorage.addListener(_onStorageChanged);
  }

  @override
  void dispose() {
    widget.trainingStorage.removeListener(_onStorageChanged);
    super.dispose();
  }

  void _onStorageChanged() {
    setState(() {
      // Update selected leaderboard mode to match the last played mode.
      final lastKey = widget.trainingStorage.lastPlayedKey;
      if (lastKey != null) {
        for (final entry in _gameModeLists().entries) {
          final modes = entry.value;
          final idx = modes.indexWhere((m) => m.storageKey == lastKey);
          if (idx >= 0) {
            _selectedModeIndex[entry.key] = idx;
            break;
          }
        }
      }
    });
  }

  /// Pick the default mode index for a game based on last played or best score.
  int _pickDefaultMode(List<_GameMode> modes) {
    final lastKey = widget.trainingStorage.lastPlayedKey;
    if (lastKey != null) {
      final idx = modes.indexWhere((m) => m.storageKey == lastKey);
      if (idx >= 0) return idx;
    }

    int bestIdx = 1; // Default to middle mode (Quick).
    int bestStreak = -1;
    for (int i = 0; i < modes.length; i++) {
      final top = widget.trainingStorage.getBest(modes[i].storageKey);
      if (top != null && top.streak > bestStreak) {
        bestStreak = top.streak;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  /// Returns all game mode lists keyed by game key.
  Map<String, List<_GameMode>> _gameModeLists() => {
        'numberRush': _numberRushModes(),
        'whereDoesNGo': _whereDoesNGoModes(),
        'candidateFill': _candidateFillModes(),
        'bullsAndCows': _bullsAndCowsModes(),
        'spotThePattern': _spotThePatternModes(),
        'candidateKiller': _candidateKillerModes(),
      };

  // ── Game definitions ──────────────────────────────────────────────

  List<_GameMode> _numberRushModes() => [
        for (final mode in NumberRushMode.values)
          _GameMode(
            label: mode.label,
            storageKey: TrainingStorageService.numberRushKey(mode),
            onStart: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => NumberRushScreen(
                mode: mode,
                settings: widget.settings,
                trainingStorage: widget.trainingStorage,
              ),
            )),
          ),
      ];

  List<_GameMode> _whereDoesNGoModes() => [
        for (final mode in WhereDoesNGoMode.values)
          _GameMode(
            label: mode.label,
            storageKey: TrainingStorageService.whereDoesNGoKey(mode),
            onStart: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => WhereDoesNGoScreen(
                mode: mode,
                settings: widget.settings,
                trainingStorage: widget.trainingStorage,
              ),
            )),
          ),
      ];

  List<_GameMode> _candidateFillModes() => [
        for (final mode in CandidateFillMode.values)
          _GameMode(
            label: mode.label,
            storageKey: TrainingStorageService.candidateFillKey(mode),
            onStart: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CandidateFillScreen(
                mode: mode,
                settings: widget.settings,
                trainingStorage: widget.trainingStorage,
              ),
            )),
          ),
      ];

  List<_GameMode> _bullsAndCowsModes() => [
        for (final mode in BullsAndCowsMode.values)
          _GameMode(
            label: mode.label,
            storageKey: TrainingStorageService.bullsAndCowsKey(mode),
            onStart: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BullsAndCowsScreen(
                mode: mode,
                settings: widget.settings,
                trainingStorage: widget.trainingStorage,
              ),
            )),
          ),
      ];

  List<_GameMode> _spotThePatternModes() => [
        for (final mode in SpotThePatternMode.values)
          _GameMode(
            label: mode.label,
            storageKey: TrainingStorageService.spotThePatternKey(mode),
            onStart: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SpotThePatternScreen(
                mode: mode,
                settings: widget.settings,
                trainingStorage: widget.trainingStorage,
              ),
            )),
          ),
      ];

  List<_GameMode> _candidateKillerModes() => [
        for (final mode in CandidateKillerMode.values)
          _GameMode(
            label: mode.label,
            storageKey: TrainingStorageService.candidateKillerKey(mode),
            onStart: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CandidateKillerScreen(
                mode: mode,
                settings: widget.settings,
                trainingStorage: widget.trainingStorage,
              ),
            )),
          ),
      ];

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: ListenableBuilder(
        listenable: widget.trainingStorage,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _gameCard(
              context,
              gameKey: 'numberRush',
              icon: Icons.bolt,
              name: 'Number Rush',
              description: 'Find the missing number — as fast as you can.',
              modes: _numberRushModes(),
            ),
            const SizedBox(height: 12),
            _gameCard(
              context,
              gameKey: 'whereDoesNGo',
              icon: Icons.location_searching,
              name: 'Where Does N Go?',
              description: 'Spot the only cell where a digit can go.',
              modes: _whereDoesNGoModes(),
            ),
            const SizedBox(height: 12),
            _gameCard(
              context,
              gameKey: 'candidateFill',
              icon: Icons.grid_on,
              name: 'Candidate Fill',
              description: 'Mark every candidate in a region — perfectly.',
              modes: _candidateFillModes(),
            ),
            const SizedBox(height: 12),
            _gameCard(
              context,
              gameKey: 'bullsAndCows',
              icon: Icons.vpn_key_outlined,
              name: 'Bulls & Cows',
              description: 'Crack a secret code with logic and elimination.',
              modes: _bullsAndCowsModes(),
              scoreLabel: 'guesses',
            ),
            const SizedBox(height: 12),
            _gameCard(
              context,
              gameKey: 'spotThePattern',
              icon: Icons.visibility,
              name: 'Spot the Pattern',
              description: 'Name the strategy \u2014 can you see it?',
              modes: _spotThePatternModes(),
            ),
            const SizedBox(height: 12),
            _gameCard(
              context,
              gameKey: 'candidateKiller',
              icon: Icons.content_cut,
              name: 'Candidate Killer',
              description: 'Find every elimination \u2014 no mistakes allowed.',
              modes: _candidateKillerModes(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Generic game card ─────────────────────────────────────────────

  Widget _gameCard(
    BuildContext context, {
    required String gameKey,
    required IconData icon,
    required String name,
    required String description,
    required List<_GameMode> modes,
    String scoreLabel = 'streak',
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAnyScores = modes.any(
      (m) => widget.trainingStorage.getLeaderboard(m.storageKey).isNotEmpty,
    );
    final expanded = _leaderboardExpanded[gameKey] ?? false;
    final selectedIdx = _selectedModeIndex[gameKey] ?? _pickDefaultMode(modes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header.
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  name,
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
              description,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // Mode buttons.
            Row(
              children: [
                for (int i = 0; i < modes.length; i++) ...[
                  Expanded(
                    child: _modeButton(context, modes[i]),
                  ),
                  if (i < modes.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            // Expandable leaderboard.
            if (hasAnyScores) ...[
              const SizedBox(height: 8),
              _leaderboardToggle(
                context,
                expanded: expanded,
                onToggle: () => setState(() =>
                    _leaderboardExpanded[gameKey] = !expanded),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _leaderboardContent(
                  context,
                  gameKey: gameKey,
                  modes: modes,
                  selectedIdx: selectedIdx,
                  scoreLabel: scoreLabel,
                ),
                crossFadeState: expanded
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

  Widget _modeButton(BuildContext context, _GameMode mode) {
    final colorScheme = Theme.of(context).colorScheme;
    final best = widget.trainingStorage.getBest(mode.storageKey);

    return FilledButton.tonal(
      onPressed: mode.onStart,
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

  // ── Leaderboard ───────────────────────────────────────────────────

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

  Widget _leaderboardContent(
    BuildContext context, {
    required String gameKey,
    required List<_GameMode> modes,
    required int selectedIdx,
    String scoreLabel = 'streak',
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final scores = widget.trainingStorage
        .getLeaderboard(modes[selectedIdx].storageKey);

    return Column(
      children: [
        const SizedBox(height: 4),
        SegmentedButton<int>(
          expandedInsets: EdgeInsets.zero,
          segments: [
            for (int i = 0; i < modes.length; i++)
              ButtonSegment(
                value: i,
                label: Text(
                  modes[i].label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          selected: {selectedIdx},
          onSelectionChanged: (selected) {
            setState(() => _selectedModeIndex[gameKey] = selected.first);
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
              'No scores yet for ${modes[selectedIdx].label}.',
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
            _leaderboardRow(context, i + 1, scores[i],
                scoreLabel: scoreLabel),
          ],
      ],
    );
  }

  Widget _leaderboardRow(
      BuildContext context, int rank, TrainingScore score,
      {String scoreLabel = 'streak'}) {
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
            scoreLabel,
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

  // ── Helpers ───────────────────────────────────────────────────────

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
}
