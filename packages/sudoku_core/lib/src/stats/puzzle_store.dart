import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/puzzle.dart';

/// An entry in the puzzle store — a saved or bookmarked puzzle.
class PuzzleEntry {
  /// Unique identifier.
  final String id;

  /// The puzzle.
  final Puzzle puzzle;

  /// Whether this puzzle is bookmarked for replay.
  final bool bookmarked;

  /// When the entry was saved.
  final DateTime savedAt;

  PuzzleEntry({
    required this.id,
    required this.puzzle,
    this.bookmarked = false,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  PuzzleEntry copyWith({bool? bookmarked}) => PuzzleEntry(
        id: id,
        puzzle: puzzle,
        bookmarked: bookmarked ?? this.bookmarked,
        savedAt: savedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'initialBoard': puzzle.initialBoard.toFlatString(),
        'solution': puzzle.solution.toFlatString(),
        'currentBoard': puzzle.board.toFlatString(),
        'difficulty': puzzle.difficulty.name,
        'bookmarked': bookmarked,
        'savedAt': savedAt.toIso8601String(),
        'createdAt': puzzle.createdAt.toIso8601String(),
        if (puzzle.quoteId != null) 'quoteId': puzzle.quoteId,
      };

  factory PuzzleEntry.fromJson(Map<String, dynamic> json) {
    final initialBoard = Board.fromString(json['initialBoard'] as String);
    final solution = Board.fromString(json['solution'] as String);

    // Restore current board: start from the saved current state.
    // Cells that are givens in initialBoard stay as givens; others are
    // user-filled.
    final currentFlat = json['currentBoard'] as String;
    final currentBoard = _restoreCurrentBoard(initialBoard, currentFlat);

    final puzzle = Puzzle(
      initialBoard: initialBoard,
      solution: solution,
      board: currentBoard,
      difficulty: Difficulty.values.byName(json['difficulty'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      quoteId: json['quoteId'] as int?,
    );

    return PuzzleEntry(
      id: json['id'] as String,
      puzzle: puzzle,
      bookmarked: json['bookmarked'] as bool? ?? false,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  /// Rebuilds a current board where givens from [initialBoard] are marked
  /// as given and other filled cells are user-entered.
  static Board _restoreCurrentBoard(Board initialBoard, String flat) {
    final values = List.generate(9, (r) {
      return List.generate(9, (c) {
        final ch = flat[r * 9 + c];
        return ch == '.' || ch == '0' ? 0 : int.parse(ch);
      });
    });

    // Build with givens from initial board.
    final board = Board.fromValues(List.generate(9, (r) {
      return List.generate(9, (c) {
        final initial = initialBoard.getCell(r, c);
        return initial.isGiven ? initial.value : 0;
      });
    }));

    // Set user-filled values.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (!initialBoard.getCell(r, c).isGiven && values[r][c] != 0) {
          board.getCell(r, c).setValue(values[r][c]);
        }
      }
    }

    return board;
  }
}

/// Stores saved and bookmarked puzzles.
class PuzzleStore {
  PuzzleStore();

  final Map<String, PuzzleEntry> _entries = {};

  /// All stored puzzle entries.
  List<PuzzleEntry> get entries =>
      _entries.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  /// In-progress puzzles (not solved, not bookmarked).
  List<PuzzleEntry> get inProgress => entries
      .where((e) => !e.puzzle.isSolved && !e.bookmarked)
      .toList();

  /// Bookmarked puzzles.
  List<PuzzleEntry> get bookmarked =>
      entries.where((e) => e.bookmarked).toList();

  /// Saves a puzzle. Overwrites if the id already exists.
  void save(PuzzleEntry entry) {
    _entries[entry.id] = entry;
  }

  /// Loads a puzzle by id.
  PuzzleEntry? load(String id) => _entries[id];

  /// Removes a puzzle by id.
  void remove(String id) {
    _entries.remove(id);
  }

  /// Toggles the bookmark status of a puzzle.
  void toggleBookmark(String id) {
    final entry = _entries[id];
    if (entry == null) return;
    _entries[id] = entry.copyWith(bookmarked: !entry.bookmarked);
  }

  Map<String, dynamic> toJson() => {
        'entries': _entries.values.map((e) => e.toJson()).toList(),
      };

  factory PuzzleStore.fromJson(Map<String, dynamic> json) {
    final store = PuzzleStore();
    final entries = json['entries'] as List<dynamic>;
    for (final e in entries) {
      final entry = PuzzleEntry.fromJson(e as Map<String, dynamic>);
      store.save(entry);
    }
    return store;
  }
}
