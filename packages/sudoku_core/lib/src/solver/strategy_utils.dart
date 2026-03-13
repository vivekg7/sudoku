/// Returns all combinations of [k] items from [items].
List<List<T>> combinations<T>(List<T> items, int k) {
  final results = <List<T>>[];
  void recurse(int start, List<T> current) {
    if (current.length == k) {
      results.add(List.of(current));
      return;
    }
    for (var i = start; i < items.length; i++) {
      current.add(items[i]);
      recurse(i + 1, current);
      current.removeLast();
    }
  }
  recurse(0, []);
  return results;
}

/// Returns true if (r1,c1) and (r2,c2) share a row, column, or box.
bool isPeer(int r1, int c1, int r2, int c2) {
  if (r1 == r2 && c1 == c2) return false;
  if (r1 == r2) return true;
  if (c1 == c2) return true;
  return (r1 ~/ 3 == r2 ~/ 3) && (c1 ~/ 3 == c2 ~/ 3);
}
