// Reads and writes the drift cache tables. Writes only fields without health
// data: profiles are cached without hard rules or consent state (see
// app_database.dart). A cached row this app version cannot read (for example
// an unknown age group) makes the whole cached copy unusable rather than
// partly shown.
//
// The household and profile caches belong to one account (security review
// M2). They are read only while that account is signed in, and are wiped
// before another account's data is written or a new session starts.
//
// The same holds in memory (security review T-027 M1): anything holding
// household data in memory must reset on a session change, by watching
// currentAccountIdProvider.
//
// Every read and write here is best effort (security review T-033 M1): a
// failure (storage full, a constraint, a broken file) is logged with the
// operation and the error type only, never its text, which for SQLite
// includes the statement's parameters (names). The caller goes on with the
// network result; a failed read counts as "no copy".
//
// While a session is ending, and for writes stamped with an older session
// epoch, nothing is written (security review T-033, structural note): a
// late answer cannot put an account's data back between the wipe and the
// removal of the tokens.
//
// The kitchen outbox (KIT-16, T-034) follows the same rules: each queued
// change names its account, is read only while that account is signed in
// and owns the cache, is written only under the session epoch it was made
// in, and goes with the rest when the session ends or another account
// signs in.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../core/api/api_client.dart';
import '../core/storage/app_database.dart';
import '../sync/device_clock.dart';
import '../sync/kitchen_change.dart';
import 'models/family.dart';
import 'models/household.dart';
import 'models/kitchen.dart';
import 'models/sourced.dart';

typedef Clock = DateTime Function();

final class LocalCache {
  LocalCache(
    this._db, {
    required this._currentAccountId,
    int Function()? currentEpoch,
    bool Function()? sessionEnding,
    Clock? clock,
  }) : _now = clock ?? DateTime.now,
       _currentEpoch = currentEpoch ?? (() => 0),
       _sessionEnding = sessionEnding ?? (() => false);

  final AppDatabase _db;
  final String? Function() _currentAccountId;
  final int Function() _currentEpoch;
  final bool Function() _sessionEnding;
  final Clock _now;

  /// The session epoch now; a write that starts under it carries it.
  int get epoch => _currentEpoch();

  // ------------------------------------------------------------ Safety net

  /// Runs [write]; a failure is logged by [operation] and error type only.
  Future<void> _bestEffort(
    String operation,
    Future<void> Function() write,
  ) async {
    try {
      await write();
    } on Object catch (e) {
      debugPrint('Cache write failed: $operation (${e.runtimeType})');
    }
  }

  /// Runs [read]; a failure is logged like a write and reads as no copy.
  Future<T?> _readSafely<T>(
    String operation,
    Future<T?> Function() read,
  ) async {
    try {
      return await read();
    } on Object catch (e) {
      debugPrint('Cache read failed: $operation (${e.runtimeType})');
      return null;
    }
  }

  /// Whether a write that started under [epoch] for [accountId] may still
  /// be stored.
  bool _mayWrite(String accountId, int epoch) =>
      !_sessionEnding() &&
      _currentEpoch() == epoch &&
      _currentAccountId() == accountId;

  // ------------------------------------------------------------ Owner

  Future<String?> _owner() async {
    final row = await (_db.select(
      _db.settings,
    )..where((t) => t.key.equals(AppDatabase.cacheOwnerKey))).getSingleOrNull();
    return row?.value;
  }

  /// Makes [accountId] the owner, wiping another account's cached data.
  Future<void> claimFor(String accountId) => _db.transaction(() async {
    if (await _owner() == accountId) return;
    await _db.clearUserData();
    await _db
        .into(_db.settings)
        .insert(
          SettingsCompanion.insert(
            key: AppDatabase.cacheOwnerKey,
            value: accountId,
          ),
        );
  });

  /// Whether the cache belongs to the signed-in account.
  Future<bool> _readable() async {
    final account = _currentAccountId();
    return account != null && await _owner() == account;
  }

