// Release-safe error reporting (DAT-08; security review T-033 M1).
//
// An exception's text can carry personal data: SQLite's prints the
// statement's parameters (custom ingredient and member names), and a
// widget error describes the widget, including its text. So outside debug
// builds only the error's type is logged, never its message or the
// diagnostics. In debug builds Flutter's full report stays, for
// development. No crash reporter is set up; T-076 must keep this rule.

import 'package:flutter/foundation.dart';

/// Installs the hooks for framework errors and for errors no code caught.
/// [verbose] is true only in debug builds.
void installErrorHooks({bool verbose = kDebugMode}) {
  FlutterError.onError = (details) {
    if (verbose) {
      FlutterError.presentError(details);
      return;
    }
    final e = details.exception;
    debugPrint('Flutter error: ${e.runtimeType}');
  };
  PlatformDispatcher.instance.onError = (e, stack) {
    if (verbose) {
      FlutterError.presentError(
        FlutterErrorDetails(exception: e, stack: stack),
      );
    } else {
      debugPrint('Unhandled error: ${e.runtimeType}');
    }
    return true;
  };
}
