import 'dart:developer' as developer;

class Logger {
  static bool _isLoggingEnabled = true;
  static const String _defaultLogPrefix = "AppMap:";

  static void log(String message, {String? prefix}) {
    final logPrefix = prefix ?? _defaultLogPrefix;
    if (_isLoggingEnabled) {
      developer.log('$logPrefix $message');
    }
  }

  static void info(String message) {
    if (_isLoggingEnabled) {
      developer.log('[INFO] $message', name: 'AppMap');
    }
  }

  static void error(String message) {
    if (_isLoggingEnabled) {
      developer.log('[ERROR] $message', name: 'AppMap');
    }
  }

  static void warning(String message) {
    if (_isLoggingEnabled) {
      developer.log('[WARNING] $message', name: 'AppMap');
    }
  }

  static void debug(String message) {
    if (_isLoggingEnabled) {
      developer.log('[DEBUG] $message', name: 'AppMap');
    }
  }

  static void enableLogging(bool isEnabled) {
    _isLoggingEnabled = isEnabled;
  }
}

// Legacy support
class AppLogger extends Logger {
  @Deprecated('Use Logger instead')
  static void log(String message, {String? prefix}) {
    Logger.log(message, prefix: prefix);
  }

  @Deprecated('Use Logger instead')
  static void enableLogging(bool isEnabled) {
    Logger.enableLogging(isEnabled);
  }
}