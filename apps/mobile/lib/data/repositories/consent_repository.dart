// Health-data consent and consent texts (ACC-08, SET-03, SET-04, SET-10).
// Online only: a consent decision needs the text version the user saw.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../decoders.dart';

final class ConsentRepository {
  ConsentRepository({required this._caller, required api.ApiClient client})
    : _api = api.ConsentApi(client);

  final ApiCaller _caller;
  final api.ConsentApi _api;

  /// The server text to show on the consent sheet (contract-alignment.md 7).
  Future<ApiResult<api.ConsentText>> getConsentText(
    api.ConsentPurpose purpose,
    api.Language language,
  ) => _caller.call(
    'getConsentText',
    () => _api.getConsentTextWithHttpInfo(purpose, language),
    decodeWith(api.ConsentText.fromJson, 'consent text'),
  );

  Future<ApiResult<api.ConsentRecordList>> listConsentRecords(
    String profileId,
  ) => _caller.call(
    'listConsentRecords',
    () => _api.listConsentRecordsWithHttpInfo(profileId),
    decodeWith(api.ConsentRecordList.fromJson, 'consent records'),
  );

  /// Records "given" or "declined" with the text version shown. Reuse the
  /// same [idempotencyKey] when retrying.
  Future<ApiResult<api.ConsentRecord>> recordHealthDataConsent(
    String profileId,
    api.HealthDataConsentDecision decision, {
    required String idempotencyKey,
  }) => _caller.call(
    'recordHealthDataConsent',
    () => _api.recordHealthDataConsentWithHttpInfo(
      profileId,
      decision,
      idempotencyKey: idempotencyKey,
    ),
    decodeWith(api.ConsentRecord.fromJson, 'consent record'),
  );

  Future<ApiResult<api.ConsentRecord>> withdrawHealthDataConsent(
    String profileId,
  ) => _caller.call(
    'withdrawHealthDataConsent',
    () => _api.withdrawHealthDataConsentWithHttpInfo(profileId),
    decodeWith(api.ConsentRecord.fromJson, 'consent record'),
  );
}

final consentRepositoryProvider = Provider<ConsentRepository>(
  (ref) => ConsentRepository(
    caller: ref.watch(apiCallerProvider),
    client: ref.watch(apiClientProvider),
  ),
);
