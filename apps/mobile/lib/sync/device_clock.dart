// How old a queued kitchen change is (KIT-16, contract `KitchenChange.ageMs`).
//
// The server dates each queued change at its own time minus the age the
// phone reports, so the age must not depend on the phone's clock setting.
// The age is measured on a monotonic timeline where one exists:
// - Android: `SystemClock.elapsedRealtime()` (counts deep sleep too) on the
//   timeline of the current boot (`Settings.Global.BOOT_COUNT`), read
//   through the app's own platform channel (MainActivity.kt).
// - Anywhere else (tests, a missing channel): a stopwatch for this process,
//   which is monotonic but only within one run of the app.
// A change stamped on another timeline (the phone was restarted, or the app
// was closed without the Android channel) falls back to the wall clock, but
// is never younger than the current timeline: it was made before it began.
// So a changed phone clock cannot make a change from this boot look newer
// or older than it is; across a restart it can only shift the age within
// the wall-clock difference.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One reading of the device clocks.
@immutable
final class ClockReading {
  const ClockReading({
    required this.timeline,
    required this.elapsedMs,
    required this.wallMs,
  });

  /// Identifies the monotonic timeline [elapsedMs] belongs to, for example
  /// `boot:12`. Readings on different timelines cannot be compared.
  final String timeline;

  /// Milliseconds since the start of [timeline]; never goes back within it.
  final int elapsedMs;

  /// Milliseconds since the Unix epoch on the phone's clock (UTC). May jump
  /// when the clock is set.
  final int wallMs;

  @override
  String toString() => 'ClockReading($timeline, $elapsedMs)';
}

/// The age in milliseconds of an edit stamped [then], read at [now]. Never
/// negative.
int ageBetween(ClockReading then, ClockReading now) {
  if (then.timeline == now.timeline) {
    return max(0, now.elapsedMs - then.elapsedMs);
  }
  // Another timeline: the edit happened before this one started.
  return max(now.elapsedMs, now.wallMs - then.wallMs);
}

abstract interface class DeviceClock {
  Future<ClockReading> read();
}

/// The Android clocks through `id.keluargamakan.app/device`, or a stopwatch
/// for this process when the channel is not there.
final class PlatformDeviceClock implements DeviceClock {
  PlatformDeviceClock({MethodChannel? channel, Random? random})
    : _channel = channel ?? const MethodChannel(channelName),
      _process = 'process:${(random ?? Random.secure()).nextInt(1 << 32)}';

  static const channelName = 'id.keluargamakan.app/device';

  final MethodChannel _channel;
  final String _process;
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool _channelMissing = false;

  @override
  Future<ClockReading> read() async {
    if (!_channelMissing) {
      try {
        final raw = await _channel.invokeMapMethod<String, Object?>('clock');
        final boot = raw?['bootCount'];
        final elapsed = raw?['elapsedRealtimeMs'];
        if (boot is int && elapsed is int && elapsed >= 0) {
          return ClockReading(
            timeline: 'boot:$boot',
            elapsedMs: elapsed,
            wallMs: DateTime.now().millisecondsSinceEpoch,
          );
        }
      } on MissingPluginException {
        _channelMissing = true;
      } on Object catch (e) {
        // A platform error, or no binding (plain unit tests): this process's
        // stopwatch from now on.
        debugPrint('Device clock unavailable (${e.runtimeType})');
        _channelMissing = true;
      }
    }
    return ClockReading(
      timeline: _process,
      elapsedMs: _stopwatch.elapsedMilliseconds,
      wallMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Overridden in tests with a clock they control.
final deviceClockProvider = Provider<DeviceClock>(
  (ref) => PlatformDeviceClock(),
);
