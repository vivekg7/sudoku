import '../hint/hint.dart';
import '../models/board.dart';
import '../models/candidate_set.dart';
import '../models/difficulty.dart';
import '../models/puzzle.dart';
import '../solver/strategy_type.dart';

/// An entry in the puzzle store - a saved or bookmarked puzzle.
class PuzzleEntry {
  /// Unique identifier.
  final String id;

  /// The puzzle.
  final Puzzle puzzle;

  /// Whether this puzzle is bookmarked for replay.
  final bool bookmarked;

  /// When the entry was saved.
  final DateTime savedAt;

  /// Elapsed play time in seconds when the game was saved.
  final int elapsedSeconds;

  /// Hints taken, broken down by layer.
  final Map<HintLevel, int> hintsByLevel;

  /// Hints taken, broken down by strategy type.
  final Map<StrategyType, int> hintsByStrategy;

  /// Number of mistakes made.
  final int mistakeCount;

  PuzzleEntry({
    required this.id,
    required this.puzzle,
    this.bookmarked = false,
    this.elapsedSeconds = 0,
    this.hintsByLevel = const {},
    this.hintsByStrategy = const {},
    this.mistakeCount = 0,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  PuzzleEntry copyWith({bool? bookmarked, int? elapsedSeconds}) => PuzzleEntry(
        id: id,
        puzzle: puzzle,
        bookmarked: bookmarked ?? this.bookmarked,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        hintsByLevel: hintsByLevel,
        hintsByStrategy: hintsByStrategy,
        mistakeCount: mistakeCount,
        savedAt: savedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'initialBoard': puzzle.initialBoard.toFlatString(),
        'solution': puzzle.solution.toFlatString(),
        'currentBoard': puzzle.board.toFlatString(),
        'candidates': puzzle.board.toCandidateBits(),
        'difficulty': puzzle.difficulty.name,
        'bookmarked': bookmarked,
        'savedAt': savedAt.toIso8601String(),
        'createdAt': puzzle.createdAt.toIso8601String(),
        if (puzzle.quoteId != null) 'quoteId': puzzle.quoteId,
        'elapsedSeconds': elapsedSeconds,
        'hintsByLevel': {
          for (final e in hintsByLevel.entries) e.key.name: e.value,
        },
        'hintsByStrategy': {
          for (final e in hintsByStrategy.entries) e.key.name: e.value,
        },
        'mistakeCount': mistakeCount,
      };

  factory PuzzleEntry.fromJson(Map<String, dynamic> json) {
    final initialBoard = Board.fromString(json['initialBoard'] as String);
    final solution = Board.fromString(json['solution'] as String);

    // Restore current board: start from the saved current state.
    // Cells that are givens in initialBoard stay as givens; others are
    // user-filled.
    final currentFlat = json['currentBoard'] as String;
    final candidateBits = (json['candidates'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList();
    final currentBoard =
        _restoreCurrentBoard(initialBoard, currentFlat, candidateBits);

    final puzzle = Puzzle(
      initialBoard: initialBoard,
      solution: solution,
      board: currentBoard,
      difficulty: Difficulty.values.byName(json['difficulty'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      quoteId: json['quoteId'] as int?,
    );

    final hintsByLevel = <HintLevel, int>{};
    final rawHintsByLevel = json['hintsByLevel'] as Map<String, dynamic>?;
    if (rawHintsByLevel != null) {
      for (final e in rawHintsByLevel.entries) {
        hintsByLevel[HintLevel.values.byName(e.key)] = e.value as int;
      }
    }

    final hintsByStrategy = <StrategyType, int>{};
    final rawHintsByStrategy = json['hintsByStrategy'] as Map<String, dynamic>?;
    if (rawHintsByStrategy != null) {
      for (final e in rawHintsByStrategy.entries) {
        hintsByStrategy[StrategyType.values.byName(e.key)] = e.value as int;
      }
    }

    return PuzzleEntry(
      id: json['id'] as String,
      puzzle: puzzle,
      bookmarked: json['bookmarked'] as bool? ?? false,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      hintsByLevel: hintsByLevel,
      hintsByStrategy: hintsByStrategy,
      mistakeCount: json['mistakeCount'] as int? ?? 0,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  /// Rebuilds a current board where givens from [initialBoard] are marked
  /// as given and other filled cells are user-entered.
  /// Optionally restores candidate pencil marks from [candidateBits].
  static Board _restoreCurrentBoard(
      Board initialBoard, String flat, List<int>? candidateBits) {
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

    // Set user-filled values and restore candidates.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (initialBoard.getCell(r, c).isGiven) continue;
        final cell = board.getCell(r, c);
        if (values[r][c] != 0) {
          cell.setValue(values[r][c]);
        } else if (candidateBits != null) {
          final bits = candidateBits[r * 9 + c];
          if (bits != 0) {
            cell.setCandidates(CandidateSet(bits));
          }
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
