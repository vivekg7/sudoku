import 'dart:async';
import 'dart:io';

/// Logical key events parsed from raw terminal input.
sealed class KeyEvent {}

class ArrowKey extends KeyEvent {
  final Direction direction;
  ArrowKey(this.direction);
}

enum Direction { up, down, left, right }

class CharKey extends KeyEvent {
  final String char;
  CharKey(this.char);
}

class BackspaceKey extends KeyEvent {}

class EscapeKey extends KeyEvent {}

class UnknownKey extends KeyEvent {}

/// Parses raw stdin bytes into a stream of [KeyEvent]s.
class InputHandler {
  StreamSubscription<List<int>>? _subscription;
  final _controller = StreamController<KeyEvent>();

  /// Stream of parsed key events.
  Stream<KeyEvent> get keys => _controller.stream;

  /// Starts listening to stdin.
  void start() {
    _subscription = stdin.listen(_handleBytes);
  }

  /// Stops listening.
  Future<void> stop() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  void _handleBytes(List<int> bytes) {
    var i = 0;
    while (i < bytes.length) {
      final byte = bytes[i];

      if (byte == 0x1B) {
        // Escape sequence
        if (i + 2 < bytes.length && bytes[i + 1] == 0x5B) {
          // CSI sequence: ESC [ <code>
          final code = bytes[i + 2];
          switch (code) {
            case 0x41: // A = Up
              _controller.add(ArrowKey(Direction.up));
            case 0x42: // B = Down
              _controller.add(ArrowKey(Direction.down));
            case 0x43: // C = Right
              _controller.add(ArrowKey(Direction.right));
            case 0x44: // D = Left
              _controller.add(ArrowKey(Direction.left));
            case 0x33: // '3' — possibly Delete (ESC [ 3 ~)
              if (i + 3 < bytes.length && bytes[i + 3] == 0x7E) {
                _controller.add(BackspaceKey());
                i += 4;
                continue;
              }
              _controller.add(UnknownKey());
            default:
              _controller.add(UnknownKey());
          }
          i += 3;
          continue;
        }
        // Standalone ESC
        _controller.add(EscapeKey());
        i++;
        continue;
      }

      if (byte == 0x7F || byte == 0x08) {
        // Backspace (0x7F on macOS, 0x08 on some terminals)
        _controller.add(BackspaceKey());
        i++;
        continue;
      }

      if (byte == 0x03) {
        // Ctrl+C — treat as quit
        _controller.add(CharKey('q'));
        i++;
        continue;
      }

      if (byte >= 0x20 && byte < 0x7F) {
        // Printable ASCII
        _controller.add(CharKey(String.fromCharCode(byte)));
        i++;
        continue;
      }

      // Ignore other control characters
      _controller.add(UnknownKey());
      i++;
    }
  }
}
