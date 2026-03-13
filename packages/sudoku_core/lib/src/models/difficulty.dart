/// Puzzle difficulty levels, ordered from easiest to hardest.
///
/// Difficulty is determined by the most advanced solving strategy
/// required to solve the puzzle — not by the number of givens.
enum Difficulty {
  beginner,
  easy,
  medium,
  hard,
  expert,
  master;

  String get label => name[0].toUpperCase() + name.substring(1);
}
