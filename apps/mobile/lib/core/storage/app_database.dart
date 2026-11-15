// The on-device SQLite database (drift), ARCHITECTURE 1 and 5.
//
// What is stored here, and what is not:
// - Settings the app keeps on this phone (language, theme, installation ID).
// - A cache of the household, the family profiles and the standard allergen
//   list, so screens can show names offline.
// - A cache of the saved kitchen (Dapur Saya, T-033): household data, not
//   health data, bound to the account like the profiles. In T-033 it is a
//   copy of the server's list only; changes made offline (T-034) will live
//   in a table of their own with step-by-step migrations.
// - The reference ingredient catalog (public reference data, KIT-04) with
//   its ETag, for offline search. Not personal: kept across accounts.
// - NO health data. Hard rules and the health-data consent state are never
//   written to this database, in any form (DAT-02, QUESTIONS #39). A cached
//   profile therefore has no rules, and the app shows its rules as
//   unavailable until the API answers; it never reads the absence of cached
//   rules as "no rules". Tokens live in secure storage, not here.
//
// Migration strategy (see [AppDatabase.migration]):
// - Cache tables hold copies of server data. On any schema change, including
//   a downgrade, they are dropped and recreated, and refill on the next
//   successful API call.
// - Tables that hold data only this phone has (settings now; the kitchen in
//   T-033 and T-034) get step-by-step migrations generated with
//   `dart run drift_dev make-migrations`, tested in test/drift/.
// After changing a table: bump [AppDatabase.schemaVersion], run
// `dart run drift_dev make-migrations`, then `dart run build_runner build`.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// App preferences kept on this phone (not synced).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// The household (contract `Household`), at most one row.
class CachedHouseholds extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get city => text().nullable()();

  /// IANA name as the API sent it.
  TextColumn get timeZone => text()();

  /// Contract `Language` wire value.
  TextColumn get language => text()();
  TextColumn get managerAccountId => text()();
  TextColumn get managerProfileId => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Family profiles without any health data: no hard rules, no consent state.
class CachedProfiles extends Table {
  TextColumn get id => text()();

  /// Order from the API (manager first).
  IntColumn get position => integer()();
  TextColumn get name => text()();

  /// Contract `AgeGroup` wire value.
  TextColumn get ageGroup => text()();
  BoolColumn get isChild => boolean()();
  BoolColumn get isManager => boolean()();

  /// Contract `AvatarStyle` wire value.
  TextColumn get avatarStyle => text()();
  TextColumn get avatarColorToken => text().nullable()();
  TextColumn get avatarIllustrationId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The standard allergen list (public reference data, PRF-04), in display
/// order.
class CachedAllergens extends Table {
  /// Contract `StandardAllergen` wire value.
  TextColumn get code => text()();
  IntColumn get position => integer()();
  TextColumn get ruleSetVersion => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {code};
}

/// The saved kitchen's list-level fields (contract `KitchenItemList`), at
/// most one row. Its presence tells "cached, empty" apart from "no copy".
class CachedKitchens extends Table {
  IntColumn get id => integer()();
  IntColumn get maxItems => integer()();
  TextColumn get referenceVersion => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Saved kitchen items (contract `KitchenItem`, KIT-01). Household data, no
/// health data.
class CachedKitchenItems extends Table {
  TextColumn get id => text()();

  /// Order from the API (KIT-03 category order).
  IntColumn get position => integer()();
  TextColumn get ingredientId => text().nullable()();
  BoolColumn get isCustom => boolean()();
  TextColumn get displayNameId => text().nullable()();
  TextColumn get displayNameEn => text().nullable()();
  TextColumn get customName => text().nullable()();

  /// Contract `KitchenCategory` wire value.
  TextColumn get category => text()();

  /// Contract `KitchenItemState` wire value.
  TextColumn get state => text()();
  BoolColumn get isDefaultStaple => boolean()();
  IntColumn get usageRank => integer().nullable()();
  DateTimeColumn get changedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The catalog's version and ETag (contract `ReferenceIngredientCatalog`),
/// at most one row.
class CachedCatalogs extends Table {
  IntColumn get id => integer()();
  TextColumn get referenceVersion => text()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Reference ingredients for offline search (contract `CatalogIngredient`).
/// No safety data: the contract carries none.
class CachedCatalogIngredients extends Table {
  TextColumn get ingredientId => text()();
  IntColumn get position => integer()();
  TextColumn get nameId => text()();
  TextColumn get nameEn => text()();

  /// JSON array of strings.
  TextColumn get localNames => text()();

  /// Contract `KitchenCategory` wire value, or null.
  TextColumn get category => text().nullable()();
  BoolColumn get brandVaries => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {ingredientId};
}

@DriftDatabase(
  tables: [
    Settings,
    CachedHouseholds,
    CachedProfiles,
    CachedAllergens,
    CachedKitchens,
    CachedKitchenItems,
    CachedCatalogs,
    CachedCatalogIngredients,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The app's database file in the app's private storage.
  factory AppDatabase.open() =>
      AppDatabase(driftDatabase(name: 'keluargamakan'));

  @override
  int get schemaVersion => 2;

  /// Tables that copy server data and can be rebuilt from it.
  List<TableInfo<Table, Object?>> get cacheTables => [
    cachedHouseholds,
    cachedProfiles,
    cachedAllergens,
    cachedKitchens,
    cachedKitchenItems,
    cachedCatalogs,
    cachedCatalogIngredients,
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from > to) {
        // A downgrade (sideloaded older build): the newer schema is unknown,
        // so start again. Settings reset to their defaults. Every table on
        // disk goes, including ones only the newer build knows, so nothing
        // it stored (names, offline changes) stays behind where
        // clearUserData cannot reach it (security review T-033 L5).
        final onDisk = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        ).get();
        for (final row in onDisk) {
          final name = row.read<String>('name').replaceAll('"', '""');
          await customStatement('DROP TABLE IF EXISTS "$name"');
        }
        await m.createAll();
        return;
      }
      // Step-by-step migrations for settings (and later the kitchen's
      // offline changes, T-034) go here, generated by `drift_dev
      // make-migrations`. None yet: v2 only added cache tables.
      for (final table in cacheTables) {
        await m.deleteTable(table.actualTableName);
        await m.createTable(table);
      }
    },
  );

  /// Settings row naming the account whose household the cache holds
  /// (security review M2). Not a user preference: removed with the cache.
  static const cacheOwnerKey = 'cache.ownerAccountId';

  /// Removes everything that belongs to the signed-in household: the
  /// household, profile and kitchen caches and their owner. Settings and public
  /// reference data stay. Runs when the session ends (sign-out, or the server
  /// ended the session on a shared phone), at startup without a session, and
  /// when a different account signs in.
  Future<void> clearUserData() => transaction(() async {
    await delete(cachedProfiles).go();
    await delete(cachedKitchenItems).go();
    await delete(cachedKitchens).go();
    await delete(cachedHouseholds).go();
    await (delete(settings)..where((t) => t.key.equals(cacheOwnerKey))).go();
  });
}

/// Overridden in main() with the opened database, and in tests with an
/// in-memory one.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('appDatabaseProvider must be overridden'),
);
