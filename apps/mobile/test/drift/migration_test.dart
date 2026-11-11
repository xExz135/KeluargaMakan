// NFR-05: the on-device database, its schema and its migration strategy.
// TEST FIXTURE: not real safety or nutrition data.

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/storage/app_database.dart';

import 'app_database/generated/schema.dart';

/// The same tables with a higher version, to exercise onUpgrade.
class _FutureVersion extends AppDatabase {
  _FutureVersion(super.e, this.version);

  final int version;

  @override
  int get schemaVersion => version;
}

Future<void> _seed(AppDatabase db) async {
  await db
      .into(db.settings)
      .insert(SettingsCompanion.insert(key: 'settings.locale', value: 'en'));
  await db
      .into(db.cachedHouseholds)
      .insert(
        CachedHouseholdsCompanion.insert(
          id: 'hh-1',
          timeZone: 'Asia/Jakarta',
          language: 'id',
          managerAccountId: 'acc-1',
          managerProfileId: 'p-1',
          updatedAt: DateTime.utc(2026, 11, 1),
          cachedAt: DateTime.utc(2026, 11, 1),
        ),
      );
  await db
      .into(db.cachedAllergens)
      .insert(
        CachedAllergensCompanion.insert(
          code: 'peanut',
          position: 0,
          ruleSetVersion: '1.1.0',
          cachedAt: DateTime.utc(2026, 11, 1),
        ),
      );
}

Future<Directory> _tempDir() async {
  final dir = await Directory.systemTemp.createTemp('km_drift_');
  addTearDown(() => dir.delete(recursive: true));
  return dir;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('NFR-05 a new database matches the v1 schema dump', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 1);
    await db.close();
  });

  test('NFR-05 a schema upgrade rebuilds cache tables and keeps '
      'settings', () async {
    final dir = await _tempDir();
    final path = '${dir.path}/upgrade.sqlite';
    final v1 = AppDatabase(NativeDatabase(File(path)));
    await _seed(v1);
    await v1.close();

    final v2 = _FutureVersion(NativeDatabase(File(path)), 2);
    expect(await v2.select(v2.cachedHouseholds).get(), isEmpty);
    expect(await v2.select(v2.cachedAllergens).get(), isEmpty);
    final settings = await v2.select(v2.settings).get();
    expect(settings.single.key, 'settings.locale');
    expect(settings.single.value, 'en');
    await v2.close();
  });

  test('NFR-05 a downgrade from an unknown newer schema starts '
      'again', () async {
    final dir = await _tempDir();
    final path = '${dir.path}/downgrade.sqlite';
    final newer = _FutureVersion(NativeDatabase(File(path)), 7);
    await _seed(newer);
    await newer.close();

    final v1 = AppDatabase(NativeDatabase(File(path)));
    expect(await v1.select(v1.settings).get(), isEmpty);
    expect(await v1.select(v1.cachedHouseholds).get(), isEmpty);
    final version = await v1.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 1);
    await v1.close();
  });

  test('ACC-13 clearing user data removes the household and profiles but '
      'keeps settings and public reference data', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await _seed(db);
    await db
        .into(db.cachedProfiles)
        .insert(
          CachedProfilesCompanion.insert(
            id: 'p-1',
            position: 0,
            name: 'Ibu',
            ageGroup: 'adult',
            isChild: false,
            isManager: true,
            avatarStyle: 'initials',
            updatedAt: DateTime.utc(2026, 11, 1),
            cachedAt: DateTime.utc(2026, 11, 1),
          ),
        );

    await db.clearUserData();

    expect(await db.select(db.cachedProfiles).get(), isEmpty);
    expect(await db.select(db.cachedHouseholds).get(), isEmpty);
    expect(await db.select(db.settings).get(), hasLength(1));
    expect(await db.select(db.cachedAllergens).get(), hasLength(1));
    await db.close();
  });

  test('DAT-02 no table can hold hard rules or consent state', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final columns = <String>[
      for (final table in db.allTables)
        for (final column in table.$columns) column.name.toLowerCase(),
    ];
    for (final forbidden in [
      'hard_rule',
      'rules',
      'consent',
      'free_text',
      'mapping',
    ]) {
      expect(
        columns.where((c) => c.contains(forbidden)),
        isEmpty,
        reason: 'column containing "$forbidden"',
      );
    }
    await db.close();
  });
}
