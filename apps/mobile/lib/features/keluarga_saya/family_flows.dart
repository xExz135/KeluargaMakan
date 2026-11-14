// Flows shared by the Keluarga Saya screens: consent before health data,
// then the rules (ACC-08, SET-03, PRF-03, PRF-04, PRF-08; flow.md 1).
//
// Order is fixed: the consent decision is recorded first, and only after
// "given" are the picked rules sent, one `createHardRule` each. A rule is
// shown as saved only once the server confirmed it. Nothing is queued
// offline: rules and consent are online only (family.rules.offline).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../data/family_profiles_state.dart';
import '../../data/models/family.dart';
import '../../data/models/household.dart';
import '../../data/repositories/auth_repository.dart' show randomUuidV4;
import '../../data/repositories/hard_rules_repository.dart';
import '../../data/repositories/reference_repository.dart';
import 'consent_sheet.dart';
import 'rule_draft.dart';

/// The standard allergen list (PRF-04), in the API's order. Public reference
/// data; it is rebuilt with the account anyway so nothing outlives a
/// session (security review T-027 M1).
final standardAllergensProvider =
    FutureProvider.autoDispose<ApiResult<AllergenReference>>((ref) {
      ref.watch(currentAccountIdProvider);
      return ref.read(referenceRepositoryProvider).listStandardAllergens();
    });

/// What happened to a set of picked rules.
@immutable
final class RulesSaveResult {
  const RulesSaveResult({
    required this.consent,
    this.saved = 0,
    this.duplicates = 0,
    this.failed = const [],
    this.offline = false,
  });

  /// [ConsentOutcome.given] when consent was already given or was given now.
  final ConsentOutcome consent;
  final int saved;

  /// Rules the member already had (`hard_rule_duplicate`): treated as saved.
  final int duplicates;

  /// Rules not saved; they stay picked so the manager can try again.
  final List<RuleDraft> failed;

  /// No answer from the API.
  final bool offline;

  bool get complete =>
      consent == ConsentOutcome.given && failed.isEmpty && !offline;
}

/// Asks consent when the member's state does not allow new health data, then
/// saves [drafts]. [keys] holds one Idempotency-Key per draft, kept by the
/// caller across retries of the same rule.
Future<RulesSaveResult> saveRulesWithConsent(
  BuildContext context,
  WidgetRef ref, {
  required String profileId,
  required List<RuleDraft> drafts,
  required Map<RuleDraft, String> keys,
  ValueChanged<bool>? onConsentSheet,
}) async {
  final family = ref.read(familyProfilesProvider.notifier);
  // The rules belong to this account. If the screen closes or the session
  // ends or changes while saving, nothing more is sent (security review
  // T-028 L1).
  final account = ref.read(currentAccountIdProvider);
  bool gone() =>
      !context.mounted || ref.read(currentAccountIdProvider) != account;
  var member = memberIn(ref.read(familyProfilesProvider), profileId);
  if (member == null || member.rules is RulesNotLoaded) {
    return const RulesSaveResult(
      consent: ConsentOutcome.notRecorded,
      offline: true,
    );
  }

  Future<ConsentOutcome> askConsent() async {
    final rules = member!.rules;
    onConsentSheet?.call(true);
    try {
      return await showMemberConsentSheet(
        context,
        profileId: profileId,
        rules: drafts,
        renewal: rules is RulesSaved && rules.renewalRequired,
      );
    } finally {
      onConsentSheet?.call(false);
    }
  }

  if (!member.rules.allowsNewHealthData) {
    final outcome = await askConsent();
    if (outcome != ConsentOutcome.given) {
      return RulesSaveResult(consent: outcome);
    }
    if (gone()) {
      return RulesSaveResult(consent: outcome, failed: [...drafts]);
    }
  }

  final repo = ref.read(hardRulesRepositoryProvider);
  var saved = 0;
  var duplicates = 0;
  var offline = false;
  var askedAgain = false;
  final failed = <RuleDraft>[];
  final queue = [...drafts];
  var stopped = false;
  while (queue.isNotEmpty) {
    if (gone()) {
      stopped = true;
      failed.addAll(queue);
      queue.clear();
      break;
    }
    final draft = queue.removeAt(0);
    final key = keys.putIfAbsent(draft, randomUuidV4);
    final result = await repo.createHardRule(
      profileId,
      draft.toApi(),
      idempotencyKey: key,
    );
    switch (result) {
      case Ok():
        saved++;
        keys.remove(draft);
      case Err(:final failure)
          when failure.problemCode == ApiErrorCode.hardRuleDuplicate:
        duplicates++;
        keys.remove(draft);
      case Err(:final failure)
          when failure.problemCode == ApiErrorCode.consentRequired &&
              !askedAgain &&
              context.mounted:
        // Consent changed meanwhile (withdrawn on another phone, or a
        // renewal is due): ask once, then retry this rule and the rest.
        askedAgain = true;
        await family.refresh();
        member = memberIn(ref.read(familyProfilesProvider), profileId);
        if (member == null || !context.mounted) {
          failed
            ..add(draft)
            ..addAll(queue);
          queue.clear();
          break;
        }
        final outcome = await askConsent();
        if (outcome != ConsentOutcome.given || gone()) {
          failed
            ..add(draft)
            ..addAll(queue);
          queue.clear();
          break;
        }
        queue.insert(0, draft);
      case Err(failure: NetworkFailure()):
        offline = true;
        failed.add(draft);
      case Err():
        failed.add(draft);
    }
  }
  // After a session change the family state is already another account's.
  if (!stopped && !gone()) await family.refresh();
  return RulesSaveResult(
    consent: ConsentOutcome.given,
    saved: saved,
    duplicates: duplicates,
    failed: failed,
    offline: offline,
  );
}

/// Saved rules as drafts, for the consent summary when the manager decides
/// again on the stored rules (renewal, QUESTIONS #62). Never sent.
List<RuleDraft> draftsOf(List<api.HardRule> rules) => [
  for (final rule in rules)
    switch (rule.type) {
      api.HardRuleType.allergy when rule.allergen != null => RuleDraft.allergy(
        rule.allergen!,
      ),
      api.HardRuleType.freeText || api.HardRuleType.medicalExclusion
          when rule.freeText != null =>
        RuleDraft.written(
          rule.freeText!,
          medical: rule.type == api.HardRuleType.medicalExclusion,
        ),
      api.HardRuleType.halal ||
      api.HardRuleType.vegetarian ||
      api.HardRuleType.vegan => RuleDraft.diet(rule.type),
      _ => null,
    },
].nonNulls.toList();
