//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class HardRulesApi {
  HardRulesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Confirm which ingredients a free-text rule means
  ///
  /// The manager confirms a mapping, either accepting a content-team proposal or choosing ingredients from the catalog (PRF-08). The rule becomes `mapped` with `confirmedBy: manager`, and affected safety results are re-evaluated. Only `free_text` and `medical_exclusion` rules have a mapping; other types return 409 `mapping_not_applicable`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [String] ruleId (required):
  ///
  /// * [HardRuleMappingConfirmation] hardRuleMappingConfirmation (required):
  Future<Response> confirmHardRuleMappingWithHttpInfo(String profileId, String ruleId, HardRuleMappingConfirmation hardRuleMappingConfirmation, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/hard-rules/{ruleId}/mapping'
      .replaceAll('{profileId}', profileId)
      .replaceAll('{ruleId}', ruleId);

    // ignore: prefer_final_locals
    Object? postBody = hardRuleMappingConfirmation;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Confirm which ingredients a free-text rule means
  ///
  /// The manager confirms a mapping, either accepting a content-team proposal or choosing ingredients from the catalog (PRF-08). The rule becomes `mapped` with `confirmedBy: manager`, and affected safety results are re-evaluated. Only `free_text` and `medical_exclusion` rules have a mapping; other types return 409 `mapping_not_applicable`.
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [String] ruleId (required):
  ///
  /// * [HardRuleMappingConfirmation] hardRuleMappingConfirmation (required):
  Future<HardRule?> confirmHardRuleMapping(String profileId, String ruleId, HardRuleMappingConfirmation hardRuleMappingConfirmation, { Future<void>? abortTrigger, }) async {
    final response = await confirmHardRuleMappingWithHttpInfo(profileId, ruleId, hardRuleMappingConfirmation, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'HardRule',) as HardRule;
    
    }
    return null;
  }

  /// Add a hard rule
  ///
  /// Adds an allergy from the standard list, halal, vegetarian, vegan, a medical exclusion or a free-text rule (PRF-03, PRF-04). Needs a current health-data consent for the member, else 409 `consent_required` (ACC-08); for a child the guardian confirmation must also be on record (SET-10). Free-text and medical-exclusion rules are saved as unmapped unless the manager picked matching ingredients (`mappedIngredientIds`). An unmapped rule makes Cek Aman return \"Check the label\" for related recipes, never \"Safe\" (PRF-08, SAF-09). Online only: the server re-evaluates affected safety results.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [HardRuleCreate] hardRuleCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> createHardRuleWithHttpInfo(String profileId, HardRuleCreate hardRuleCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/hard-rules'
      .replaceAll('{profileId}', profileId);

    // ignore: prefer_final_locals
    Object? postBody = hardRuleCreate;

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

  /// Add a hard rule
  ///
  /// Adds an allergy from the standard list, halal, vegetarian, vegan, a medical exclusion or a free-text rule (PRF-03, PRF-04). Needs a current health-data consent for the member, else 409 `consent_required` (ACC-08); for a child the guardian confirmation must also be on record (SET-10). Free-text and medical-exclusion rules are saved as unmapped unless the manager picked matching ingredients (`mappedIngredientIds`). An unmapped rule makes Cek Aman return \"Check the label\" for related recipes, never \"Safe\" (PRF-08, SAF-09). Online only: the server re-evaluates affected safety results.
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [HardRuleCreate] hardRuleCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<HardRule?> createHardRule(String profileId, HardRuleCreate hardRuleCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await createHardRuleWithHttpInfo(profileId, hardRuleCreate, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'HardRule',) as HardRule;
    
    }
    return null;
  }

  /// Remove a hard rule
  ///
  /// The manager removes a rule from their family's data. This is an edit of the profile, not an override of a safety result: there is no way to override a \"Not safe\" result while a rule is active (SAF-12).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [String] ruleId (required):
  Future<Response> deleteHardRuleWithHttpInfo(String profileId, String ruleId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/hard-rules/{ruleId}'
      .replaceAll('{profileId}', profileId)
      .replaceAll('{ruleId}', ruleId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Remove a hard rule
  ///
  /// The manager removes a rule from their family's data. This is an edit of the profile, not an override of a safety result: there is no way to override a \"Not safe\" result while a rule is active (SAF-12).
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [String] ruleId (required):
  Future<void> deleteHardRule(String profileId, String ruleId, { Future<void>? abortTrigger, }) async {
    final response = await deleteHardRuleWithHttpInfo(profileId, ruleId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// List a profile's hard rules and consent state
  ///
  /// Returns the member's hard rules and the consent state that decides whether rules can be stored. With no current consent there are no rules, and clients show \"rules not saved\" for the member, never \"Safe\" (DECISIONS 2026-11-10). If the rules cannot be read or decrypted the server returns 503 `rules_unavailable`, never an empty list (QUESTIONS #39).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<Response> listHardRulesWithHttpInfo(String profileId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/hard-rules'
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

  /// List a profile's hard rules and consent state
  ///
  /// Returns the member's hard rules and the consent state that decides whether rules can be stored. With no current consent there are no rules, and clients show \"rules not saved\" for the member, never \"Safe\" (DECISIONS 2026-11-10). If the rules cannot be read or decrypted the server returns 503 `rules_unavailable`, never an empty list (QUESTIONS #39).
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<ProfileRules?> listHardRules(String profileId, { Future<void>? abortTrigger, }) async {
    final response = await listHardRulesWithHttpInfo(profileId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ProfileRules',) as ProfileRules;
    
    }
    return null;
  }

  /// Reject or clear a free-text rule mapping
  ///
  /// \"Bukan ini\": the rule returns to `unmapped` and goes back to the content team's anonymized queue (no names). Until it is mapped again, related recipes get \"Check the label\" (PRF-08, SAF-09). Other rule types return 409 `mapping_not_applicable`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [String] ruleId (required):
  Future<Response> rejectHardRuleMappingWithHttpInfo(String profileId, String ruleId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/hard-rules/{ruleId}/mapping'
      .replaceAll('{profileId}', profileId)
      .replaceAll('{ruleId}', ruleId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Reject or clear a free-text rule mapping
  ///
  /// \"Bukan ini\": the rule returns to `unmapped` and goes back to the content team's anonymized queue (no names). Until it is mapped again, related recipes get \"Check the label\" (PRF-08, SAF-09). Other rule types return 409 `mapping_not_applicable`.
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [String] ruleId (required):
  Future<HardRule?> rejectHardRuleMapping(String profileId, String ruleId, { Future<void>? abortTrigger, }) async {
    final response = await rejectHardRuleMappingWithHttpInfo(profileId, ruleId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'HardRule',) as HardRule;
    
    }
    return null;
  }
}
