// Reads and writes the drift cache tables. Writes only fields without health
// data: profiles are cached without hard rules or consent state (see
// app_database.dart). A cached row this app version cannot read (for example
// an unknown age group) makes the whole cached copy unusable rather than
// partly shown.

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../core/storage/app_database.dart';
import 'models/family.dart';
import 'models/household.dart';
import 'models/sourced.dart';

typedef Clock = DateTime Function();

final class LocalCache {
  LocalCache(this._db, {Clock? clock}) : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Clock _now;

  // ------------------------------------------------------------ Household

  Future<void> saveHousehold(HouseholdInfo h) => _db.transaction(() async {
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
  Future<void> saveProfiles(List<FamilyMember> members) => _db.transaction(
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
}

final localCacheProvider = Provider<LocalCache>(
  (ref) => LocalCache(ref.watch(appDatabaseProvider)),
);
