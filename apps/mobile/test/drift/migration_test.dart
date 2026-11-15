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

  test('NFR-05 a new database matches the v4 schema dump', () async {
    final connection = await verifier.startAt(4);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 4);
    await db.close();
  });

  test('NFR-05 KIT-01 a v1 database upgrades to v4 with the kitchen, '
      'catalog, set and outbox tables and keeps settings', () async {
    final v1 = await verifier.schemaAt(1);
    v1.rawDatabase.execute(
      "INSERT INTO settings (key, value) VALUES ('settings.locale', 'en')",
    );
    final db = AppDatabase(v1.newConnection());
    await verifier.migrateAndValidate(db, 4);
    final settings = await db.select(db.settings).get();
    expect(settings.single.value, 'en');
    expect(await db.select(db.cachedKitchenItems).get(), isEmpty);
    expect(await db.select(db.cachedCatalogIngredients).get(), isEmpty);
    expect(await db.select(db.kitchenOutbox).get(), isEmpty);
    await db.close();
  });

  test('NFR-05 KIT-16 a v2 database upgrades to v4: the outbox is added, the '
      'caches start again and settings stay', () async {
    final v2 = await verifier.schemaAt(2);
    v2.rawDatabase.execute(
      "INSERT INTO settings (key, value) VALUES ('settings.locale', 'en')",
    );
    final db = AppDatabase(v2.newConnection());
    await verifier.migrateAndValidate(db, 4);
    expect((await db.select(db.settings).get()).single.value, 'en');
    expect(await db.select(db.kitchenOutbox).get(), isEmpty);
    await db.close();
  });

  test('NFR-05 KIT-16 L6 a v3 database upgrades to v4: queued changes stay, '
      'counted as never sent', () async {
    final v3 = await verifier.schemaAt(3);
    v3.rawDatabase.execute(
      'INSERT INTO kitchen_outbox (account_id, change_id, ingredient_id, '
      'custom_name, operation, patch, timeline, elapsed_ms, wall_ms) VALUES '
      "('acc-1', 'c-1', 'fx_kit_tempe', NULL, 'upsert', '{}', 'boot:1', 0, 0)",
    );
    final db = AppDatabase(v3.newConnection());
    await verifier.migrateAndValidate(db, 4);
    final row = (await db.select(db.kitchenOutbox).get()).single;
    expect(row.changeId, 'c-1');
    expect(row.sendAttempts, 0);
    await db.close();
  });

  test('NFR-05 KIT-16 a schema upgrade keeps the kitchen outbox (data only '
      'this phone has) while caches start again', () async {
    final dir = await _tempDir();
    final path = '${dir.path}/outbox.sqlite';
    final v3 = AppDatabase(NativeDatabase(File(path)));
    await _seed(v3);
    await v3
        .into(v3.kitchenOutbox)
        .insert(
          KitchenOutboxCompanion.insert(
            accountId: 'acc-1',
            changeId: '6f1a2b3c-4d5e-4f60-8a7b-000000000001',
            ingredientId: const Value('fx_kit_tempe'),
            operation: 'upsert',
            patch: '{"state":"out"}',
            timeline: 'boot:1',
            elapsedMs: 1000,
            wallMs: 1763190000000,
          ),
        );
    await v3.close();

    final v5 = _FutureVersion(NativeDatabase(File(path)), 5);
    expect(await v5.select(v5.cachedHouseholds).get(), isEmpty);
    expect(
      (await v5.select(v5.kitchenOutbox).get()).single.ingredientId,
      'fx_kit_tempe',
    );
    await v5.close();
  });

  test('NFR-05 a schema upgrade rebuilds cache tables and keeps '
      'settings', () async {
    final dir = await _tempDir();
    final path = '${dir.path}/upgrade.sqlite';
    final v1 = AppDatabase(NativeDatabase(File(path)));
    await _seed(v1);
    await v1.close();

    final v5 = _FutureVersion(NativeDatabase(File(path)), 5);
    expect(await v5.select(v5.cachedHouseholds).get(), isEmpty);
    expect(await v5.select(v5.cachedAllergens).get(), isEmpty);
    expect(await v5.select(v5.cachedCatalogs).get(), isEmpty);
    final settings = await v5.select(v5.settings).get();
    expect(settings.single.key, 'settings.locale');
    expect(settings.single.value, 'en');
    await v5.close();
  });

  test('NFR-05 L5 a downgrade from an unknown newer schema starts again and '
      'drops tables only the newer build knows', () async {
    final dir = await _tempDir();
    final path = '${dir.path}/downgrade.sqlite';
    final newer = _FutureVersion(NativeDatabase(File(path)), 7);
    await _seed(newer);
    // A table only the newer build knows, holding a name.
    await newer.customStatement(
      'CREATE TABLE kitchen_future (id TEXT PRIMARY KEY, custom_name TEXT)',
    );
    await newer.customStatement(
      "INSERT INTO kitchen_future VALUES ('c-1', 'Sambal Nenek')",
    );
    await newer
        .into(newer.kitchenOutbox)
        .insert(
          KitchenOutboxCompanion.insert(
            accountId: 'acc-1',
            changeId: '6f1a2b3c-4d5e-4f60-8a7b-000000000002',
            customName: const Value('Sambal Nenek'),
            operation: 'upsert',
            patch: '{}',
            timeline: 'boot:1',
            elapsedMs: 0,
            wallMs: 0,
          ),
        );
    await newer.close();

    final current = AppDatabase(NativeDatabase(File(path)));
    expect(await current.select(current.settings).get(), isEmpty);
    expect(await current.select(current.cachedHouseholds).get(), isEmpty);
    final version = await current
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), current.schemaVersion);
    final tables = await current
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(
      tables.map((t) => t.read<String>('name')),
      isNot(contains('kitchen_future')),
    );
    expect(await current.select(current.kitchenOutbox).get(), isEmpty);
    await current.close();
  });

  test('ACC-13 KIT-01 KIT-16 clearing user data removes the household, '
      'profiles, kitchen, sets and queued changes but keeps settings and '
      'public reference data', () async {
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

    await db
        .into(db.cachedKitchens)
        .insert(
          CachedKitchensCompanion.insert(
            id: const Value(1),
            maxItems: 300,
            cachedAt: DateTime.utc(2026, 11, 1),
          ),
        );
    await db
        .into(db.cachedKitchenItems)
        .insert(
          CachedKitchenItemsCompanion.insert(
            id: 'k-1',
            position: 0,
            isCustom: true,
            customName: const Value('Sambal buatan Ibu'),
            category: 'sauces_condiments',
            state: 'available',
            isDefaultStaple: false,
            changedAt: DateTime.utc(2026, 11, 1),
            createdAt: DateTime.utc(2026, 11, 1),
          ),
        );
    await db
        .into(db.cachedCatalogs)
        .insert(
          CachedCatalogsCompanion.insert(
            id: const Value(1),
            referenceVersion: 'fx-1',
            cachedAt: DateTime.utc(2026, 11, 1),
          ),
        );

    await db
        .into(db.kitchenOutbox)
        .insert(
          KitchenOutboxCompanion.insert(
            accountId: 'acc-1',
            changeId: '6f1a2b3c-4d5e-4f60-8a7b-000000000003',
            customName: const Value('Sambal buatan Ibu'),
            operation: 'upsert',
            patch: '{"state":"out"}',
            timeline: 'boot:1',
            elapsedMs: 0,
            wallMs: 0,
          ),
        );
    await db
        .into(db.cachedIngredientSets)
        .insert(
          CachedIngredientSetsCompanion.insert(
            id: 's-1',
            position: 0,
            name: 'Belanja Ibu',
            itemIds: '["k-1"]',
            updatedAt: DateTime.utc(2026, 11, 1),
          ),
        );

    await db.clearUserData();

    expect(await db.select(db.kitchenOutbox).get(), isEmpty);
    expect(await db.select(db.cachedIngredientSets).get(), isEmpty);
    expect(await db.select(db.cachedProfiles).get(), isEmpty);
    expect(await db.select(db.cachedHouseholds).get(), isEmpty);
    expect(await db.select(db.cachedKitchens).get(), isEmpty);
    expect(await db.select(db.cachedKitchenItems).get(), isEmpty);
    expect(await db.select(db.settings).get(), hasLength(1));
    expect(await db.select(db.cachedAllergens).get(), hasLength(1));
    expect(await db.select(db.cachedCatalogs).get(), hasLength(1));
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
