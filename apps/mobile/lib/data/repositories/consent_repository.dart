// Health-data consent and consent texts (ACC-08, SET-03, SET-04, SET-10).
//
// Online only (contract 0.1.2): a consent decision or withdrawal is sent at
// once or not at all. It is never queued, stored or replayed offline: it
// needs the text version the manager saw and the consent state they were
// shown ([ConsentSnapshot]), and either can be stale by the time a queue
// would send it.
//
// A 409 `consent_changed` comes back as [ConsentChangedFailure]: the screen
// reloads the member and asks again. It never resends the same request.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../decoders.dart';
import '../models/family.dart';

final class ConsentRepository {
  ConsentRepository({required this._caller, required api.ApiClient client})
    : _api = api.ConsentApi(client);

  final ApiCaller _caller;
  final api.ConsentApi _api;

  /// The server text to show on the consent sheet (contract-alignment.md 7).
  ///
  /// For [api.ConsentPurpose.healthData] pass the member's
  /// [FamilyMember.healthDataConsentAudience]: a child profile needs the
  /// child text, and a decision on the other text is refused
  /// (`consent_text_outdated`). [audience] is ignored for the guardian
  /// confirmation.
  Future<ApiResult<api.ConsentText>> getConsentText(
    api.ConsentPurpose purpose,
    api.Language language, {
    api.ConsentAudience? audience,
  }) => _caller.call(
    'getConsentText',
    () =>
        _api.getConsentTextWithHttpInfo(purpose, language, audience: audience),
    decodeWith(api.ConsentText.fromJson, 'consent text'),
  );

  Future<ApiResult<api.ConsentRecordList>> listConsentRecords(
    String profileId,
  ) => _caller.call(
    'listConsentRecords',
    () => _api.listConsentRecordsWithHttpInfo(profileId),
    decodeWith(api.ConsentRecordList.fromJson, 'consent records'),
  );

  /// Records "given" or "declined" on [textVersion], shown in [language].
  ///
  /// [seen] is the member's consent as the manager was shown it, from the
  /// latest [MemberRules] the profiles or hard-rules repository returned
  /// ([MemberRules.consentSnapshot]). It is sent as `expectedConsent`.
  ///
  /// Reuse the same [idempotencyKey] only when resending after no answer
  /// (a network failure while online). After [ConsentChangedFailure], reload
  /// the member and ask again with a new key.
  Future<ApiResult<api.ConsentRecord>> recordHealthDataConsent(
    String profileId, {
    required api.ConsentDecision decision,
    required String textVersion,
    required api.Language language,
    required ConsentSnapshot seen,
    required String idempotencyKey,
  }) => _caller.call(
    'recordHealthDataConsent',
    () => _api.recordHealthDataConsentWithHttpInfo(
      profileId,
      api.HealthDataConsentDecision(
        decision: decision,
        textVersion: textVersion,
        language: language,
        expectedConsent: seen.toApi(),
      ),
      idempotencyKey: idempotencyKey,
    ),
    decodeWith(api.ConsentRecord.fromJson, 'consent record'),
  );

  /// Withdraws the member's current consent (SET-03, SET-04). [seen] is the
  /// state the manager was shown, as for [recordHealthDataConsent].
  Future<ApiResult<api.ConsentRecord>> withdrawHealthDataConsent(
    String profileId, {
    required ConsentSnapshot seen,
  }) => _caller.call(
    'withdrawHealthDataConsent',
    () => _api.withdrawHealthDataConsentWithHttpInfo(
      profileId,
      api.HealthDataConsentWithdrawal(expectedConsent: seen.toApi()),
    ),
    decodeWith(api.ConsentRecord.fromJson, 'consent record'),
  );
}

final consentRepositoryProvider = Provider<ConsentRepository>(
  (ref) => ConsentRepository(
    caller: ref.watch(apiCallerProvider),
    client: ref.watch(apiClientProvider),
  ),
);
