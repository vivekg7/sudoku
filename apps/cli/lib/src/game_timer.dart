/// Simple game timer with pause support.
class GameTimer {
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  /// Starts or resumes the timer.
  void start() {
    if (_running) return;
    _startTime = DateTime.now();
    _running = true;
  }

  /// Pauses the timer.
  void pause() {
    if (!_running) return;
    _elapsed += DateTime.now().difference(_startTime!);
    _running = false;
  }

  /// Resets the timer to zero.
  void reset() {
    _startTime = null;
    _elapsed = Duration.zero;
    _running = false;
  }

  /// Current elapsed time.
  Duration get elapsed {
    if (_running) {
      return _elapsed + DateTime.now().difference(_startTime!);
    }
    return _elapsed;
  }

  /// Total elapsed seconds.
  int get elapsedSeconds => elapsed.inSeconds;

  bool get isRunning => _running;

  /// Formatted elapsed time as MM:SS or H:MM:SS.
  String get formatted {
    final d = elapsed;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}'
          ':${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}'
        ':${seconds.toString().padLeft(2, '0')}';
  }
}
