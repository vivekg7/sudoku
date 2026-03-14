import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/pdf_service.dart';

class PdfExportScreen extends StatefulWidget {
  const PdfExportScreen({super.key});

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  Difficulty _difficulty = Difficulty.medium;
  int _count = 6;
  bool _includeRoughGrid = false;
  bool _includeHints = true;
  Uint8List? _pdfBytes;
  bool _generating = false;
  int _generatedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export PDF'),
        centerTitle: true,
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _savePdf,
              tooltip: 'Save PDF',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printPdf,
              tooltip: 'Print',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _pdfBytes = null),
              tooltip: 'New generation',
            ),
          ],
        ],
      ),
      body: _pdfBytes != null ? _previewView() : _configView(),
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
            const Text(
              'Generate Puzzles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure and export to PDF',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
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
                      backgroundColor: const Color(0xFFE0E0E0),
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _generatedCount < _count
                        ? 'Generating puzzle $_generatedCount of $_count…'
                        : 'Building PDF…',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF757575)),
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

  Widget _previewView() {
    return PdfPreview(
      build: (_) => _pdfBytes!,
      pdfFileName: _pdfFileName,
      allowPrinting: false,
      allowSharing: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      useActions: false,
    );
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
        onProgress: (completed) {
          if (mounted) setState(() => _generatedCount = completed);
        },
      );
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }

  Future<void> _savePdf() async {
    if (_pdfBytes == null) return;
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Sudoku PDF',
        fileName: _pdfFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: _pdfBytes!,
      );
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.sharePdf(
          bytes: _pdfBytes!, filename: _pdfFileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }
}
