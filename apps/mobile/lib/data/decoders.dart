// Strict decoding of API payloads into app models.
//
// The generated models are lenient in places that matter for safety:
// - in release builds a missing `items` list decodes as an empty list,
// - list rows that are not objects are skipped silently.
// So a missing or malformed rule list could look like "no rules". These
// decoders check the raw JSON shape first, decode with the generated models,
// and then check that no row was dropped. Any mismatch throws, and
// [ApiCaller] turns it into a DecodeFailure (fail closed, QUESTIONS #39).

import 'package:keluargamakan_api/api.dart' as api;

import '../core/api/api_client.dart';
import 'models/family.dart';
import 'models/household.dart';
import 'models/sourced.dart';

Never _bad(String what) => throw FormatException('Invalid $what');

Map<String, Object?> _object(Object? json, String what) =>
    json is Map<String, Object?> ? json : _bad(what);

List<Object?> _list(Object? json, String what) =>
    json is List<Object?> ? json : _bad(what);

/// The generated `HardRule` reads a wrong-typed `allergen`, `freeText` or
/// `mapping` as null, and a mapped rule without a known confirmer as mapped
/// (security review L1). Check each raw row against the contract first. An
/// allergy with an allergen code this app does not know stays allowed: it is
/// shown as "other allergy".
void _checkRuleRow(Object? row) {
  final r = _object(row, 'rule');
  switch (r['type']) {
    case 'allergy':
      if (r['allergen'] is! String) _bad('allergy rule allergen');
    case 'free_text':
      if (r['freeText'] is! String) _bad('free-text rule text');
      _checkMapping(r['mapping']);
    case 'medical_exclusion':
      final text = r['freeText'];
      if (text != null && text is! String) _bad('medical exclusion text');
      _checkMapping(r['mapping']);
  }
}

void _checkMapping(Object? json) {
  final m = _object(json, 'rule mapping');
  _list(m['ingredients'], 'rule mapping ingredients');
  if (m['status'] == 'mapped' &&
      m['confirmedBy'] != 'content_team' &&
      m['confirmedBy'] != 'manager') {
    _bad('mapped rule without a confirmer');
  }
}

/// Contract `ProfileRules`.
MemberRules decodeRules(Object? json) {
  final raw = _object(json, 'rules');
  final rawItems = _list(raw['items'], 'rules.items');
  rawItems.forEach(_checkRuleRow);
  final rawConsent = _object(raw['consent'], 'rules.consent');
  if (rawConsent['status'] is! String) _bad('rules.consent.status');

  final rules = required(api.ProfileRules.fromJson(raw), 'rules');
  if (rules.items.length != rawItems.length) _bad('rules.items row');
  final consent = rules.consent;
  final status = ConsentStatus.fromApi(consent.status);
  if (status == ConsentStatus.given) {
    return RulesSaved(items: rules.items, consent: consent);
  }
  // The contract keeps items empty unless consent is given. Rules next to a
  // consent that does not allow them contradict each other: fail closed.
  if (rules.items.isNotEmpty) _bad('rules without consent');
  return RulesNotSaved(
    status: status,
    decidedAt: consent.decidedAt,
    textVersion: consent.textVersion,
    deletionDueBy: consent.deletionDueBy,
  );
}

/// Contract `Profile`.
FamilyMember decodeProfile(Object? json) {
  final raw = _object(json, 'profile');
  final rules = decodeRules(raw['rules']);
  final p = required(api.Profile.fromJson(raw), 'profile');
  return FamilyMember(
    id: p.id,
    name: p.name,
    avatar: p.avatar,
    ageGroup: p.ageGroup,
    isChild: p.isChild,
    isManager: p.isManager,
    rules: rules,
    updatedAt: p.updatedAt,
    details: MemberDetails(
      guardianConfirmation: p.guardianConfirmation,
      portions: p.portions,
      preferences: p.preferences,
      likesDislikes: p.likesDislikes,
      createdAt: p.createdAt,
    ),
  );
}

/// Contract `ProfileList`. One bad profile fails the whole list.
FamilyProfiles decodeProfileList(Object? json) {
  final raw = _object(json, 'profile list');
  final rawItems = _list(raw['items'], 'profile list items');
  final maxProfiles = raw['maxProfiles'];
  if (maxProfiles is! int) _bad('maxProfiles');
  return FamilyProfiles(
    members: [for (final item in rawItems) decodeProfile(item)],
    maxProfiles: maxProfiles,
    source: const FromNetwork(),
  );
}

/// Contract `Household`.
HouseholdInfo decodeHousehold(Object? json) {
  final h = required(api.Household.fromJson(json), 'household');
  return HouseholdInfo(
    id: h.id,
    name: h.name,
    city: h.city,
    timeZoneName: h.timeZone,
    language: h.language,
    managerAccountId: h.managerAccountId,
    managerProfileId: h.managerProfileId,
    updatedAt: h.updatedAt,
    source: const FromNetwork(),
  );
}

/// Contract `StandardAllergenList`. Unknown codes are left out (the picker
/// shows only codes the app can label, contract-alignment.md 3).
AllergenReference decodeAllergens(Object? json) {
  final raw = _object(json, 'allergen list');
  _list(raw['items'], 'allergen items');
  final list = required(api.StandardAllergenList.fromJson(raw), 'allergens');
  return AllergenReference(
    ruleSetVersion: list.ruleSetVersion,
    items: list.items,
    source: const FromNetwork(),
  );
}

/// A generated model's `fromJson`, failing on null.
T Function(Object? json) decodeWith<T>(
  T? Function(dynamic json) fromJson,
  String what,
) =>
    (json) => required(fromJson(json), what);