  /// Runs [write] for the signed-in account; does nothing when signed out
  /// or while the session is ending. Best effort.
  Future<void> _writeAsOwner(String operation, Future<void> Function() write) =>
      _bestEffort(operation, () async {
        final account = _currentAccountId();
        if (account == null || _sessionEnding()) return;
        final epoch = _currentEpoch();
        await _db.transaction(() async {
          if (!_mayWrite(account, epoch)) return;
          await claimFor(account);
          await write();
        });
      });

  // ------------------------------------------------------------ Household

  Future<void> saveHousehold(HouseholdInfo h) =>
      _writeAsOwner('saveHousehold', () async {
        await _db.delete(_db.cachedHouseholds).go();
        await _db
            .into(_db.cachedHouseholds)
            .insert(
              CachedHouseholdsCompanion.insert(
                id: h.id,
                name: Value(h.name),
                city: Value(h.city),
                timeZone: h.timeZoneName,
                language: h.language.toJson(),
                managerAccountId: h.managerAccountId,
                managerProfileId: h.managerProfileId,
                updatedAt: h.updatedAt,
                cachedAt: _now().toUtc(),
              ),
            );
      });

  Future<HouseholdInfo?> household() => _readSafely('household', _household);

  Future<HouseholdInfo?> _household() async {
    if (!await _readable()) return null;
    final row = await _db.select(_db.cachedHouseholds).getSingleOrNull();
    if (row == null) return null;
    final language = api.Language.fromJson(row.language);
    if (language == null) return null;
    return HouseholdInfo(
      id: row.id,
      name: row.name,
      city: row.city,
      timeZoneName: row.timeZone,
      language: language,
      managerAccountId: row.managerAccountId,
      managerProfileId: row.managerProfileId,
      updatedAt: row.updatedAt,
      source: FromCache(row.cachedAt),
    );
  }

  // ------------------------------------------------------------ Profiles

  /// Replaces the cached profiles with [members]. Rules are not written.
  Future<void> saveProfiles(List<FamilyMember> members) => _writeAsOwner(
    'saveProfiles',
    () async {
      final now = _now().toUtc();
      await _db.delete(_db.cachedProfiles).go();
      await _db.batch((b) {
        b.insertAll(_db.cachedProfiles, [
          for (final (i, m) in members.indexed)
            CachedProfilesCompanion.insert(
              id: m.id,
              position: i,
              name: m.name,
              ageGroup: m.ageGroup.toJson(),
              isChild: m.isChild,
              isManager: m.isManager,
              avatarStyle: m.avatar.style.toJson(),
              avatarColorToken: Value(m.avatar.colorToken.orElse(null)),
              avatarIllustrationId: Value(m.avatar.illustrationId.orElse(null)),
              updatedAt: m.updatedAt,
              cachedAt: now,
            ),
        ]);
      });
    },
  );

  Future<void> removeProfile(String id) => _bestEffort(
    'removeProfile',
    () => (_db.delete(_db.cachedProfiles)..where((t) => t.id.equals(id))).go(),
  );

  /// The cached profiles with [RulesNotLoaded], or null when there is no
  /// usable cached copy.
  Future<FamilyProfiles?> profiles() => _readSafely('profiles', _profiles);

