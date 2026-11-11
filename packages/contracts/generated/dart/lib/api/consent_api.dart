//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class ConsentApi {
  ConsentApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get the current consent text for a purpose
  ///
  /// Returns the current text and its version, which the client sends back when recording a decision (SET-03). Texts are served from content, not built into the app, so legal changes need no release. `isDraft` stays true until legal approval.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ConsentPurpose] purpose (required):
  ///
  /// * [Language] language (required):
  Future<Response> getConsentTextWithHttpInfo(ConsentPurpose purpose, Language language, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/consent-texts/{purpose}'
      .replaceAll('{purpose}', purpose.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'language', language));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Get the current consent text for a purpose
  ///
  /// Returns the current text and its version, which the client sends back when recording a decision (SET-03). Texts are served from content, not built into the app, so legal changes need no release. `isDraft` stays true until legal approval.
  ///
  /// Parameters:
  ///
  /// * [ConsentPurpose] purpose (required):
  ///
  /// * [Language] language (required):
  Future<ConsentText?> getConsentText(ConsentPurpose purpose, Language language, { Future<void>? abortTrigger, }) async {
    final response = await getConsentTextWithHttpInfo(purpose, language, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ConsentText',) as ConsentText;
    
    }
    return null;
  }

  /// List a member's consent records
  ///
  /// All consent records for the member, newest first, including withdrawn ones (SET-03).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<Response> listConsentRecordsWithHttpInfo(String profileId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/consents'
      .replaceAll('{profileId}', profileId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// List a member's consent records
  ///
  /// All consent records for the member, newest first, including withdrawn ones (SET-03).
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<ConsentRecordList?> listConsentRecords(String profileId, { Future<void>? abortTrigger, }) async {
    final response = await listConsentRecordsWithHttpInfo(profileId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ConsentRecordList',) as ConsentRecordList;
    
    }
    return null;
  }

  /// Record the manager's health-data consent decision for a member
  ///
  /// Records an explicit decision, given or declined, on storing the member's hard rules (ACC-08, SET-03). Nothing is pre-given. `textVersion` must be the current version from `getConsentText`, else 409 `consent_text_outdated`. For a child profile the guardian confirmation must be on record, else 409 `guardian_confirmation_required` (SET-10). A decline stores no rules; the member shows \"rules not saved\".
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [HealthDataConsentDecision] healthDataConsentDecision (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> recordHealthDataConsentWithHttpInfo(String profileId, HealthDataConsentDecision healthDataConsentDecision, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/consents/health-data'
      .replaceAll('{profileId}', profileId);

    // ignore: prefer_final_locals
    Object? postBody = healthDataConsentDecision;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (idempotencyKey != null) {
      headerParams[r'Idempotency-Key'] = parameterToString(idempotencyKey);
    }

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Record the manager's health-data consent decision for a member
  ///
  /// Records an explicit decision, given or declined, on storing the member's hard rules (ACC-08, SET-03). Nothing is pre-given. `textVersion` must be the current version from `getConsentText`, else 409 `consent_text_outdated`. For a child profile the guardian confirmation must be on record, else 409 `guardian_confirmation_required` (SET-10). A decline stores no rules; the member shows \"rules not saved\".
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [HealthDataConsentDecision] healthDataConsentDecision (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<ConsentRecord?> recordHealthDataConsent(String profileId, HealthDataConsentDecision healthDataConsentDecision, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await recordHealthDataConsentWithHttpInfo(profileId, healthDataConsentDecision, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ConsentRecord',) as ConsentRecord;
    
    }
    return null;
  }

  /// Withdraw a member's health-data consent
  ///
  /// Withdraws the current consent (SET-03). The member's hard rules stop being used at once and are deleted by `deletionDueBy`, set from the configured period (SET-04, 30 days target). Cek Aman no longer checks rules for this member, and clients show \"rules not saved\". Returns 409 `consent_not_active` when there is no current consent.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<Response> withdrawHealthDataConsentWithHttpInfo(String profileId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/consents/health-data/withdraw'
      .replaceAll('{profileId}', profileId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Withdraw a member's health-data consent
  ///
  /// Withdraws the current consent (SET-03). The member's hard rules stop being used at once and are deleted by `deletionDueBy`, set from the configured period (SET-04, 30 days target). Cek Aman no longer checks rules for this member, and clients show \"rules not saved\". Returns 409 `consent_not_active` when there is no current consent.
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<ConsentRecord?> withdrawHealthDataConsent(String profileId, { Future<void>? abortTrigger, }) async {
    final response = await withdrawHealthDataConsentWithHttpInfo(profileId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ConsentRecord',) as ConsentRecord;
    
    }
    return null;
  }
}
