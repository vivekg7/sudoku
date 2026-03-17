import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/pdf_service.dart';
import '../services/settings_service.dart';

class PdfExportScreen extends StatefulWidget {
  final SettingsService settings;

  const PdfExportScreen({super.key, required this.settings});

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  Difficulty _difficulty = Difficulty.medium;
  int _count = 6;
  bool _includeRoughGrid = false;
  bool _includeHints = true;
  bool _generating = false;
  int _generatedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export PDF')),
      body: _configView(),
    );
  }

  Widget _configView() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Generate Puzzles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure and export to PDF',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              child: DropdownMenu<Difficulty>(
                initialSelection: _difficulty,
                label: const Text('Difficulty'),
                expandedInsets: EdgeInsets.zero,
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                menuStyle: MenuStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onSelected: (d) {
                  if (d != null) setState(() => _difficulty = d);
                },
                dropdownMenuEntries: [
                  for (final d in Difficulty.values)
                    DropdownMenuEntry(value: d, label: d.label),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Puzzles', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                IconButton.filled(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed:
                      _count > 1 ? () => setState(() => _count--) : null,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed:
                      _count < 20 ? () => setState(() => _count++) : null,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              child: SwitchListTile(
                title: const Text('Rough work grid',
                    style: TextStyle(fontSize: 14)),
                value: _includeRoughGrid,
                onChanged: (v) => setState(() => _includeRoughGrid = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            SizedBox(
              width: 220,
              child: SwitchListTile(
                title: const Text('Solve order hints',
                    style: TextStyle(fontSize: 14)),
                value: _includeHints,
                onChanged: (v) => setState(() => _includeHints = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 32),
            if (_generating)
              Column(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: _count > 0 ? _generatedCount / _count : null,
                      strokeWidth: 3,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _generatedCount < _count
                        ? 'Generating puzzle $_generatedCount of $_count…'
                        : 'Building PDF…',
                    style: TextStyle(
                        fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              )
            else
              SizedBox(
                width: 220,
                child: FilledButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate PDF'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String get _pdfFileName {
    final parts = <String>[
      'sudoku',
      _difficulty.label.toLowerCase(),
      '${_count}x',
    ];
    if (_includeHints) parts.add('hints');
    if (_includeRoughGrid) parts.add('grid');
    return '${parts.join('_')}.pdf';
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _generatedCount = 0;
    });
    try {
      final bytes = await PdfService().generatePdf(
        _count,
        _difficulty,
        includeRoughGrid: _includeRoughGrid,
        includeHints: _includeHints,
        includeQuotes: widget.settings.quotesEnabled,
        onProgress: (completed) {
          if (mounted) setState(() => _generatedCount = completed);
        },
      );
      if (!mounted) return;
      setState(() => _generating = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PdfPreviewScreen(
            pdfBytes: bytes,
            fileName: _pdfFileName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }
}

class _PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const _PdfPreviewScreen({
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () => _savePdf(context),
            tooltip: 'Save PDF',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printPdf(context),
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(context),
            tooltip: 'Share',
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => pdfBytes,
        pdfFileName: fileName,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        useActions: false,
      ),
    );
  }

  Future<void> _savePdf(BuildContext context) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Sudoku PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: pdfBytes,
      );
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    try {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }
}
