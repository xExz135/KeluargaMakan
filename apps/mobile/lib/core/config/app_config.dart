// Client configuration for SRS figures marked (target) (SRS 1.3,
// docs/ARCHITECTURE.md 7). Values are read through [AppConfig], never written
// as constants in feature code, so they can change after validation without
// an app release.
//
// Sources are consulted in order; the first valid value wins, and the key's
// local default is the last resort. Today there is only the local-defaults
// source. A remote config source (Firebase Remote Config, after T-095) plugs in
// by implementing [ConfigSource] and being added in front of the defaults.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether a value is a proposed SRS (target) or a decided value.
enum ConfigStatus { target, decided }

/// A typed configuration key with its local default.
@immutable
final class ConfigKey<T extends Object> {
  const ConfigKey(
    this.name,
    this.defaultValue, {
    required this.requirementIds,
    this.status = ConfigStatus.target,
    this.min,
  });

  /// Remote config key, for example `ui.minTouchTargetDp`.
  final String name;
  final T defaultValue;
  final List<String> requirementIds;
  final ConfigStatus status;

  /// Floor for numeric keys (tokens.md 6): a value below it is raised to the
  /// floor, so a bad push cannot, for example, shrink touch targets below
  /// 48dp.
  final num? min;

  /// Converts a raw source value to [T], or returns null if it is missing or
  /// unreadable (the next source, then the default, is used).
  T? coerce(Object? raw) {
    if (raw == null) return null;
    final Object? value = switch (defaultValue) {
      int() => switch (raw) {
        int() => raw,
        double() when raw == raw.roundToDouble() => raw.toInt(),
        String() => int.tryParse(raw),
        _ => null,
      },
      double() => switch (raw) {
        num() => raw.toDouble(),
        String() => double.tryParse(raw),
        _ => null,
      },
      bool() => switch (raw) {
        bool() => raw,
        'true' => true,
        'false' => false,
        _ => null,
      },
      String() => raw is String ? raw : null,
      _ => raw is T ? raw : null,
    };
    if (value is! T) return null;
    if (value is num && min != null && value < min!) {
      final floor = defaultValue is int ? min!.ceil() : min!.toDouble();
      return floor as T;
    }
    return value;
  }

  @override
  String toString() => 'ConfigKey($name)';
}

/// Where configuration values come from.
abstract interface class ConfigSource {
  /// The raw value for [key], or null when this source has none.
  Object? read(String key);
}

/// Has no values of its own, so every key falls back to its default.
final class LocalDefaultsConfigSource implements ConfigSource {
  const LocalDefaultsConfigSource();

  @override
  Object? read(String key) => null;
}

/// A fixed map of values. For tests and local overrides.
final class MapConfigSource implements ConfigSource {
  const MapConfigSource(this.values);

  final Map<String, Object?> values;

  @override
  Object? read(String key) => values[key];
}

/// Reads typed values from the configured sources.
final class AppConfig {
  const AppConfig([this.sources = const [LocalDefaultsConfigSource()]]);

  final List<ConfigSource> sources;

  T get<T extends Object>(ConfigKey<T> key) {
    for (final source in sources) {
      final value = key.coerce(source.read(key.name));
      if (value != null) return value;
    }
    return key.defaultValue;
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
