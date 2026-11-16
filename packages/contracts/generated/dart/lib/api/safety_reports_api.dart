//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class SafetyReportsApi {
  SafetyReportsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Report a wrong Cek Aman result
  ///
  /// From the recipe screen (SAF-15). The report names the recipe, the check it is about (`checkId`), the members it concerns and what is wrong. The server takes the rule set and data versions, the result and the rule types from its own log of that check (SAF-14), never from the phone. A `checkId` of another household, or one past its retention, answers 404 `not_found`; a member who is not in the check answers 400. Only the members' rule types are kept, never their names, and the content team reviews the report in the admin queue. A report never changes a result on any phone. It may be queued offline, so `Idempotency-Key` is required; a replay returns the first receipt and does not count against the rate limit (429). The note is opt-in and short; the app shows the warning against personal details before the field. The raw note is never stored: the server redacts it with deterministic rules on arrival, never through the AI service, and keeps only the redacted copy.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] idempotencyKey (required):
  ///   As `IdempotencyKey`, but required: the request is queued offline and replayed, so every send carries a client-generated UUID.
  ///
  /// * [SafetyReportCreate] safetyReportCreate (required):
  Future<Response> createSafetyReportWithHttpInfo(String idempotencyKey, SafetyReportCreate safetyReportCreate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/safety-reports';

    // ignore: prefer_final_locals
    Object? postBody = safetyReportCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    headerParams[r'Idempotency-Key'] = parameterToString(idempotencyKey);

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

  /// Report a wrong Cek Aman result
  ///
  /// From the recipe screen (SAF-15). The report names the recipe, the check it is about (`checkId`), the members it concerns and what is wrong. The server takes the rule set and data versions, the result and the rule types from its own log of that check (SAF-14), never from the phone. A `checkId` of another household, or one past its retention, answers 404 `not_found`; a member who is not in the check answers 400. Only the members' rule types are kept, never their names, and the content team reviews the report in the admin queue. A report never changes a result on any phone. It may be queued offline, so `Idempotency-Key` is required; a replay returns the first receipt and does not count against the rate limit (429). The note is opt-in and short; the app shows the warning against personal details before the field. The raw note is never stored: the server redacts it with deterministic rules on arrival, never through the AI service, and keeps only the redacted copy.
  ///
  /// Parameters:
  ///
  /// * [String] idempotencyKey (required):
  ///   As `IdempotencyKey`, but required: the request is queued offline and replayed, so every send carries a client-generated UUID.
  ///
  /// * [SafetyReportCreate] safetyReportCreate (required):
  Future<SafetyReportReceipt?> createSafetyReport(String idempotencyKey, SafetyReportCreate safetyReportCreate, { Future<void>? abortTrigger, }) async {
    final response = await createSafetyReportWithHttpInfo(idempotencyKey, safetyReportCreate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SafetyReportReceipt',) as SafetyReportReceipt;
    
    }
    return null;
  }
}
