import 'cell.dart';

/// A 9x9 Sudoku board.
class Board {
  final List<List<Cell>> _grid;

  Board._(this._grid);

  /// Creates an empty board.
  factory Board.empty() {
    final grid = List.generate(
      9,
      (r) => List.generate(9, (c) => Cell(row: r, col: c)),
    );
    return Board._(grid);
  }

  /// Creates a board from a 2D list of ints (0 = empty).
  /// Non-zero values become givens.
  factory Board.fromValues(List<List<int>> values) {
    assert(values.length == 9 && values.every((r) => r.length == 9));
    final grid = List.generate(9, (r) {
      return List.generate(9, (c) {
        final v = values[r][c];
        return Cell(row: r, col: c, value: v, isGiven: v != 0);
      });
    });
    return Board._(grid);
  }

  /// Creates a board from an 81-character string (row-major, '0' or '.' for empty).
  factory Board.fromString(String s) {
    assert(s.length == 81);
    final values = List.generate(9, (r) {
      return List.generate(9, (c) {
        final ch = s[r * 9 + c];
        return ch == '.' ? 0 : int.parse(ch);
      });
    });
    return Board.fromValues(values);
  }

  Cell getCell(int row, int col) => _grid[row][col];

  List<Cell> getRow(int row) => List.unmodifiable(_grid[row]);

  List<Cell> getColumn(int col) =>
      List.unmodifiable(List.generate(9, (r) => _grid[r][col]));

  List<Cell> getBox(int box) {
    final startRow = (box ~/ 3) * 3;
    final startCol = (box % 3) * 3;
    return List.unmodifiable([
      for (var r = startRow; r < startRow + 3; r++)
        for (var c = startCol; c < startCol + 3; c++) _grid[r][c],
    ]);
  }

  /// Returns all cells that share a row, column, or box with the given cell
  /// (excluding the cell itself).
  List<Cell> peers(int row, int col) {
    final cell = getCell(row, col);
    final seen = <Cell>{};
    seen.addAll(getRow(row));
    seen.addAll(getColumn(col));
    seen.addAll(getBox(cell.box));
    seen.remove(cell);
    return seen.toList();
  }

  /// Whether the board has no rule violations (no duplicate values in any
  /// row, column, or box). Empty cells are ignored.
  bool get isValid {
    for (var i = 0; i < 9; i++) {
      if (_hasDuplicates(getRow(i))) return false;
      if (_hasDuplicates(getColumn(i))) return false;
      if (_hasDuplicates(getBox(i))) return false;
    }
    return true;
  }

  /// Whether every cell is filled and the board is valid.
  bool get isSolved => isValid && _grid.every((row) => row.every((c) => c.isFilled));

  /// Returns a flat 81-character string representation (row-major).
  String toFlatString() =>
      _grid.expand((row) => row).map((c) => c.isEmpty ? '0' : '${c.value}').join();

  /// Returns a 2D list of int values.
  List<List<int>> toValues() =>
      List.generate(9, (r) => List.generate(9, (c) => _grid[r][c].value));

  Board clone() {
    final grid = List.generate(
      9,
      (r) => List.generate(9, (c) => _grid[r][c].clone()),
    );
    return Board._(grid);
  }

  static bool _hasDuplicates(List<Cell> cells) {
    final seen = <int>{};
    for (final cell in cells) {
      if (cell.isEmpty) continue;
      if (!seen.add(cell.value)) return true;
    }
    return false;
  }

  @override
  String toString() {
    final buf = StringBuffer();
    for (var r = 0; r < 9; r++) {
      if (r > 0 && r % 3 == 0) buf.writeln('------+-------+------');
      for (var c = 0; c < 9; c++) {
        if (c > 0 && c % 3 == 0) buf.write('| ');
        buf.write('${_grid[r][c]} ');
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
