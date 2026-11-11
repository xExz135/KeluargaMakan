//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class HouseholdApi {
  HouseholdApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create the household for the signed-in account
  ///
  /// Creates the household with the signed-in account as its only manager, and the manager's own profile (ACC-03, ACC-04). An account has at most one household; a second call returns 409 `household_exists`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [HouseholdCreate] householdCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> createHouseholdWithHttpInfo(HouseholdCreate householdCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household';

    // ignore: prefer_final_locals
    Object? postBody = householdCreate;

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

  /// Create the household for the signed-in account
  ///
  /// Creates the household with the signed-in account as its only manager, and the manager's own profile (ACC-03, ACC-04). An account has at most one household; a second call returns 409 `household_exists`.
  ///
  /// Parameters:
  ///
  /// * [HouseholdCreate] householdCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Household?> createHousehold(HouseholdCreate householdCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await createHouseholdWithHttpInfo(householdCreate, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Household',) as Household;
    
    }
    return null;
  }

  /// Get the household
  ///
  /// Returns 409 `household_required` when the account has no household yet.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getHouseholdWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household';

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

  /// Get the household
  ///
  /// Returns 409 `household_required` when the account has no household yet.
  Future<Household?> getHousehold({ Future<void>? abortTrigger, }) async {
    final response = await getHouseholdWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Household',) as Household;
    
    }
    return null;
  }

  /// Update household details
  ///
  /// Only the fields present are changed.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [HouseholdUpdate] householdUpdate (required):
  Future<Response> updateHouseholdWithHttpInfo(HouseholdUpdate householdUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household';

    // ignore: prefer_final_locals
    Object? postBody = householdUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Update household details
  ///
  /// Only the fields present are changed.
  ///
  /// Parameters:
  ///
  /// * [HouseholdUpdate] householdUpdate (required):
  Future<Household?> updateHousehold(HouseholdUpdate householdUpdate, { Future<void>? abortTrigger, }) async {
    final response = await updateHouseholdWithHttpInfo(householdUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Household',) as Household;
    
    }
    return null;
  }
}
