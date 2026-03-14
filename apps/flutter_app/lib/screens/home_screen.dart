import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/storage_service.dart';
import 'game_screen.dart';
import 'pdf_export_screen.dart';
import 'saved_games_screen.dart';
import 'scan_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  final StorageService storage;

  const HomeScreen({super.key, required this.storage});

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
                const Text(
                  'Sudoku',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a difficulty',
                  style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _navButton(
                        context,
                        icon: Icons.save_outlined,
                        label: 'Saved',
                        onPressed: () => _openSavedGames(context),
                      ),
                      const SizedBox(width: 16),
                      _navButton(
                        context,
                        icon: Icons.bar_chart,
                        label: 'Stats',
                        onPressed: () => _openStats(context),
                      ),
                      const SizedBox(width: 16),
                      _navButton(
                        context,
                        icon: Icons.picture_as_pdf,
                        label: 'PDF',
                        onPressed: () => _openPdfExport(context),
                      ),
                      const SizedBox(width: 16),
                      _navButton(
                        context,
                        icon: Icons.qr_code_scanner,
                        label: 'Scan',
                        onPressed: () => _openScan(context),
                      ),
                      const SizedBox(width: 16),
                      _navButton(
                        context,
                        icon: Icons.upload_file,
                        label: 'Export',
                        onPressed: () => _exportData(context),
                      ),
                      const SizedBox(width: 16),
                      _navButton(
                        context,
                        icon: Icons.download,
                        label: 'Import',
                        onPressed: () => _importData(context),
                      ),
                    ],
                  ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: const Color(0xFF424242),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
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
        ),
      ),
    );
  }

  void _openStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StatsScreen(storage: storage)),
    );
  }

  void _openPdfExport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PdfExportScreen()),
    );
  }

  void _openScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanScreen(storage: storage)),
    );
  }

  void _openSavedGames(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SavedGamesScreen(storage: storage)),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final jsonString = storage.exportData();
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Sudoku Data',
        fileName: 'sudoku_export.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8Bytes(jsonString),
      );

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Sudoku Data',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;
      final jsonString = await File(path).readAsString();
      await storage.importData(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }
}

/// Convert a string to UTF-8 bytes for file saving.
Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));
