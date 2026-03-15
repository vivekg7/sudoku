import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsService settings;
  final StorageService storage;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _sectionHeader(context, 'Appearance'),
            _themeTile(context),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _colorTile(context),
            const SizedBox(height: 16),
            _sectionHeader(context, 'Gameplay'),
            _hintLimitTile(context),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: const Text('Show timer'),
              subtitle: const Text('Display elapsed time during play'),
              value: settings.showTimer,
              onChanged: settings.setShowTimer,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: const Text('Show quotes'),
              subtitle: const Text('Display a quote on each puzzle'),
              value: settings.quotesEnabled,
              onChanged: settings.setQuotesEnabled,
            ),
            const SizedBox(height: 16),
            _sectionHeader(context, 'Data'),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Export data'),
              subtitle: const Text('Save stats and puzzles as JSON'),
              onTap: () => _exportData(context),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Import data'),
              subtitle: const Text('Restore from a JSON backup'),
              onTap: () => _importData(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _themeTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Theme'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.settings_brightness, size: 18),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode, size: 18),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode, size: 18),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (s) => settings.setThemeMode(s.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _colorTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Accent color'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final color in AppColor.values)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => settings.setAppColor(color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.seed,
                    shape: BoxShape.circle,
                    border: settings.appColor == color
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2.5,
                          )
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hintLimitTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lightbulb_outline),
      title: const Text('Hints'),
      subtitle: Text(settings.hintLimit.description),
      trailing: SegmentedButton<HintLimit>(
        segments: const [
          ButtonSegment(
            value: HintLimit.disabled,
            icon: Icon(Icons.block, size: 18),
          ),
          ButtonSegment(
            value: HintLimit.nudgeOnly,
            icon: Icon(Icons.lightbulb_outline, size: 18),
          ),
          ButtonSegment(
            value: HintLimit.upToStrategy,
            icon: Icon(Icons.psychology_outlined, size: 18),
          ),
          ButtonSegment(
            value: HintLimit.all,
            icon: Icon(Icons.check_circle_outline, size: 18),
          ),
        ],
        selected: {settings.hintLimit},
        onSelectionChanged: (s) => settings.setHintLimit(s.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
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
        bytes: Uint8List.fromList(utf8.encode(jsonString)),
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
