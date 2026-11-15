// TEST FIXTURE: not real safety or nutrition data.
//
// Fakes for the kitchen sync's clock, retry timers, connectivity and app
// resume (lib/sync), so tests can make a phone go offline, come back,
// restart, change its clock and fire the backoff without waiting.

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:keluargamakan/sync/device_clock.dart';
import 'package:keluargamakan/sync/sync_signals.dart';

/// The device clock of one test phone. [now] is the test's clock; the
/// monotonic timeline follows it unless the test moves the wall clock
/// ([wallSkew]) or restarts the phone ([reboot]).
final class FakeDeviceClock implements DeviceClock {
  FakeDeviceClock(this.now);

  DateTime Function() now;

  /// How far the phone's clock setting is from the true time.
  Duration wallSkew = Duration.zero;

  /// The current boot; [reboot] starts a new one.
  int boot = 1;
  DateTime _bootStart = DateTime.utc(2026, 11, 1);

  /// Starts a new monotonic timeline at the current time.
  void reboot() {
    boot++;
    _bootStart = now().toUtc();
  }

  /// The phone has been up this long (a new timeline that began then).
  void setUptime(Duration uptime) =>
      _bootStart = now().toUtc().subtract(uptime);

  /// While true, every read waits until the test releases it ([releaseNext]).
  bool hold = false;
  final List<Completer<void>> _held = [];

  /// Reads waiting to be released.
  int get heldReads => _held.length;

  /// Lets the oldest waiting read answer.
  void releaseNext() => _held.removeAt(0).complete();

  @override
  Future<ClockReading> read() async {
    if (hold) {
      final gate = Completer<void>();
      _held.add(gate);
      await gate.future;
    }
    final true_ = now().toUtc();
    return ClockReading(
      timeline: 'boot:$boot',
      elapsedMs: true_.difference(_bootStart).inMilliseconds,
      wallMs: true_.add(wallSkew).millisecondsSinceEpoch,
    );
  }
}

/// Retry timers the test fires by hand.
final class ManualSyncTimers implements SyncTimers {
  final List<ManualTimer> started = [];

  /// Timers still waiting.
  List<ManualTimer> get pending => [
    for (final t in started)
      if (t.isActive) t,
  ];

  @override
  Timer start(Duration delay, void Function() callback) {
    final timer = ManualTimer(delay, callback);
    started.add(timer);
    return timer;
  }

  /// Fires every waiting timer.
  void fireAll() {
    for (final t in pending) {
      t.fire();
    }
  }
}

final class ManualTimer implements Timer {
  ManualTimer(this.delay, this._callback);

  final Duration delay;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

final class FakeConnectivity implements ConnectivitySignal {
  final _changes = StreamController<bool>.broadcast(sync: true);

  void goOnline() => _changes.add(true);

  void goOffline() => _changes.add(false);

  @override
  Stream<bool> get changes => _changes.stream;
}

final class FakeResume implements AppResumeSignal {
  final _resumed = StreamController<void>.broadcast(sync: true);

  void resume() => _resumed.add(null);

  @override
  Stream<void> get resumed => _resumed.stream;
}

/// The sync fakes of one phone.
final class SyncFakes {
  SyncFakes(DateTime Function() now) : clock = FakeDeviceClock(now);

  final FakeDeviceClock clock;
  final timers = ManualSyncTimers();
  final connectivity = FakeConnectivity();
  final resume = FakeResume();

  List<Override> get overrides => [
    deviceClockProvider.overrideWithValue(clock),
    syncTimersProvider.overrideWithValue(timers),
    connectivitySignalProvider.overrideWithValue(connectivity),
    appResumeSignalProvider.overrideWithValue(resume),
  ];
}
