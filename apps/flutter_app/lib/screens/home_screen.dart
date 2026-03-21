import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/training_storage_service.dart';
import '../widgets/app_logo.dart';
import 'game_screen.dart';
import 'how_to_solve_screen.dart';
import 'pdf_export_screen.dart';
import 'strategy_guide_screen.dart';
import 'saved_games_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'training/training_hub_screen.dart';

class HomeScreen extends StatelessWidget {
  final StorageService storage;
  final SettingsService settings;
  final TrainingStorageService trainingStorage;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.settings,
    required this.trainingStorage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 80),
                const SizedBox(height: 12),
                Text(
                  'Select a difficulty',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                for (final difficulty in Difficulty.values) ...[
                  SizedBox(
                    width: 220,
                    child: Builder(builder: (context) {
                      final colorScheme = Theme.of(context).colorScheme;
                      // 0.0 (Beginner) to 1.0 (Master)
                      final t = difficulty.index /
                          (Difficulty.values.length - 1);
                      final bg = Color.lerp(
                        colorScheme.secondaryContainer,
                        colorScheme.primary.withValues(alpha: 0.10),
                        t,
                      )!;
                      return FilledButton.tonal(
                        onPressed: () => _startGame(context, difficulty),
                        style: FilledButton.styleFrom(
                          backgroundColor: bg,
                          foregroundColor: colorScheme.onSurface,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          difficulty.label,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _navButton(
                      context,
                      icon: Icons.save_outlined,
                      label: 'Saved',
                      onPressed: () => _openSavedGames(context),
                    ),
                    _navButton(
                      context,
                      icon: Icons.bar_chart,
                      label: 'Stats',
                      onPressed: () => _openStats(context),
                    ),
                    _navButton(
                      context,
                      icon: Icons.fitness_center,
                      label: 'Train',
                      onPressed: () => _openTraining(context),
                    ),
                    _navButton(
                      context,
                      icon: Icons.picture_as_pdf,
                      label: 'PDF',
                      onPressed: () => _openPdfExport(context),
                    ),
                    _navButton(
                      context,
                      icon: Icons.qr_code_scanner,
                      label: 'Scan',
                      onPressed: () => _openScan(context),
                    ),
                    _navButton(
                      context,
                      icon: Icons.school_outlined,
                      label: 'Learn',
                      onPressed: () => _openHowToSolve(context),
                    ),
                    _navButton(
                      context,
                      icon: Icons.menu_book_outlined,
                      label: 'Strategies',
                      onPressed: () => _openStrategyGuide(context),
                    ),
                    _navButton(
                      context,
                      icon: Icons.settings,
                      label: 'Settings',
                      onPressed: () => _openSettings(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          icon: Icon(icon),
          onPressed: onPressed,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _startGame(BuildContext context, Difficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: difficulty,
          storage: storage,
          settings: settings,
        ),
      ),
    );
  }

  void _openTraining(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingHubScreen(
          settings: settings,
          trainingStorage: trainingStorage,
        ),
      ),
    );
  }

  void _openHowToSolve(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HowToSolveScreen()),
    );
  }

  void _openStrategyGuide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StrategyGuideScreen()),
    );
  }

  void _openStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StatsScreen(storage: storage)),
    );
  }

  void _openPdfExport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfExportScreen(settings: settings),
      ),
    );
  }

  void _openScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanScreen(storage: storage, settings: settings),
      ),
    );
  }

  void _openSavedGames(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedGamesScreen(
          storage: storage,
          settings: settings,
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settings: settings,
          storage: storage,
        ),
      ),
    );
  }
}
