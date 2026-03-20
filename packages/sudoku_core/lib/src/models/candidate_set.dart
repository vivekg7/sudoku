import 'dart:collection';

/// A set of Sudoku candidate values (1-9) backed by a bitmask.
///
/// Bit `i` being set means value `i` is a candidate. Only bits 1-9 are used.
/// All set operations (union, intersection, contains, length) are single
/// bitwise ops - no heap allocation, no hashing.
class CandidateSet extends IterableBase<int> {
  int _bits;

  CandidateSet([this._bits = 0]);

  /// Creates a CandidateSet from an existing [Set<int>].
  CandidateSet.fromSet(Set<int> values) : _bits = 0 {
    for (final v in values) {
      _bits |= 1 << v;
    }
  }

  /// Creates a CandidateSet containing the given [values].
  CandidateSet.of(Iterable<int> values) : _bits = 0 {
    for (final v in values) {
      _bits |= 1 << v;
    }
  }

  /// The raw bitmask. Bit `i` set means candidate `i` is present.
  int get bits => _bits;

  // -- Iterable<int> --------------------------------------------------------

  @override
  Iterator<int> get iterator => _CandidateIterator(_bits);

  @override
  bool contains(Object? element) =>
      element is int &&
      element >= 1 &&
      element <= 9 &&
      (_bits & (1 << element)) != 0;

  @override
  int get length {
    // Kernighan's bit-counting for a max-10-bit number.
    var count = 0;
    var x = _bits;
    while (x != 0) {
      count++;
      x &= x - 1;
    }
    return count;
  }

  @override
  bool get isEmpty => _bits == 0;

  @override
  bool get isNotEmpty => _bits != 0;

  @override
  int get first {
    if (_bits == 0) throw StateError('No element');
    return _lowestBit(_bits);
  }

  // -- Mutation --------------------------------------------------------------

  void add(int v) {
    assert(v >= 1 && v <= 9);
    _bits |= 1 << v;
  }

  void remove(int v) {
    _bits &= ~(1 << v);
  }

  void clear() {
    _bits = 0;
  }

  void addAll(CandidateSet other) {
    _bits |= other._bits;
  }

  void setAll(CandidateSet other) {
    _bits = other._bits;
  }

  // -- Set operations (return new CandidateSet) ------------------------------

  CandidateSet union(CandidateSet other) => CandidateSet(_bits | other._bits);

  CandidateSet intersection(CandidateSet other) =>
      CandidateSet(_bits & other._bits);

  CandidateSet difference(CandidateSet other) =>
      CandidateSet(_bits & ~other._bits);

  bool containsAll(CandidateSet other) => (_bits & other._bits) == other._bits;

  /// Returns a copy with the same bits.
  CandidateSet copy() => CandidateSet(_bits);

  // -- Helpers ---------------------------------------------------------------

  static int _lowestBit(int n) {
    final bit = n & (-n);
    // bit is a power of 2; find its position.
    var v = 0;
    var b = bit;
    while (b > 1) {
      v++;
      b >>= 1;
    }
    return v;
  }

  @override
  String toString() => '{${toList().join(', ')}}';

  @override
  bool operator ==(Object other) =>
      other is CandidateSet && _bits == other._bits;

  @override
  int get hashCode => _bits.hashCode;
}

class _CandidateIterator implements Iterator<int> {
  int _remaining;
  int _current = 0;

  _CandidateIterator(this._remaining);

  @override
  int get current => _current;

  @override
  bool moveNext() {
    if (_remaining == 0) return false;
    _current = CandidateSet._lowestBit(_remaining);
    _remaining &= _remaining - 1; // clear lowest set bit
    return true;
  }
}
