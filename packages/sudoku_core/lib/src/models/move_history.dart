import 'move.dart';

/// Undo/redo stack for moves.
class MoveHistory {
  final List<Move> _undoStack = [];
  final List<Move> _redoStack = [];

  /// Push a new move. Clears the redo stack (branching).
  void push(Move move) {
    _undoStack.add(move);
    _redoStack.clear();
  }

  /// Pop the last move for undoing. Returns null if nothing to undo.
  Move? undo() {
    if (_undoStack.isEmpty) return null;
    final move = _undoStack.removeLast();
    _redoStack.add(move);
    return move;
  }

  /// Re-apply the last undone move. Returns null if nothing to redo.
  Move? redo() {
    if (_redoStack.isEmpty) return null;
    final move = _redoStack.removeLast();
    _undoStack.add(move);
    return move;
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
