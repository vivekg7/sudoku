/// Returns all combinations of [k] items from [items] lazily.
///
/// Yields one combination at a time so callers that find a result early
/// avoid generating the remaining combinations.
Iterable<List<T>> combinations<T>(List<T> items, int k) sync* {
  if (k == 0) {
    yield [];
    return;
  }
  if (k > items.length) return;

  final indices = List.generate(k, (i) => i);

  yield [for (final i in indices) items[i]];

  while (true) {
    // Find the rightmost index that can be incremented.
    var i = k - 1;
    while (i >= 0 && indices[i] == items.length - k + i) {
      i--;
    }
    if (i < 0) return;

    indices[i]++;
    for (var j = i + 1; j < k; j++) {
      indices[j] = indices[j - 1] + 1;
    }

    yield [for (final idx in indices) items[idx]];
  }
}

/// Returns true if (r1,c1) and (r2,c2) share a row, column, or box.
bool isPeer(int r1, int c1, int r2, int c2) {
  if (r1 == r2 && c1 == c2) return false;
  if (r1 == r2) return true;
  if (c1 == c2) return true;
  return (r1 ~/ 3 == r2 ~/ 3) && (c1 ~/ 3 == c2 ~/ 3);
}
