import '../models/parsed_crash_context.dart';

/// Pure-Dart stack trace parser.
///
/// Processes a raw Android logcat / Java stack trace and extracts:
/// - Exception type and message
/// - Package name (inferred)
/// - All stack frames
/// - Top N app-owned frames (filtered from framework internals)
class StackTraceParser {
  // Regex patterns
  static final _exceptionLineRegex = RegExp(
    r'^(?:FATAL EXCEPTION.*\n)?'
    r'(?:.*Process:.*\n)?'
    r'(?:.*PID:.*\n)?'
    r'([\w\.\$]+(?:Exception|Error|Throwable|RuntimeException))[:\s]+(.*)',
    multiLine: true,
  );

  static final _frameRegex = RegExp(
    r'^\s+at\s+([\w\.\$<>]+)\.([\w\$<>]+)\(([\w\.]+):(\d+)\)',
    multiLine: true,
  );

  // Package prefixes considered "framework" (filtered from top-app-frames)
  static const _frameworkPrefixes = [
    'android.',
    'com.android.',
    'java.',
    'javax.',
    'kotlin.',
    'kotlinx.',
    'dalvik.',
    'sun.',
    'libcore.',
    'androidx.',
    'com.google.android.',
  ];

  /// Parse a raw stack trace string into a structured [ParsedCrashContext].
  static ParsedCrashContext parse(String raw) {
    final trimmed = raw.trim();

    // --- Extract exception type + message ---
    String exceptionType = 'UnknownException';
    String exceptionMessage = 'No message';

    final exMatch = _exceptionLineRegex.firstMatch(trimmed);
    if (exMatch != null) {
      exceptionType = exMatch.group(1) ?? exceptionType;
      exceptionMessage = (exMatch.group(2) ?? exceptionMessage).trim();
    } else {
      // Fallback: look for any line with "Exception" or "Error"
      for (final line in trimmed.split('\n')) {
        final stripped = line.trim();
        if (stripped.contains('Exception') || stripped.contains('Error')) {
          final colonIdx = stripped.indexOf(':');
          if (colonIdx > 0) {
            exceptionType = stripped.substring(0, colonIdx).trim();
            exceptionMessage = stripped.substring(colonIdx + 1).trim();
          } else {
            exceptionType = stripped;
          }
          break;
        }
      }
    }

    // Shorten fully-qualified exception type to simple name for display
    final shortExceptionType = exceptionType.split('.').last;

    // --- Extract package name (from first app frame) ---
    String? packageName;

    // --- Extract stack frames ---
    final allFrames = <StackFrame>[];
    for (final match in _frameRegex.allMatches(trimmed)) {
      final className = match.group(1) ?? '';
      final methodName = match.group(2) ?? '';
      final fileName = match.group(3) ?? '';
      final lineNumber = int.tryParse(match.group(4) ?? '0') ?? 0;

      final isAppFrame = !_isFramework(className);

      if (isAppFrame && packageName == null) {
        // Infer package from first app class (everything before last segment)
        final parts = className.split('.');
        if (parts.length > 2) {
          packageName = parts.sublist(0, parts.length - 1).join('.');
        }
      }

      allFrames.add(StackFrame(
        className: className,
        methodName: methodName,
        fileName: fileName,
        lineNumber: lineNumber,
        isAppFrame: isAppFrame,
      ));
    }

    // Top app frames (for LLM context — high signal, low noise)
    final topAppFrames = allFrames.where((f) => f.isAppFrame).take(8).toList();

    return ParsedCrashContext(
      exceptionType: shortExceptionType,
      exceptionMessage: exceptionMessage,
      packageName: packageName,
      allFrames: allFrames,
      topAppFrames: topAppFrames,
      rawTrace: trimmed,
    );
  }

  static bool _isFramework(String className) {
    for (final prefix in _frameworkPrefixes) {
      if (className.startsWith(prefix)) return true;
    }
    return false;
  }
}