  Future<FamilyProfiles?> _profiles() async {
    if (!await _readable()) return null;
    final rows = await (_db.select(
      _db.cachedProfiles,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    if (rows.isEmpty) return null;
    final members = <FamilyMember>[];
    for (final row in rows) {
      final ageGroup = api.AgeGroup.fromJson(row.ageGroup);
      final style = api.AvatarStyle.fromJson(row.avatarStyle);
      if (ageGroup == null || style == null) return null;
      members.add(
        FamilyMember(
          id: row.id,
          name: row.name,
          avatar: api.Avatar(
            style: style,
            colorToken: api.Optional.present(row.avatarColorToken),
            illustrationId: api.Optional.present(row.avatarIllustrationId),
          ),
          ageGroup: ageGroup,
          isChild: row.isChild,
          isManager: row.isManager,
          rules: const RulesNotLoaded(),
          updatedAt: row.updatedAt,
        ),
      );
    }
    final oldest = rows
        .map((r) => r.cachedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return FamilyProfiles(
      members: members,
      maxProfiles: null,
      source: FromCache(oldest),
    );
  }

  // ------------------------------------------------------------ Allergens

  Future<void> saveAllergens(AllergenReference list) => _bestEffort(
    'saveAllergens',
    () => _db.transaction(() async {
      final now = _now().toUtc();
      await _db.delete(_db.cachedAllergens).go();
      await _db.batch((b) {
        b.insertAll(_db.cachedAllergens, [
          for (final (i, code) in list.items.indexed)
            CachedAllergensCompanion.insert(
              code: code.toJson(),
              position: i,
              ruleSetVersion: list.ruleSetVersion,
              cachedAt: now,
            ),
        ]);
      });
    }),
  );

  Future<AllergenReference?> allergens() =>
      _readSafely('allergens', _allergens);

  Future<AllergenReference?> _allergens() async {
    final rows = await (_db.select(
      _db.cachedAllergens,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    if (rows.isEmpty) return null;
    final items = <api.StandardAllergen>[];
    for (final row in rows) {
      final code = api.StandardAllergen.fromJson(row.code);
      // A code from a newer app version: leave it out, as the decoder does.
      if (code != null) items.add(code);
    }
    return AllergenReference(
      ruleSetVersion: rows.first.ruleSetVersion,
      items: items,
      source: FromCache(rows.first.cachedAt),
    );
  }

  // ------------------------------------------------------------ Kitchen

  /// Replaces the cached kitchen with [list], only while [accountId] is
  /// still the signed-in account (checked inside the write, so an answer
  /// that arrives after another account signed in is never stored for it).
  Future<void> saveKitchen(
    KitchenList list, {
    required String accountId,
    required int epoch,
    String? cursor,
  }) => _bestEffort(
    'saveKitchen',
    () => _db.transaction(() async {
      if (!_mayWrite(accountId, epoch)) return;
      await claimFor(accountId);
      final now = _now().toUtc();
      await _db.delete(_db.cachedKitchenItems).go();
      await _db.delete(_db.cachedKitchens).go();
      await _db
          .into(_db.cachedKitchens)
          .insert(
            CachedKitchensCompanion.insert(
              id: const Value(1),
              maxItems: list.maxItems,
              referenceVersion: Value(list.referenceVersion),
              cachedAt: now,
              syncCursor: Value(cursor),
            ),
          );
      await _db.batch((b) {
        b.insertAll(_db.cachedKitchenItems, [
          for (final (i, item) in list.items.indexed)
            CachedKitchenItemsCompanion.insert(
              id: item.id,
              position: i,
              ingredientId: Value(item.ingredientId),
              isCustom: item.isCustom,
              displayNameId: Value(item.displayName?.id),
              displayNameEn: Value(item.displayName?.en),
              customName: Value(item.customName),
              category: item.category.toJson(),
              state: item.state.wire,
              isDefaultStaple: item.isDefaultStaple,
              usageRank: Value(item.usageRank),
              changedAt: item.changedAt,
              createdAt: item.createdAt,
              quantity: Value(item.quantity?.wire),
              brandId: Value(switch (item.brand) {
                ReferenceBrand(:final brandId) => brandId,
                _ => null,
              }),
              brandName: Value(item.brand?.name),
            ),
        ]);
      });
    }),
  );

  /// The cached kitchen, or null when there is no usable copy for the
  /// signed-in account.
  Future<KitchenList?> kitchen() async => (await kitchenWithCursor())?.list;

  /// The cached kitchen with the cursor of the sync that gave it (KIT-16).
  Future<({KitchenList list, String? cursor})?> kitchenWithCursor() =>
      _readSafely('kitchen', _kitchen);

  Future<({KitchenList list, String? cursor})?> _kitchen() async {
    if (!await _readable()) return null;
    final meta = await _db.select(_db.cachedKitchens).getSingleOrNull();
    if (meta == null) return null;
    final rows = await (_db.select(
      _db.cachedKitchenItems,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    final items = <KitchenEntry>[];
    for (final row in rows) {
      final category = api.KitchenCategory.fromJson(row.category);
      if (category == null) return null;
      final nameId = row.displayNameId;
      final nameEn = row.displayNameEn;
      items.add(
        KitchenEntry(
          id: row.id,
          ingredientId: row.ingredientId,
          displayName: nameId != null && nameEn != null
              ? BilingualName(id: nameId, en: nameEn)
              : null,
          customName: row.customName,
          category: category,
          state: KitchenItemState.fromWire(row.state),
          isDefaultStaple: row.isDefaultStaple,
          usageRank: row.usageRank,
          changedAt: row.changedAt,
          createdAt: row.createdAt,
          quantity: KitchenAmount.fromWire(row.quantity),
          brand: switch ((row.brandId, row.brandName)) {
            (final String id, final String name) => ReferenceBrand(id, name),
            (null, final String name) => TypedBrand(name),
            _ => null,
          },
        ),
      );
    }
    return (
      list: KitchenList(
        items: items,
        maxItems: meta.maxItems,
        referenceVersion: meta.referenceVersion,
        source: FromCache(meta.cachedAt),
      ),
      cursor: meta.syncCursor,
    );
  }

  // ------------------------------------------------------------ Outbox

  /// The kitchen changes queued on this phone for the signed-in account,
  /// oldest first, or null when nothing can be read for it. A row this app
  /// version cannot read is dropped: it is never sent half understood.
  Future<List<QueuedChange>?> outbox() => _readSafely('outbox', _outbox);

  Future<List<QueuedChange>?> _outbox() async {
    if (!await _readable()) return null;
    final account = _currentAccountId();
    if (account == null) return null;
    final rows =
        await (_db.select(_db.kitchenOutbox)
              ..where((t) => t.accountId.equals(account))
              ..orderBy([(t) => OrderingTerm(expression: t.seq)]))
            .get();
    final changes = <QueuedChange>[];
    final unreadable = <int>[];
    for (final row in rows) {
      final change = _readChange(row);
      if (change == null) {
        unreadable.add(row.seq);
      } else {
        changes.add(change);
      }
    }
    if (unreadable.isNotEmpty) {
      debugPrint('Outbox rows dropped (unreadable)');
      await (_db.delete(
        _db.kitchenOutbox,
      )..where((t) => t.seq.isIn(unreadable))).go();
    }
    return changes;
  }

  static QueuedChange? _readChange(KitchenOutboxData row) {
    final IngredientKey ingredient;
    switch ((row.ingredientId, row.customName)) {
      case (final String id, null):
        ingredient = ReferenceIngredient(id);
      case (null, final String name):
        ingredient = CustomIngredient(name);
      case _:
        return null;
    }
    final op = switch (row.operation) {
      'upsert' => KitchenChangeOp.upsert,
      'remove' => KitchenChangeOp.remove,
      _ => null,
    };
    if (op == null) return null;
    final KitchenPatch patch;
    try {
      patch = KitchenPatch.fromJson(jsonDecode(row.patch));
    } on FormatException {
      return null;
    }
    return QueuedChange(
      seq: row.seq,
      changeId: row.changeId,
      ingredient: ingredient,
      op: op,
      patch: patch,
      stamp: ClockReading(
        timeline: row.timeline,
        elapsedMs: row.elapsedMs,
        wallMs: row.wallMs,
      ),
      sendAttempts: row.sendAttempts,
    );
  }

  /// How many changes are queued for [accountId] (no other data is read).
  Future<int> outboxCount(String accountId) async =>
      await _readSafely('outboxCount', () async {
        final count = _db.kitchenOutbox.seq.count();
        final query = _db.selectOnly(_db.kitchenOutbox)
          ..addColumns([count])
          ..where(_db.kitchenOutbox.accountId.equals(accountId));
        return (await query.getSingle()).read(count);
      }) ??
      0;

  /// Queues [change] for [accountId] and drops the changes it replaces
  /// ([changesReplacedBy]), in one transaction, only while that account's
  /// session of [epoch] is current. Best effort: false when nothing was
  /// written.
  Future<bool> queueKitchenChange(
    QueuedChange change, {
    required Set<String> replacing,
    required String accountId,
    required int epoch,
  }) async {
    var written = false;
    await _bestEffort(
      'queueKitchenChange',
      () => _db.transaction(() async {
        if (!_mayWrite(accountId, epoch)) return;
        await claimFor(accountId);
        if (replacing.isNotEmpty) {
          await (_db.delete(
            _db.kitchenOutbox,
          )..where((t) => t.changeId.isIn(replacing))).go();
        }
        final (ingredientId, customName) = switch (change.ingredient) {
          ReferenceIngredient(:final ingredientId) => (ingredientId, null),
          CustomIngredient(:final name) => (null, name),
        };
        await _db
            .into(_db.kitchenOutbox)
            .insert(
              KitchenOutboxCompanion.insert(
                accountId: accountId,
                changeId: change.changeId,
                ingredientId: Value(ingredientId),
                customName: Value(customName),
                operation: change.op.name,
                patch: change.patchJson(),
                timeline: change.stamp.timeline,
                elapsedMs: change.stamp.elapsedMs,
                wallMs: change.stamp.wallMs,
              ),
            );
        written = true;
      }),
    );
    return written;
  }

  /// Records that [changeIds] are about to be sent once more (written
  /// before the request goes out). Best effort.
  Future<void> markKitchenChangesSent(Iterable<String> changeIds) {
    final ids = changeIds.toList();
    if (ids.isEmpty) return Future.value();
    return _bestEffort(
      'markKitchenChangesSent',
      () => _db.customUpdate(
        'UPDATE kitchen_outbox SET send_attempts = send_attempts + 1 '
        'WHERE change_id IN (${List.filled(ids.length, '?').join(', ')})',
        variables: [for (final id in ids) Variable<String>(id)],
        updates: {_db.kitchenOutbox},
      ),
    );
  }

  /// Removes answered (or dropped) changes. Removing never exposes data, so
  /// it needs no session check.
  Future<void> unqueueKitchenChanges(Iterable<String> changeIds) {
    final ids = changeIds.toList();
    if (ids.isEmpty) return Future.value();
    return _bestEffort(
      'unqueueKitchenChanges',
      () => (_db.delete(
        _db.kitchenOutbox,
      )..where((t) => t.changeId.isIn(ids))).go(),
    );
  }

  // ------------------------------------------------------------ Sets

  /// Replaces the cached ingredient sets (KIT-08) for [accountId].
  Future<void> saveSets(
    IngredientSets sets, {
    required String accountId,
    required int epoch,
  }) => _bestEffort(
    'saveSets',
    () => _db.transaction(() async {
      if (!_mayWrite(accountId, epoch)) return;
      await claimFor(accountId);
      final now = _now().toUtc();
      await _db.delete(_db.cachedIngredientSets).go();
      await _db.delete(_db.cachedIngredientSetLists).go();
      await _db
          .into(_db.cachedIngredientSetLists)
          .insert(
            CachedIngredientSetListsCompanion.insert(
              id: const Value(1),
              maxSets: sets.maxSets,
              cachedAt: now,
            ),
          );
      await _db.batch((b) {
        b.insertAll(_db.cachedIngredientSets, [
          for (final (i, set) in sets.items.indexed)
            CachedIngredientSetsCompanion.insert(
              id: set.id,
              position: i,
              name: set.name,
              itemIds: jsonEncode(set.itemIds),
              updatedAt: set.updatedAt,
            ),
        ]);
      });
    }),
  );

  /// The cached sets, or null when there is no usable copy.
  Future<IngredientSets?> sets() => _readSafely('sets', _sets);

  Future<IngredientSets?> _sets() async {
    if (!await _readable()) return null;
    final meta = await _db
        .select(_db.cachedIngredientSetLists)
        .getSingleOrNull();
    if (meta == null) return null;
    final rows = await (_db.select(
      _db.cachedIngredientSets,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    final items = <IngredientSetInfo>[];
    for (final row in rows) {
      final Object? ids;
      try {
        ids = jsonDecode(row.itemIds);
      } on FormatException {
        return null;
      }
      if (ids is! List || ids.any((i) => i is! String)) return null;
      items.add(
        IngredientSetInfo(
          id: row.id,
          name: row.name,
          itemIds: ids.cast<String>(),
          updatedAt: row.updatedAt,
        ),
      );
    }
    return IngredientSets(
      items: items,
      maxSets: meta.maxSets,
      source: FromCache(meta.cachedAt),
    );
  }

  // ------------------------------------------------------------ Catalog

  /// Replaces the cached reference catalog. Public reference data: not
  /// bound to an account and kept when the session ends.
  Future<void> saveCatalog(IngredientCatalog catalog) => _bestEffort(
    'saveCatalog',
    () => _db.transaction(() async {
      final now = _now().toUtc();
      await _db.delete(_db.cachedCatalogIngredients).go();
      await _db.delete(_db.cachedCatalogs).go();
      await _db
          .into(_db.cachedCatalogs)
          .insert(
            CachedCatalogsCompanion.insert(
              id: const Value(1),
              referenceVersion: catalog.referenceVersion,
              etag: Value(catalog.etag),
              cachedAt: now,
            ),
          );
      await _db.batch((b) {
        b.insertAll(_db.cachedCatalogIngredients, [
          for (final (i, item) in catalog.items.indexed)
            CachedCatalogIngredientsCompanion.insert(
              ingredientId: item.ingredientId,
              position: i,
              nameId: item.displayName.id,
              nameEn: item.displayName.en,
              localNames: jsonEncode(item.localNames),
              category: Value(item.category?.toJson()),
              brandVaries: item.brandVaries,
              brands: Value(
                jsonEncode([
                  for (final b in item.brands)
                    {'brandId': b.brandId, 'name': b.name},
                ]),
              ),
            ),
        ]);
      });
    }),
  );

  /// Records that the cached catalog was confirmed current (304).
  Future<void> touchCatalog() => _bestEffort(
    'touchCatalog',
    () =>
        (_db.update(_db.cachedCatalogs))
            .write(CachedCatalogsCompanion(cachedAt: Value(_now().toUtc()))),
  );

  /// The cached catalog, or null when there is no usable copy.
  Future<IngredientCatalog?> catalog() => _readSafely('catalog', _catalog);

  Future<IngredientCatalog?> _catalog() async {
    final meta = await _db.select(_db.cachedCatalogs).getSingleOrNull();
    if (meta == null) return null;
    final rows = await (_db.select(
      _db.cachedCatalogIngredients,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    final items = <CatalogEntry>[];
    for (final row in rows) {
      final Object? names;
      try {
        names = jsonDecode(row.localNames);
      } on FormatException {
        return null;
      }
      if (names is! List || names.any((n) => n is! String)) return null;
      final Object? brands;
      try {
        brands = jsonDecode(row.brands);
      } on FormatException {
        return null;
      }
      if (brands is! List) return null;
      final catalogBrands = <CatalogBrand>[];
      for (final brand in brands) {
        if (brand case {'brandId': final String id, 'name': final String n}) {
          catalogBrands.add(CatalogBrand(brandId: id, name: n));
        } else {
          return null;
        }
      }
      items.add(
        CatalogEntry(
          ingredientId: row.ingredientId,
          displayName: BilingualName(id: row.nameId, en: row.nameEn),
          localNames: names.cast<String>(),
          category: api.KitchenCategory.fromJson(row.category),
          brandVaries: row.brandVaries,
          brands: catalogBrands,
        ),
      );
    }
    return IngredientCatalog(
      referenceVersion: meta.referenceVersion,
      etag: meta.etag,
      items: items,
      source: FromCache(meta.cachedAt),
    );
  }
}

final localCacheProvider = Provider<LocalCache>(
  (ref) => LocalCache(
    ref.watch(appDatabaseProvider),
    currentAccountId: () => ref.read(sessionManagerProvider).current?.accountId,
    currentEpoch: () => ref.read(sessionManagerProvider).epoch,
    sessionEnding: () => ref.read(sessionManagerProvider).isEnding,
  ),
);
