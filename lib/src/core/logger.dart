enum DebugLevel { error, warn, log, info }

DebugLevel? _currentLevel = DebugLevel.warn;

void setLoggerLevel(DebugLevel? level) {
  _currentLevel = level;
}

class Logger {
  Logger._(this.namespace);

  final String namespace;

  void error(Object? message, [List<Object?> arguments = const []]) {
    _log(DebugLevel.error, message, arguments);
  }

  void warn(Object? message, [List<Object?> arguments = const []]) {
    _log(DebugLevel.warn, message, arguments);
  }

  void log(Object? message, [List<Object?> arguments = const []]) {
    _log(DebugLevel.log, message, arguments);
  }

  void info(Object? message, [List<Object?> arguments = const []]) {
    _log(DebugLevel.info, message, arguments);
  }

  void level(DebugLevel? level) => setLoggerLevel(level);

  void _log(DebugLevel level, Object? message, List<Object?> arguments) {
    if (!_shouldLog(level)) {
      return;
    }
    final buffer = StringBuffer()
      ..write(namespace)
      ..write(': ');
    if (message != null) {
      buffer.write(message);
    }
    for (final argument in arguments) {
      buffer
        ..write(' ')
        ..write(argument);
    }
    // Using print keeps the implementation simple while remaining testable.
    // In production this can be swapped by providing a custom Zone print.
    print(buffer.toString());
  }
}

bool _shouldLog(DebugLevel level) {
  final current = _currentLevel;
  if (current == null) {
    return false;
  }
  return level.index <= current.index;
}

Logger logger(String namespace) => Logger._(namespace);
