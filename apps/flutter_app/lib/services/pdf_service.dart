import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sudoku_core/sudoku_core.dart';

/// Data for a single puzzle in the PDF.
class PdfPuzzle {
  final int number;
  final Puzzle puzzle;
  final String qrData;

  /// 9x9 grid: 0 = given cell, 1+ = step number when that cell was solved.
  final List<List<int>> solveOrder;

  PdfPuzzle({
    required this.number,
    required this.puzzle,
    required this.qrData,
    required this.solveOrder,
  });
}

/// Generates PDF documents containing Sudoku puzzles.
class PdfService {
  /// Generate puzzles and build a PDF.
  /// Returns the PDF bytes.
  ///
  /// [onProgress] is called each time a puzzle finishes generating, with the
  /// number of completed puzzles so far.
  Future<Uint8List> generatePdf(
    int count,
    Difficulty difficulty, {
    bool includeRoughGrid = false,
    bool includeHints = true,
    void Function(int completed)? onProgress,
  }) async {
    // O3: Generate puzzles in parallel across multiple isolates.
    final puzzles =
        await _generatePuzzlesParallel(count, difficulty, onProgress);
    if (puzzles.isEmpty) {
      throw StateError('Failed to generate puzzles.');
    }
    if (onProgress != null) onProgress(count); // ensure final tick
    return _buildPdf(puzzles,
        includeRoughGrid: includeRoughGrid, includeHints: includeHints);
  }

  /// Spawns multiple isolates to generate puzzles concurrently.
  static Future<List<PdfPuzzle>> _generatePuzzlesParallel(
    int count,
    Difficulty difficulty,
    void Function(int completed)? onProgress,
  ) async {
    if (count <= 1) {
      // Single puzzle — no benefit from parallelism.
      final result = await compute(
        _generatePuzzlesWithHints,
        _GenParams(count, difficulty, 0),
      );
      onProgress?.call(1);
      return result;
    }

    // Split work across isolates. Each isolate generates a subset.
    // Use up to `count` isolates (one per puzzle) since puzzle generation
    // is CPU-bound and benefits from true parallelism.
    var completed = 0;
    final puzzles = List<PdfPuzzle?>.filled(count, null);

    final futures = <Future<void>>[];
    for (var i = 0; i < count; i++) {
      final index = i;
      futures.add(
        compute(
          _generatePuzzlesWithHints,
          _GenParams(1, difficulty, index),
        ).then((batch) {
          puzzles[index] = batch.first;
          completed++;
          onProgress?.call(completed);
        }),
      );
    }

    await Future.wait(futures);

    final result = puzzles.whereType<PdfPuzzle>().toList();

    // Re-number sequentially.
    for (var i = 0; i < result.length; i++) {
      result[i] = PdfPuzzle(
        number: i + 1,
        puzzle: result[i].puzzle,
        qrData: result[i].qrData,
        solveOrder: result[i].solveOrder,
      );
    }
    return result;
  }

  static List<PdfPuzzle> _generatePuzzlesWithHints(_GenParams params) {
    final generator = PuzzleGenerator(random: Random());
    final puzzles = <PdfPuzzle>[];

    for (var i = 0; i < params.count; i++) {
      Puzzle? puzzle;
      while (puzzle == null) {
        puzzle = generator.generate(params.difficulty);
      }

      final qrData =
          'S${params.difficulty.index}${puzzle.initialBoard.toFlatString()}';

      // O4: Use cached solve result from generation if available,
      // otherwise solve again.
      final solveOrder = _solveOrderFromResult(puzzle);

      puzzles.add(PdfPuzzle(
        number: params.startIndex + i + 1,
        puzzle: puzzle,
        qrData: qrData,
        solveOrder: solveOrder,
      ));
    }
    return puzzles;
  }

