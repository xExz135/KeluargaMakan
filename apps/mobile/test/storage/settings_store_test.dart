// ACC-09, INT-05: the language and theme settings live in the drift
// database and survive an app restart.

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('ACC-09 settings written in one session are read in the next', () async {
    final dir = await Directory.systemTemp.createTemp('km_settings_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    final store = await DriftSettingsStore.open(first);
    await store.setString(PreferenceKeys.locale, 'en');
    await store.setString(PreferenceKeys.themeMode, 'dark');
    await store.setString(PreferenceKeys.themeMode, 'light');
    expect(store.getString(PreferenceKeys.themeMode), 'light');
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    final reopened = await DriftSettingsStore.open(second);
    expect(reopened.getString(PreferenceKeys.locale), 'en');
    expect(reopened.getString(PreferenceKeys.themeMode), 'light');

    await reopened.remove(PreferenceKeys.locale);
    expect(reopened.getString(PreferenceKeys.locale), isNull);
    expect(await second.select(second.settings).get(), hasLength(1));
    await second.close();
  });

  test('ACC-09 keys the app does not know are ignored', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.settings)
        .insert(SettingsCompanion.insert(key: 'old.key', value: 'x'));
    final store = await DriftSettingsStore.open(db);
    expect(store.getString('old.key'), isNull);
  });
}
