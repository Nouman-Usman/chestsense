import 'package:flutter/foundation.dart';

class LoggerService {
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');
  static bool enableDebugLogs = true;
  static const String _tagML = '[ML]';
  static const String _tagAuth = '[AUTH]';
  static const String _tagDB = '[DB]';
  static const String _tagUI = '[UI]';
  static void debug(String message, {String? tag}) {
    if (!_isProduction && enableDebugLogs) {
      final prefix = tag ?? '[DEBUG]';
      debugPrint('$prefix $message');
    }
  }
  static void info(String message, {String? tag}) {
    final prefix = tag ?? '[INFO]';
    debugPrint('$prefix $message');
  }
  static void warning(String message, {String? tag, dynamic context}) {
    final prefix = tag ?? '[WARN]';
    final contextStr = context != null ? ' | Context: $context' : '';
    debugPrint('$prefix $message$contextStr');
  }
  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final prefix = tag ?? '[ERROR]';
    debugPrint('$prefix $message');
    
    if (error != null) {
      debugPrint('  └─ Error: $error');
    }
    
    if (context != null && context.isNotEmpty) {
      debugPrint('  └─ Context: $context');
    }
    
    if (stackTrace != null && !_isProduction) {
      debugPrint('  └─ Stack trace:');
      final lines = stackTrace.toString().split('\n').take(10);
      for (final line in lines) {
        debugPrint('     $line');
      }
    }
  }
  static Stopwatch startTimer(String operation) {
    debug('⏱️  Starting: $operation');
    return Stopwatch()..start();
  }
  static void logTiming(String operation, Stopwatch timer) {
    timer.stop();
    final ms = timer.elapsedMilliseconds;
    
    if (ms > 1000) {
      warning('⏱️  $operation took ${ms}ms (slow)', context: {'ms': ms});
    } else {
      debug('⏱️  $operation completed in ${ms}ms');
    }
  }
  static void ml(String message, {bool isDebug = false}) {
    if (isDebug) {
      debug(message, tag: _tagML);
    } else {
      info(message, tag: _tagML);
    }
  }
  static void auth(String message, {bool isDebug = false}) {
    if (isDebug) {
      debug(message, tag: _tagAuth);
    } else {
      info(message, tag: _tagAuth);
    }
  }
  static void database(String message, {bool isDebug = false}) {
    if (isDebug) {
      debug(message, tag: _tagDB);
    } else {
      info(message, tag: _tagDB);
    }
  }
  static void ui(String message, {bool isDebug = false}) {
    if (isDebug) {
      debug(message, tag: _tagUI);
    } else {
      info(message, tag: _tagUI);
    }
  }
  static void success(String message, {String? tag}) {
    info('✅ $message', tag: tag);
  }
  static void failure(String message, {String? tag, dynamic error}) {
    error('❌ $message', tag: tag, error: error);
  }
}