  /// Extracts solve order from a puzzle's cached solve result, or re-solves
  /// if no cached result is available.
  static List<List<int>> _solveOrderFromResult(Puzzle puzzle) {
    final steps = puzzle.solveResult?.steps ??
        Solver().solve(puzzle.initialBoard).steps;

    final order = List.generate(9, (_) => List.filled(9, 0));
    var stepNum = 0;
    for (final step in steps) {
      for (final p in step.placements) {
        stepNum++;
        order[p.row][p.col] = stepNum;
      }
    }
    return order;
  }

  Future<Uint8List> _buildPdf(
    List<PdfPuzzle> puzzles, {
    bool includeRoughGrid = false,
    bool includeHints = true,
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

    // Hints pages: solve-order grids, 4 per page in a 2x2 layout.
    if (includeHints) {
      for (var i = 0; i < puzzles.length; i += 4) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(30),
            build: (context) {
              final batch = puzzles.sublist(
                  i, (i + 4).clamp(0, puzzles.length));
              return pw.Column(
                children: [
                  pw.Text(
                    'Hints - Solve Order',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Numbers show the order in which cells can be solved',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _buildSolveOrderEntry(batch[0], compact: true),
                              if (batch.length > 2) ...[
                                pw.SizedBox(height: 16),
                                _buildSolveOrderEntry(batch[2],
                                    compact: true),
                              ],
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              if (batch.length > 1)
                                _buildSolveOrderEntry(batch[1],
                                    compact: true),
                              if (batch.length > 3) ...[
                                pw.SizedBox(height: 16),
                                _buildSolveOrderEntry(batch[3],
                                    compact: true),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

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
        _buildQuoteLine(puzzle.puzzle.quoteId),
        pw.SizedBox(height: 16),
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

  pw.Widget _buildQuoteLine(int? quoteId) {
    if (quoteId == null) return pw.SizedBox(height: 4);
    final quote = QuoteRepository.instance.getById(quoteId);
    if (quote == null) return pw.SizedBox(height: 4);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, left: 20, right: 20),
      child: pw.Text(
        '"${quote.text}" - ${quote.author}',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 9,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey700,
        ),
      ),
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

  /// A solve-order grid: shows the step number each cell was solved at.
  pw.Widget _buildSolveOrderEntry(PdfPuzzle puzzle, {bool compact = false}) {
    final gridSize = compact ? 220.0 : 280.0;
    final cellSize = gridSize / 9;
    final board = puzzle.puzzle.initialBoard;
    final order = puzzle.solveOrder;

    return pw.Column(
      children: [
        pw.Text(
          'Puzzle ${puzzle.number} - ${puzzle.puzzle.difficulty.label}',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
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
                      pw.Table(
                        border: pw.TableBorder.all(
                            width: 0.5, color: PdfColors.grey400),
                        defaultColumnWidth: const pw.FlexColumnWidth(),
                        children: [
                          for (var r = 0; r < 3; r++)
                            pw.TableRow(
                              children: [
                                for (var c = 0; c < 3; c++)
                                  _buildOrderCell(
                                    board,
                                    order,
                                    boxRow * 3 + r,
                                    boxCol * 3 + c,
                                    cellSize,
                                  ),
                              ],
                            ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildOrderCell(
    Board board,
    List<List<int>> order,
    int row,
    int col,
    double cellSize,
  ) {
    final isGiven = board.getCell(row, col).isGiven;
    final stepNum = order[row][col];

    return pw.Container(
      width: cellSize,
      height: cellSize,
      alignment: pw.Alignment.center,
      decoration: isGiven
          ? const pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      child: isGiven
          ? pw.SizedBox()
          : pw.Text(
              stepNum > 0 ? '$stepNum' : '',
              style: pw.TextStyle(
                fontSize: cellSize * 0.4,
                color: PdfColors.grey700,
              ),
            ),
    );
  }
}

class _GenParams {
  final int count;
  final Difficulty difficulty;
  final int startIndex;
  const _GenParams(this.count, this.difficulty, this.startIndex);
}
