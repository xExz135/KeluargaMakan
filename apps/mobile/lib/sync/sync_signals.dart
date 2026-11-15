// When to try sending queued kitchen changes again (KIT-16, SRS 19.4):
// - the connection comes back (Android `ConnectivityManager` through the
//   app's own event channel, MainActivity.kt; no third-party plugin),
// - the app comes back to the foreground,
// - a retry timer from the backoff fires.
// Each is a provider so tests can drive it. A missing channel (tests, other
// platforms) only means fewer triggers: the backoff timer still retries.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------ Connectivity

abstract interface class ConnectivitySignal {
  /// True when the phone has a network with internet, false when it lost
  /// it. Only changes are reported.
  Stream<bool> get changes;
}

final class PlatformConnectivitySignal implements ConnectivitySignal {
  PlatformConnectivitySignal({EventChannel? channel})
    : _channel = channel ?? const EventChannel(channelName);

  static const channelName = 'id.keluargamakan.app/connectivity';

  final EventChannel _channel;

  @override
  Stream<bool> get changes => _channel
      .receiveBroadcastStream()
      .where((event) => event is bool)
      .cast<bool>()
      .handleError((Object e) {
        // No channel (tests, other platforms): retries rely on the timer.
        debugPrint('Connectivity signal unavailable (${e.runtimeType})');
      });
}

final connectivitySignalProvider = Provider<ConnectivitySignal>(
  (ref) => PlatformConnectivitySignal(),
);

// ------------------------------------------------------------ App resume

abstract interface class AppResumeSignal {
  /// Fires each time the app comes back to the foreground.
  Stream<void> get resumed;
}

final class LifecycleResumeSignal implements AppResumeSignal {
  @override
  Stream<void> get resumed {
    late final StreamController<void> controller;
    AppLifecycleListener? listener;
    controller = StreamController<void>.broadcast(
      onListen: () {
        try {
          listener = AppLifecycleListener(onResume: () => controller.add(null));
        } on Object catch (e) {
          // No binding yet (plain unit tests).
          debugPrint('App lifecycle unavailable (${e.runtimeType})');
        }
      },
      onCancel: () {
        listener?.dispose();
        listener = null;
      },
    );
    return controller.stream;
  }
}

final appResumeSignalProvider = Provider<AppResumeSignal>(
  (ref) => LifecycleResumeSignal(),
);

// ------------------------------------------------------------ Retry timers

/// Starts the retry timers of the sync, so tests can fire them by hand
/// instead of waiting.
abstract interface class SyncTimers {
  Timer start(Duration delay, void Function() callback);
}

final class RealSyncTimers implements SyncTimers {
  const RealSyncTimers();

  @override
  Timer start(Duration delay, void Function() callback) =>
      Timer(delay, callback);
}

final syncTimersProvider = Provider<SyncTimers>(
  (ref) => const RealSyncTimers(),
);
