import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/settings_service.dart';
import '../widgets/app_logo.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';
import 'how_to_solve_screen.dart';
import 'pdf_export_screen.dart';
import 'strategy_guide_screen.dart';
import 'saved_games_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  final StorageService storage;
  final SettingsService settings;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.settings,
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
                    child: FilledButton.tonal(
                      onPressed: () => _startGame(context, difficulty),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        difficulty.label,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
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
