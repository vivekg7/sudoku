/// Represents a single cell in a 9x9 Sudoku grid.
class Cell {
  final int row;
  final int col;

  /// The 3x3 box index (0–8), derived from row and col.
  int get box => (row ~/ 3) * 3 + col ~/ 3;

  /// The current value (1–9), or 0 if empty.
  int _value;
  int get value => _value;

  /// Whether this cell was part of the original puzzle (cannot be modified).
  final bool isGiven;

  /// Candidate pencil marks — possible values the player is considering.
  final Set<int> _candidates;
  Set<int> get candidates => Set.unmodifiable(_candidates);

  Cell({
    required this.row,
    required this.col,
    int value = 0,
    this.isGiven = false,
    Set<int>? candidates,
  })  : _value = value,
        _candidates = candidates != null ? Set.of(candidates) : {};

  /// Sets the cell value. Clears candidates when a value is set.
  /// Throws if the cell is a given.
  void setValue(int v) {
    assert(v >= 0 && v <= 9);
    if (isGiven) throw StateError('Cannot modify a given cell.');
    _value = v;
    if (v != 0) _candidates.clear();
  }

  /// Clears the cell value (sets to 0).
  void clearValue() {
    if (isGiven) throw StateError('Cannot modify a given cell.');
    _value = 0;
  }

  void addCandidate(int v) {
    assert(v >= 1 && v <= 9);
    if (_value != 0) return; // no candidates on filled cells
    _candidates.add(v);
  }

  void removeCandidate(int v) {
    _candidates.remove(v);
  }

  void toggleCandidate(int v) {
    assert(v >= 1 && v <= 9);
    if (_value != 0) return;
    _candidates.contains(v) ? _candidates.remove(v) : _candidates.add(v);
  }

  void setCandidates(Set<int> values) {
    _candidates
      ..clear()
      ..addAll(values);
  }

  bool get isEmpty => _value == 0;
  bool get isFilled => _value != 0;

  Cell clone() => Cell(
        row: row,
        col: col,
        value: _value,
        isGiven: isGiven,
        candidates: Set.of(_candidates),
      );

  @override
  String toString() =>
      isEmpty ? '.' : '$_value';

  @override
  bool operator ==(Object other) =>
      other is Cell &&
      row == other.row &&
      col == other.col &&
      _value == other._value &&
      isGiven == other.isGiven;

  @override
  int get hashCode => Object.hash(row, col, _value, isGiven);
}
