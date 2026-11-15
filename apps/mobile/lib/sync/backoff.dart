// Exponential backoff with jitter for retrying the kitchen sync (SRS 19.4,
// KIT-16). The base, the ceiling and the jitter come from configuration
// (`sync.retryBaseMs`, `sync.retryMaxMs`, `sync.retryJitterPercent`), never
// from constants, so they can be tuned without an app release.

import 'dart:math';

import '../core/config/app_config.dart';
import '../core/config/config_keys.dart';

final class Backoff {
  Backoff({
    required this.baseMs,
    required this.maxMs,
    required this.jitterPercent,
    Random? random,
  }) : _random = random ?? Random();

  factory Backoff.fromConfig(AppConfig config, {Random? random}) => Backoff(
    baseMs: config.get(ConfigKeys.syncRetryBaseMs),
    maxMs: config.get(ConfigKeys.syncRetryMaxMs),
    jitterPercent: config.get(ConfigKeys.syncRetryJitterPercent),
    random: random,
  );

  final int baseMs;
  final int maxMs;

  /// 0 to 100: how much of each delay may be taken off at random, so phones
  /// that lost the connection together do not all retry at once.
  final int jitterPercent;
  final Random _random;

  /// The longest delay before retry number [failures] (1 for the first
  /// retry), before jitter.
  int ceilingFor(int failures) {
    final ceiling = max(baseMs, maxMs);
    if (failures <= 1) return min(baseMs, ceiling);
    // Doubling stops at the ceiling; the shift is bounded to avoid overflow.
    final shift = min(failures - 1, 30);
    final grown = baseMs * (1 << shift);
    return grown <= 0 ? ceiling : min(grown, ceiling);
  }

  /// The delay before retry number [failures]: the ceiling, minus up to
  /// [jitterPercent] of it at random.
  Duration delayFor(int failures) {
    final ceiling = ceilingFor(failures);
    final jitter = jitterPercent.clamp(0, 100) / 100;
    final cut = (ceiling * jitter * _random.nextDouble()).floor();
    return Duration(milliseconds: max(0, ceiling - cut));
  }
}
