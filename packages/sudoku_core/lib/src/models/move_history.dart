import 'move.dart';

/// Undo/redo stack for moves.
///
/// Each entry is a list of moves that form a single undo step.
/// Normal moves are wrapped in a single-element list; batch operations
/// (like auto-fill notes) push a multi-element list as one step.
class MoveHistory {
  final List<List<Move>> _undoStack = [];
  final List<List<Move>> _redoStack = [];

  /// Push a single move. Clears the redo stack (branching).
  void push(Move move) {
    _undoStack.add([move]);
    _redoStack.clear();
  }

  /// Push a batch of moves as a single undo step.
  void pushAll(List<Move> moves) {
    if (moves.isEmpty) return;
    _undoStack.add(moves);
    _redoStack.clear();
  }

  /// Pop the last undo step. Returns null if nothing to undo.
  List<Move>? undo() {
    if (_undoStack.isEmpty) return null;
    final moves = _undoStack.removeLast();
    _redoStack.add(moves);
    return moves;
  }

  /// Re-apply the last undone step. Returns null if nothing to redo.
  List<Move>? redo() {
    if (_redoStack.isEmpty) return null;
    final moves = _redoStack.removeLast();
    _undoStack.add(moves);
    return moves;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
