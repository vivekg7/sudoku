import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sudoku_core/sudoku_core.dart';

/// Data for a single puzzle in the PDF.
class PdfPuzzle {
  final int number;
  final Puzzle puzzle;
  final Hint? hint;
  final String qrData;

  PdfPuzzle({
    required this.number,
    required this.puzzle,
    this.hint,
    required this.qrData,
  });
}

/// Generates PDF documents containing Sudoku puzzles.
class PdfService {
  /// Generate puzzles and build a PDF.
  /// Returns the PDF bytes.
  Future<Uint8List> generatePdf(
    int count,
    Difficulty difficulty, {
    bool includeRoughGrid = false,
  }) async {
    final puzzles = await compute(
      _generatePuzzlesWithHints,
      _GenParams(count, difficulty),
    );
    return _buildPdf(puzzles, includeRoughGrid: includeRoughGrid);
  }

  static List<PdfPuzzle> _generatePuzzlesWithHints(_GenParams params) {
    final generator = PuzzleGenerator(random: Random());
    final hintGen = HintGenerator();
    final puzzles = <PdfPuzzle>[];

    for (var i = 0; i < params.count; i++) {
      Puzzle? puzzle;
      while (puzzle == null) {
        puzzle = generator.generate(params.difficulty);
      }

      final hint = hintGen.generate(puzzle.board);
      final qrData = 'S${params.difficulty.index}${puzzle.initialBoard.toFlatString()}';

      puzzles.add(PdfPuzzle(
        number: i + 1,
        puzzle: puzzle,
        hint: hint,
        qrData: qrData,
      ));
    }
    return puzzles;
  }

  Future<Uint8List> _buildPdf(
    List<PdfPuzzle> puzzles, {
    bool includeRoughGrid = false,
  }) async {
    final doc = pw.Document(
      title: 'Sudoku Puzzles',
      author: 'Sudoku App',
    );

    // Puzzle pages.
    for (final p in puzzles) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) =>
              _buildPuzzlePage(p, includeRoughGrid: includeRoughGrid),
        ),
      );
    }

    // Hints pages.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Text(
            'Hints',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        ),
        build: (context) => [
          for (final p in puzzles) _buildHintEntry(p),
        ],
      ),
    );

    return await doc.save();
  }

  pw.Widget _buildPuzzlePage(
    PdfPuzzle puzzle, {
    bool includeRoughGrid = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Puzzle ${puzzle.number} - ${puzzle.puzzle.difficulty.label}',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Center(child: _buildGrid(puzzle.puzzle.initialBoard)),
        if (includeRoughGrid) ...[
          pw.SizedBox(height: 12),
          pw.Text(
            'Rough work',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(child: _buildEmptyGrid(width: 440, height: 220)),
        ],
        pw.Spacer(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.BarcodeWidget(
                  data: puzzle.qrData,
                  barcode: pw.Barcode.qrCode(),
                  width: 60,
                  height: 60,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Scan to play',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildGrid(Board board, [double gridSize = 360.0]) {
    final cellSize = gridSize / 9;

    return pw.Container(
      width: gridSize,
      height: gridSize,
      child: pw.Table(
        border: pw.TableBorder.all(width: 2.0),
        defaultColumnWidth: const pw.FlexColumnWidth(),
        children: [
          for (var boxRow = 0; boxRow < 3; boxRow++)
            pw.TableRow(
              children: [
                for (var boxCol = 0; boxCol < 3; boxCol++)
                  _buildBox(board, boxRow, boxCol, cellSize),
              ],
            ),
        ],
      ),
    );
  }

  /// An empty 9x9 grid for rough work (rectangular).
  pw.Widget _buildEmptyGrid({double width = 360, double height = 360}) {
    final cellW = width / 9;
    final cellH = height / 9;

    return pw.Container(
      width: width,
      height: height,
      child: pw.Table(
        border: pw.TableBorder.all(width: 2.0),
        defaultColumnWidth: const pw.FlexColumnWidth(),
        children: [
          for (var boxRow = 0; boxRow < 3; boxRow++)
            pw.TableRow(
              children: [
                for (var boxCol = 0; boxCol < 3; boxCol++)
                  pw.Table(
                    border: pw.TableBorder.all(
                        width: 0.5, color: PdfColors.grey400),
                    defaultColumnWidth: const pw.FlexColumnWidth(),
                    children: [
                      for (var r = 0; r < 3; r++)
                        pw.TableRow(
                          children: [
                            for (var c = 0; c < 3; c++)
                              pw.Container(width: cellW, height: cellH),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildBox(Board board, int boxRow, int boxCol, double cellSize) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      defaultColumnWidth: const pw.FlexColumnWidth(),
      children: [
        for (var r = 0; r < 3; r++)
          pw.TableRow(
            children: [
              for (var c = 0; c < 3; c++)
                _buildCell(
                  board,
                  boxRow * 3 + r,
                  boxCol * 3 + c,
                  cellSize,
                ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildCell(Board board, int row, int col, double cellSize) {
    final cell = board.getCell(row, col);
    return pw.Container(
      width: cellSize,
      height: cellSize,
      alignment: pw.Alignment.center,
      child: cell.isGiven
          ? pw.Text(
              '${cell.value}',
              style: pw.TextStyle(
                fontSize: cellSize * 0.55,
                fontWeight: pw.FontWeight.bold,
              ),
            )
          : pw.SizedBox(),
    );
  }

  pw.Widget _buildHintEntry(PdfPuzzle puzzle) {
    final hint = puzzle.hint;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Puzzle ${puzzle.number} (${puzzle.puzzle.difficulty.label})',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          if (hint != null) ...[
            _hintLine('Nudge', hint.nudge),
            _hintLine('Strategy', hint.strategyHint),
            _hintLine('Answer', hint.answer),
          ] else
            pw.Text(
              'No hint available',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        ],
      ),
    );
  }

  pw.Widget _hintLine(String label, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.TextSpan(
              text: text,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenParams {
  final int count;
  final Difficulty difficulty;
  const _GenParams(this.count, this.difficulty);
}
