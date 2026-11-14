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

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../core/api/api_client.dart';
import '../core/storage/app_database.dart';
import 'models/family.dart';
import 'models/household.dart';
import 'models/kitchen.dart';
import 'models/sourced.dart';

typedef Clock = DateTime Function();

final class LocalCache {
  LocalCache(this._db, {required this._currentAccountId, Clock? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final String? Function() _currentAccountId;
  final Clock _now;

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

  /// Runs [write] for the signed-in account; does nothing when signed out.
  Future<void> _writeAsOwner(Future<void> Function() write) async {
    final account = _currentAccountId();
    if (account == null) return;
    await _db.transaction(() async {
      await claimFor(account);
      await write();
    });
  }

  // ------------------------------------------------------------ Household

  Future<void> saveHousehold(HouseholdInfo h) => _writeAsOwner(() async {
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

  Future<HouseholdInfo?> household() async {
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

  Future<void> removeProfile(String id) =>
      (_db.delete(_db.cachedProfiles)..where((t) => t.id.equals(id))).go();

  /// The cached profiles with [RulesNotLoaded], or null when there is no
  /// usable cached copy.
  Future<FamilyProfiles?> profiles() async {
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

  Future<void> saveAllergens(AllergenReference list) =>
      _db.transaction(() async {
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
      });

  Future<AllergenReference?> allergens() async {
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
  Future<void> saveKitchen(KitchenList list, {required String accountId}) =>
      _db.transaction(() async {
        if (_currentAccountId() != accountId) return;
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
              ),
          ]);
        });
      });

  /// The cached kitchen, or null when there is no usable copy for the
  /// signed-in account.
  Future<KitchenList?> kitchen() async {
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
        ),
      );
    }
    return KitchenList(
      items: items,
      maxItems: meta.maxItems,
      referenceVersion: meta.referenceVersion,
      source: FromCache(meta.cachedAt),
    );
  }

  // ------------------------------------------------------------ Catalog

  /// Replaces the cached reference catalog. Public reference data: not
  /// bound to an account and kept when the session ends.
  Future<void> saveCatalog(IngredientCatalog catalog) =>
      _db.transaction(() async {
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
              ),
          ]);
        });
      });

  /// Records that the cached catalog was confirmed current (304).
  Future<void> touchCatalog() =>
      (_db.update(_db.cachedCatalogs))
          .write(CachedCatalogsCompanion(cachedAt: Value(_now().toUtc())));

  /// The cached catalog, or null when there is no usable copy.
  Future<IngredientCatalog?> catalog() async {
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
      items.add(
        CatalogEntry(
          ingredientId: row.ingredientId,
          displayName: BilingualName(id: row.nameId, en: row.nameEn),
          localNames: names.cast<String>(),
          category: api.KitchenCategory.fromJson(row.category),
          brandVaries: row.brandVaries,
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
  ),
);
