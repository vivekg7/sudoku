import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('MoveHistory', () {
    late MoveHistory history;

    setUp(() {
      history = MoveHistory();
    });

    Move makeMove(int row, int col, int value) => Move(
          row: row,
          col: col,
          type: MoveType.setValue,
          previousValue: 0,
          newValue: value,
        );

    test('starts empty', () {
      expect(history.canUndo, false);
      expect(history.canRedo, false);
      expect(history.undoCount, 0);
      expect(history.redoCount, 0);
    });

    test('push adds to undo stack', () {
      history.push(makeMove(0, 0, 5));
      expect(history.canUndo, true);
      expect(history.undoCount, 1);
    });

    test('undo returns last move and moves to redo', () {
      final m = makeMove(0, 0, 5);
      history.push(m);
      final undone = history.undo();
      expect(undone, [m]);
      expect(history.canUndo, false);
      expect(history.canRedo, true);
    });

    test('redo returns last undone move', () {
      final m = makeMove(0, 0, 5);
      history.push(m);
      history.undo();
      final redone = history.redo();
      expect(redone, [m]);
      expect(history.canUndo, true);
      expect(history.canRedo, false);
    });

    test('push after undo clears redo stack', () {
      history.push(makeMove(0, 0, 5));
      history.undo();
      history.push(makeMove(1, 1, 3));
      expect(history.canRedo, false);
      expect(history.undoCount, 1);
    });

    test('undo on empty returns null', () {
      expect(history.undo(), isNull);
    });

    test('redo on empty returns null', () {
      expect(history.redo(), isNull);
    });

    test('clear empties both stacks', () {
      history.push(makeMove(0, 0, 1));
      history.push(makeMove(0, 1, 2));
      history.undo();
      history.clear();
      expect(history.canUndo, false);
      expect(history.canRedo, false);
    });

    test('multiple undo/redo in sequence', () {
      history.push(makeMove(0, 0, 1));
      history.push(makeMove(0, 1, 2));
      history.push(makeMove(0, 2, 3));

      expect(history.undo()!.first.newValue, 3);
      expect(history.undo()!.first.newValue, 2);
      expect(history.redo()!.first.newValue, 2);
      expect(history.redo()!.first.newValue, 3);
      expect(history.canRedo, false);
    });
  });

  group('Move', () {
    test('toString is readable', () {
      final m = Move(
        row: 3,
        col: 4,
        type: MoveType.setValue,
        previousValue: 0,
        newValue: 7,
      );
      expect(m.toString(), contains('R4C5'));
      expect(m.toString(), contains('setValue'));
    });
  });
}
