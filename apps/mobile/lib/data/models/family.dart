// Keluarga Saya profiles as the app reads them (PRF-01, PRF-03, ACC-08).
//
// The generated `Profile` is decoded strictly and then turned into these
// types, so feature code cannot read hard rules without the consent state
// that allows them:
// - [RulesSaved]: consent `given`; `items` may be empty ("no food rules").
// - [RulesNotSaved]: consent `none`, `declined` or `withdrawn`. No rules;
//   the member gets the neutral chip, never "Aman" (contract-alignment.md 1).
// - [RulesNotLoaded]: the profile came from the on-device cache, which holds
//   no health data. Nothing about the member's rules is known.
// None of these is a safety result. Only Cek Aman results from the API (or
// their cache, T-058) decide what is safe.

import 'package:flutter/foundation.dart';
import 'package:keluargamakan_api/api.dart' as api;

import 'sourced.dart';

/// Health-data consent for a member's hard rules (contract
/// `RulesConsentStatus`). An unknown server value fails decoding, so it never
/// reaches the app as a permissive state.
enum ConsentStatus {
  none,
  given,
  declined,
  withdrawn;

  static ConsentStatus fromApi(api.RulesConsentStatus status) =>
      switch (status) {
        api.RulesConsentStatus.none => none,
        api.RulesConsentStatus.given => given,
        api.RulesConsentStatus.declined => declined,
        api.RulesConsentStatus.withdrawn => withdrawn,
      };
}

/// The neutral, non-safety chips shown instead of a badge
/// (contract-alignment.md 1; copy deck 24.3).
enum RulesChip {
  /// Consent `none`: `safety.badge.rulesNotSet`.
  rulesNotSet,

  /// Consent `declined` or `withdrawn`: `safety.badge.rulesNotSaved`.
  rulesNotSaved,
}

@immutable
sealed class MemberRules {
  const MemberRules();

  /// Whether Cek Aman can check this member at all. This is not "safe": a
  /// member is shown as safe only from a Cek Aman result.
  bool get checkedByCekAman => this is RulesSaved;
}

/// Consent is given; [items] are the stored hard rules (possibly none).
final class RulesSaved extends MemberRules {
  const RulesSaved({required this.items, required this.consent});

  final List<api.HardRule> items;
  final api.RulesConsentState consent;

  bool get hasNoRules => items.isEmpty;
}

/// No rules are stored, because consent is not given.
final class RulesNotSaved extends MemberRules {
  const RulesNotSaved({
    required this.status,
    this.decidedAt,
    this.textVersion,
    this.deletionDueBy,
  }) : assert(status != ConsentStatus.given);

  final ConsentStatus status;
  final DateTime? decidedAt;
  final String? textVersion;

  /// For [ConsentStatus.withdrawn]: when stored rules will have been deleted.
  final DateTime? deletionDueBy;

  RulesChip get chip => status == ConsentStatus.none
      ? RulesChip.rulesNotSet
      : RulesChip.rulesNotSaved;
}

/// Rules are not on the phone (cached profile). Treat as unknown.
final class RulesNotLoaded extends MemberRules {
  const RulesNotLoaded();
}

/// Profile details that only come fresh from the API.
@immutable
final class MemberDetails {
  const MemberDetails({
    required this.guardianConfirmation,
    required this.portions,
    required this.preferences,
    required this.likesDislikes,
    required this.createdAt,
  });

  final api.GuardianConfirmation? guardianConfirmation;
  final api.Portions portions;
  final api.SoftPreferences preferences;
  final api.LikesDislikes likesDislikes;
  final DateTime createdAt;
}

@immutable
final class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.avatar,
    required this.ageGroup,
    required this.isChild,
    required this.isManager,
    required this.rules,
    required this.updatedAt,
    this.details,
  });

  final String id;
  final String name;
  final api.Avatar avatar;
  final api.AgeGroup ageGroup;
  final bool isChild;
  final bool isManager;
  final MemberRules rules;
  final DateTime updatedAt;

  /// Null for a cached profile.
  final MemberDetails? details;
}

@immutable
final class FamilyProfiles {
  const FamilyProfiles({
    required this.members,
    required this.maxProfiles,
    required this.source,
  });

  /// Manager first, in the API's order.
  final List<FamilyMember> members;

  /// The configured limit (PRF-02), or null when read from the cache.
  final int? maxProfiles;
  final DataSource source;
}
