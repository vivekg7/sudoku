import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../widgets/app_logo.dart';
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _sectionHeader(context, 'Appearance'),
            _themeTile(context),
            const Divider(),
            _colorTile(context),
            const Divider(),
            _layoutTile(context),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.animation),
              title: const Text('Animations'),
              value: settings.animationsEnabled,
              onChanged: settings.setAnimationsEnabled,
            ),
            const SizedBox(height: 16),
            _sectionHeader(context, 'Gameplay'),
            _hintLimitTile(context),
            const Divider(),
            ..._assistToggleTiles(context),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.edit_outlined),
              title: const Text('Pencil notes'),
              value: settings.notesEnabled,
              onChanged: settings.setNotesEnabled,
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.timer_outlined),
              title: const Text('Show timer'),
              value: settings.showTimer,
              onChanged: settings.setShowTimer,
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.format_quote_outlined),
              title: const Text('Show quotes'),
              value: settings.quotesEnabled,
              onChanged: settings.setQuotesEnabled,
            ),
            const SizedBox(height: 16),
            _sectionHeader(context, 'Data'),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Export data'),
              onTap: () => _exportData(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Import data'),
              onTap: () => _importData(context),
            ),
            const SizedBox(height: 16),
            _sectionHeader(context, 'About'),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Sudoku'),
              subtitle: const Text('v1.2.0'),
              onTap: () => _showAbout(context),
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
    final colorScheme = Theme.of(context).colorScheme;
    final themeLabel = switch (settings.appThemeMode) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
      AppThemeMode.amoled => 'AMOLED',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.brightness_6_outlined, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme'),
                Text(
                  themeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      icon: Icon(Icons.settings_brightness_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.amoled,
                      icon: Icon(Icons.brightness_1_outlined, size: 18),
                    ),
                  ],
                  selected: {settings.appThemeMode},
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.palette, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Accent color'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in AppColor.values)
                      GestureDetector(
                        onTap: () => settings.setAppColor(color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.seed,
                            shape: BoxShape.circle,
                            border: settings.appColor == color
                                ? Border.all(
                                    color: colorScheme.onSurface,
                                    width: 2.5,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintLimitTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hints'),
                Text(
                  settings.hintLimit.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<HintLimit>(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _assistToggleTiles(BuildContext context) {
    final t = settings.assistToggles;
    return [
      SwitchListTile(
        secondary: const Icon(Icons.grid_on_outlined),
        title: const Text('Highlight row/col/box'),
        value: t.highlightRelated,
        onChanged: (v) =>
            settings.setAssistToggles(t.copyWith(highlightRelated: v)),
      ),
      const Divider(),
      SwitchListTile(
        secondary: const Icon(Icons.filter_1_outlined),
        title: const Text('Highlight same digit'),
        value: t.highlightSameDigit,
        onChanged: (v) =>
            settings.setAssistToggles(t.copyWith(highlightSameDigit: v)),
      ),
      const Divider(),
      SwitchListTile(
        secondary: const Icon(Icons.error_outline),
        title: const Text('Show conflicts'),
        subtitle: const Text('Highlight duplicates in red'),
        value: t.showConflicts,
        onChanged: (v) =>
            settings.setAssistToggles(t.copyWith(showConflicts: v)),
      ),
      const Divider(),
      SwitchListTile(
        secondary: const Icon(Icons.pin_outlined),
        title: const Text('Digit count on numpad'),
        value: t.showRemainingCount,
        onChanged: (v) =>
            settings.setAssistToggles(t.copyWith(showRemainingCount: v)),
      ),
      const Divider(),
      SwitchListTile(
        secondary: const Icon(Icons.auto_fix_high_outlined),
        title: const Text('Auto-remove candidates'),
        subtitle: const Text('Remove from row/col/box peers'),
        value: t.autoRemoveCandidates,
        onChanged: (v) =>
            settings.setAssistToggles(t.copyWith(autoRemoveCandidates: v)),
      ),
      const Divider(),
      SwitchListTile(
        secondary: const Icon(Icons.note_add_outlined),
        title: const Text('Auto-fill notes'),
        subtitle: const Text('Long-press Notes to fill candidates'),
        value: t.autoFillNotes,
        onChanged: (v) =>
            settings.setAssistToggles(t.copyWith(autoFillNotes: v)),
      ),
    ];
  }

  Widget _layoutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.grid_view_rounded),
      title: const Text('Board layout'),
      subtitle: Text(settings.boardLayout.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLayoutPicker(context),
    );
  }

  void _showLayoutPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Board layout',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final layout in BoardLayout.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: layout != BoardLayout.values.last ? 12 : 0,
                      ),
                      child: _layoutCard(ctx, layout, colorScheme),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _layoutCard(
    BuildContext context,
    BoardLayout layout,
    ColorScheme colorScheme,
  ) {
    final isSelected = settings.boardLayout == layout;

    return GestureDetector(
      onTap: () {
        settings.setBoardLayout(layout);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _LayoutPreviewPainter(
                  layout: layout,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              layout.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              layout.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AboutDialog(
        applicationName: 'Sudoku',
        applicationVersion: 'v1.2.0',
        applicationIcon: const AppLogo(size: 48),
        children: const [
          Text(
            'Built by a sudoku nerd, for sudoku nerds.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            'This app teaches you how to think, not just gives you answers. '
            'Every puzzle is generated on the fly with real solving strategies '
            ' - from naked singles to forcing chains.',
          ),
          SizedBox(height: 12),
          Text(
            'No internet. No ads. No tracking. No accounts. '
            'Just you and the puzzle.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 16),
          Text(
            'Philosophy',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text('\u2022 Offline-first \u2014 everything works without internet'),
          Text('\u2022 Respect the player \u2014 hints are layered and intentional'),
          Text('\u2022 Teach, don\'t tell \u2014 guide thinking, not just answers'),
          Text('\u2022 No bloat \u2014 no tracking, no ads, just sudoku'),
          SizedBox(height: 12),
          Text(
            'Licensed under GPLv3.\nhttps://github.com/vivekg7/sudoku',
            style: TextStyle(fontSize: 12),
          ),
        ],
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

class _LayoutPreviewPainter extends CustomPainter {
  final BoardLayout layout;
  final Color color;

  _LayoutPreviewPainter({required this.layout, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 3;

    if (layout == BoardLayout.classic) {
      _paintClassic(canvas, size, cellSize);
    } else {
      _paintCircular(canvas, size, cellSize);
    }
  }

  void _paintClassic(Canvas canvas, Size size, double cellSize) {
    // Outer border.
    final thickPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, thickPaint);

    // Inner grid lines.
    final thinPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    for (var i = 1; i < 3; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), thinPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), thinPaint);
    }
  }

  void _paintCircular(Canvas canvas, Size size, double cellSize) {
    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final radius = cellSize * 0.35;

    // Draw 3x3 circles.
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final center = Offset((c + 0.5) * cellSize, (r + 0.5) * cellSize);
        canvas.drawCircle(center, radius, circlePaint);
      }
    }

    // Tick marks between circles.
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    final tickLen = cellSize * 0.12;

    // Horizontal ticks at row boundaries.
    for (var r = 1; r < 3; r++) {
      final y = r * cellSize;
      for (var c = 0; c < 3; c++) {
        final midX = (c + 0.5) * cellSize;
        canvas.drawLine(Offset(midX - tickLen, y), Offset(midX + tickLen, y), tickPaint);
      }
    }

    // Vertical ticks at column boundaries.
    for (var c = 1; c < 3; c++) {
      final x = c * cellSize;
      for (var r = 0; r < 3; r++) {
        final midY = (r + 0.5) * cellSize;
        canvas.drawLine(Offset(x, midY - tickLen), Offset(x, midY + tickLen), tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_LayoutPreviewPainter oldDelegate) =>
      layout != oldDelegate.layout || color != oldDelegate.color;
}
