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
  /// From the recipe screen (SAF-15). The report names the recipe, the check it is about (`checkId`, with the rule set and data versions, SAF-14), the members it concerns and what is wrong. The server stores only the members' rule types from that check, never their names, and the content team reviews it in the admin queue. A report never changes a result on any phone. It may be queued offline: send an `Idempotency-Key`. The note is optional, short, and the app asks not to put personal details in it. Rate-limited (429).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SafetyReportCreate] safetyReportCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> createSafetyReportWithHttpInfo(SafetyReportCreate safetyReportCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/safety-reports';

    // ignore: prefer_final_locals
    Object? postBody = safetyReportCreate;

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

  /// Report a wrong Cek Aman result
  ///
  /// From the recipe screen (SAF-15). The report names the recipe, the check it is about (`checkId`, with the rule set and data versions, SAF-14), the members it concerns and what is wrong. The server stores only the members' rule types from that check, never their names, and the content team reviews it in the admin queue. A report never changes a result on any phone. It may be queued offline: send an `Idempotency-Key`. The note is optional, short, and the app asks not to put personal details in it. Rate-limited (429).
  ///
  /// Parameters:
  ///
  /// * [SafetyReportCreate] safetyReportCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<SafetyReportReceipt?> createSafetyReport(SafetyReportCreate safetyReportCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await createSafetyReportWithHttpInfo(safetyReportCreate, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
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
