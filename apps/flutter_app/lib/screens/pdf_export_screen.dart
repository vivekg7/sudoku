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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Generate Puzzles',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Difficulty: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                DropdownButton<Difficulty>(
                  value: _difficulty,
                  onChanged: (d) => setState(() => _difficulty = d!),
                  items: [
                    for (final d in Difficulty.values)
                      DropdownMenuItem(value: d, child: Text(d.label)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Puzzles: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed:
                      _count > 1 ? () => setState(() => _count--) : null,
                ),
                Text(
                  '$_count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed:
                      _count < 20 ? () => setState(() => _count++) : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Rough work grid: ',
                    style: TextStyle(fontSize: 16)),
                Switch(
                  value: _includeRoughGrid,
                  onChanged: (v) => setState(() => _includeRoughGrid = v),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Solve order hints: ',
                    style: TextStyle(fontSize: 16)),
                Switch(
                  value: _includeHints,
                  onChanged: (v) => setState(() => _includeHints = v),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_generating)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Generating puzzles...',
                    style: TextStyle(color: Color(0xFF757575)),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate PDF'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _previewView() {
    return PdfPreview(
      build: (_) => _pdfBytes!,
      pdfFileName: 'sudoku_puzzles.pdf',
      allowPrinting: false,
      allowSharing: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      useActions: false,
    );
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final bytes = await PdfService().generatePdf(
        _count,
        _difficulty,
        includeRoughGrid: _includeRoughGrid,
        includeHints: _includeHints,
      );
      setState(() {
        _pdfBytes = bytes;
        _generating = false;
      });
    } catch (e) {
      setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    }
  }

  Future<void> _savePdf() async {
    if (_pdfBytes == null) return;
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Sudoku PDF',
      fileName: 'sudoku_puzzles.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: _pdfBytes!,
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF saved.')),
      );
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    await Printing.sharePdf(bytes: _pdfBytes!, filename: 'sudoku_puzzles.pdf');
  }
}
