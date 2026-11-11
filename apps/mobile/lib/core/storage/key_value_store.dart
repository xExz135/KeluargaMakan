// Small on-device store for non-sensitive app preferences (language, theme,
// installation ID), kept in the drift database. Never use it for health data,
// hard rules or tokens: hard rules are not stored on the phone at all, and
// tokens go to secure storage (token_store.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// Settings in the drift [AppDatabase] `settings` table. All rows are read
/// once at startup, so reads are synchronous; writes go straight to the
/// database.
final class DriftSettingsStore implements KeyValueStore {
  DriftSettingsStore._(this._db, this._values);

  final AppDatabase _db;
  final Map<String, String> _values;

  static Future<DriftSettingsStore> open(AppDatabase db) async {
    final rows = await db.select(db.settings).get();
    return DriftSettingsStore._(db, {
      for (final row in rows)
        if (PreferenceKeys.all.contains(row.key)) row.key: row.value,
    });
  }

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
    await (_db.delete(_db.settings)..where((t) => t.key.equals(key))).go();
  }
}

final class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? initial])
    : _values = {...?initial};

  final Map<String, String> _values;

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}

abstract final class PreferenceKeys {
  static const locale = 'settings.locale';
  static const themeMode = 'settings.themeMode';

  /// Random ID of this app installation (contract `DeviceInfo`).
  static const installationId = 'device.installationId';

  static const Set<String> all = {locale, themeMode, installationId};
}

/// Overridden in main() with the opened store, and in tests with
/// [InMemoryKeyValueStore].
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => throw StateError('keyValueStoreProvider must be overridden'),
);
