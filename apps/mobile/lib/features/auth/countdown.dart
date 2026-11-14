// Seconds left until a moment on this phone's clock, ticking once a second,
// for the resend wait and rate-limit waits (ACC-01).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/clock.dart';

/// Ticks the state once a second while it is mounted.
mixin SecondTicker<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Timer? _ticker;

  DateTime now() => ref.read(clockProvider)();

  /// Whole seconds until [until], rounded up; 0 when it has passed or is
  /// null.
  int secondsUntil(DateTime? until) {
    if (until == null) return 0;
    final ms = until.difference(now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms + 999) ~/ 1000;
  }

  /// Whole minutes to show for [seconds], rounded up, at least 1.
  static int minutesFor(int seconds) => seconds <= 0 ? 1 : (seconds + 59) ~/ 60;

  /// Starts ticking if it is not already.
  void startTicking() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!stillWaiting()) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  /// Whether any wait is still running; ticking stops when none is.
  bool stillWaiting();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
