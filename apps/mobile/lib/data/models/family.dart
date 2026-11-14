// Keluarga Saya profiles as the app reads them (PRF-01, PRF-03, ACC-08).
//
// The generated `Profile` is decoded strictly and then turned into these
// types, so feature code cannot read hard rules without the consent state
// that allows them:
// - [RulesSaved]: consent `given`; `items` may be empty ("no food rules").
//   With [RulesSaved.renewalRequired] the stored rules still apply (Cek Aman
//   keeps checking them) but no new health data is saved until the manager
//   decides again on the matching text (QUESTIONS #62).
// - [RulesNotSaved]: consent `none`, `declined` or `withdrawn`. No rules;
//   the member gets the neutral chip, never "Aman" (contract-alignment.md 1).
// - [RulesNotLoaded]: the profile came from the on-device cache, which holds
//   no health data. Nothing about the member's rules is known.
// toString never prints names or rule contents (security review L2).
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

  api.RulesConsentStatus toApi() => switch (this) {
    none => api.RulesConsentStatus.none,
    given => api.RulesConsentStatus.given,
    declined => api.RulesConsentStatus.declined,
    withdrawn => api.RulesConsentStatus.withdrawn,
  };
}

/// The member's health-data consent as the manager was shown it, from a
/// fresh API read (never from the cache, which holds no consent state).
///
/// Consent writes send it as `expectedConsent` (contract 0.1.2, security
/// review T-019 M1). If the server's state has moved since, the write fails
/// with `ConsentChangedFailure`; the screen then reloads the member and asks
/// again with the new snapshot.
@immutable
final class ConsentSnapshot {
  const ConsentSnapshot._(this.status, this.consentRecordId);

  final ConsentStatus status;

  /// The latest health-data consent record, null for [ConsentStatus.none].
  final String? consentRecordId;

  api.ExpectedConsentState toApi() => api.ExpectedConsentState(
    status: status.toApi(),
    consentRecordId: consentRecordId,
  );

  @override
  bool operator ==(Object other) =>
      other is ConsentSnapshot &&
      other.status == status &&
      other.consentRecordId == consentRecordId;

  @override
  int get hashCode => Object.hash(status, consentRecordId);

  @override
  String toString() => 'ConsentSnapshot(${status.name})';
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

  /// The consent state to send as the precondition of a consent decision or
  /// withdrawal. Null when the rules were not loaded from the API: consent
  /// writes are online only and need the state the manager was shown.
  ConsentSnapshot? get consentSnapshot;

  /// Whether new health data (a new hard rule) may be saved for this member
  /// now. False without a given consent, and while a renewal is required.
  /// This gates writes only: it never hides stored rules or changes what
  /// Cek Aman checks.
  bool get allowsNewHealthData => switch (this) {
    RulesSaved(:final renewalRequired) => !renewalRequired,
    RulesNotSaved() || RulesNotLoaded() => false,
  };
}

/// Consent is given; [items] are the stored hard rules (possibly none).
final class RulesSaved extends MemberRules {
  const RulesSaved({required this.items, required this.consent});

  final List<api.HardRule> items;
  final api.RulesConsentState consent;

  bool get hasNoRules => items.isEmpty;

  /// The consent was given on the other audience's text (the member moved
  /// between adult and child, QUESTIONS #62). [items] stay and Cek Aman
  /// still applies them, but the manager must decide again before new
  /// health data is saved (the server answers `consent_required` until then).
  bool get renewalRequired => consent.renewalRequired;

  @override
  ConsentSnapshot get consentSnapshot =>
      ConsentSnapshot._(ConsentStatus.given, consent.consentRecordId);

  @override
  String toString() => renewalRequired
      ? 'RulesSaved(${items.length} rules, renewal required)'
      : 'RulesSaved(${items.length} rules)';
}

/// No rules are stored, because consent is not given.
final class RulesNotSaved extends MemberRules {
  const RulesNotSaved({
    required this.status,
    this.consentRecordId,
    this.decidedAt,
    this.textVersion,
    this.deletionDueBy,
  }) : assert(status != ConsentStatus.given);

  final ConsentStatus status;

  /// The latest health-data consent record, null for [ConsentStatus.none].
  final String? consentRecordId;
  final DateTime? decidedAt;
  final String? textVersion;

  /// For [ConsentStatus.withdrawn]: when stored rules will have been deleted.
  final DateTime? deletionDueBy;

  RulesChip get chip => status == ConsentStatus.none
      ? RulesChip.rulesNotSet
      : RulesChip.rulesNotSaved;

  @override
  ConsentSnapshot get consentSnapshot =>
      ConsentSnapshot._(status, consentRecordId);

  @override
  String toString() => 'RulesNotSaved(${status.name})';
}

/// Rules are not on the phone (cached profile). Treat as unknown.
final class RulesNotLoaded extends MemberRules {
  const RulesNotLoaded();

  @override
  ConsentSnapshot? get consentSnapshot => null;
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

  /// Which health-data consent text applies to this member (SET-10,
  /// QUESTIONS #62): the child text for an infant, child or teen profile.
  api.ConsentAudience get healthDataConsentAudience =>
      isChild ? api.ConsentAudience.child : api.ConsentAudience.adult;

  @override
  String toString() => 'FamilyMember($id, $rules)';
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

  @override
  String toString() => 'FamilyProfiles(${members.length} members)';
}
