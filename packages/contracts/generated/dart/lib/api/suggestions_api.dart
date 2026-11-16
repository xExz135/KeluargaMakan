//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class SuggestionsApi {
  SuggestionsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Show three other suggestions for the same inputs
  ///
  /// \"Tampilkan 3 lainnya\" (SUG-11): the next page for the same inputs, never repeating an item shown earlier in the set. Asking for the same `page` again offers the same recipes, so a retry is safe, but every serve, a repeat of the same page included, runs Cek Aman again against the selected members' current rules and consent and the current versions, with a fresh `checkId` (SUG-04). A stored or cached result is never replayed. A changed result is allowed: an item that is now Not safe for an eater is replaced or dropped, and the others carry their new result. When the pool is used up `poolExhausted` is true. A set is kept for a configured time; after that the answer is 409 `suggestion_set_expired` and the client asks again with `requestSuggestions`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] suggestionSetId (required):
  ///   A suggestion set of the session's household.
  ///
  /// * [SuggestionMoreRequest] suggestionMoreRequest (required):
  Future<Response> requestMoreSuggestionsWithHttpInfo(String suggestionSetId, SuggestionMoreRequest suggestionMoreRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/suggestions/{suggestionSetId}/more'
      .replaceAll('{suggestionSetId}', suggestionSetId);

    // ignore: prefer_final_locals
    Object? postBody = suggestionMoreRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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

  /// Show three other suggestions for the same inputs
  ///
  /// \"Tampilkan 3 lainnya\" (SUG-11): the next page for the same inputs, never repeating an item shown earlier in the set. Asking for the same `page` again offers the same recipes, so a retry is safe, but every serve, a repeat of the same page included, runs Cek Aman again against the selected members' current rules and consent and the current versions, with a fresh `checkId` (SUG-04). A stored or cached result is never replayed. A changed result is allowed: an item that is now Not safe for an eater is replaced or dropped, and the others carry their new result. When the pool is used up `poolExhausted` is true. A set is kept for a configured time; after that the answer is 409 `suggestion_set_expired` and the client asks again with `requestSuggestions`.
  ///
  /// Parameters:
  ///
  /// * [String] suggestionSetId (required):
  ///   A suggestion set of the session's household.
  ///
  /// * [SuggestionMoreRequest] suggestionMoreRequest (required):
  Future<SuggestionSet?> requestMoreSuggestions(String suggestionSetId, SuggestionMoreRequest suggestionMoreRequest, { Future<void>? abortTrigger, }) async {
    final response = await requestMoreSuggestionsWithHttpInfo(suggestionSetId, suggestionMoreRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SuggestionSet',) as SuggestionSet;
    
    }
    return null;
  }

  /// Get three suggestions for who is eating, the meal and the time
  ///
  /// Masak Apa Hari Ini (SUG-01, SUG-02): up to three suggestions from the household's saved kitchen (sync queued changes first, KIT-16), the selected eaters (PRF-09, PRF-11), the meal type, the time available and the cuisine (Indonesian in V1, SUG-03). Ranking favors the most available and fewest missing ingredients (SUG-05), avoids recent dishes and repeated main proteins (SUG-07, window from configuration) and follows the eaters' likes, dislikes and feedback (SUG-08); every hard rule is met first, then soft preferences, with any trade-off in one line (PRF-12). Every suggestion passes Cek Aman for exactly the selected eaters before it is returned; one that is Not safe for any of them is replaced, not returned (SUG-04, SAF-02). An AI adaptation is made after the library pick and checked again (LIB-06, AI-01); with AI off or down the library recipes are used (AI-08, `aiAvailability`). `onlyWhatIHave` keeps recipes with zero missing ingredients (SUG-12). Fewer than three items means fewer passed. When none passes, `noSafeRecipe` says so and lists the closest checked options and the conflicts (SUG-17). Missing ingredients are a plain list to copy; there are no shopping lists (SUG-10). Answered within the SUG-13 target (5 s at p90, from configuration). 503 `rules_unavailable` or `reference_data_unavailable` when Cek Aman cannot run: no suggestion is ever returned without a completed result.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SuggestionRequest] suggestionRequest (required):
  Future<Response> requestSuggestionsWithHttpInfo(SuggestionRequest suggestionRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/suggestions';

    // ignore: prefer_final_locals
    Object? postBody = suggestionRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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

  /// Get three suggestions for who is eating, the meal and the time
  ///
  /// Masak Apa Hari Ini (SUG-01, SUG-02): up to three suggestions from the household's saved kitchen (sync queued changes first, KIT-16), the selected eaters (PRF-09, PRF-11), the meal type, the time available and the cuisine (Indonesian in V1, SUG-03). Ranking favors the most available and fewest missing ingredients (SUG-05), avoids recent dishes and repeated main proteins (SUG-07, window from configuration) and follows the eaters' likes, dislikes and feedback (SUG-08); every hard rule is met first, then soft preferences, with any trade-off in one line (PRF-12). Every suggestion passes Cek Aman for exactly the selected eaters before it is returned; one that is Not safe for any of them is replaced, not returned (SUG-04, SAF-02). An AI adaptation is made after the library pick and checked again (LIB-06, AI-01); with AI off or down the library recipes are used (AI-08, `aiAvailability`). `onlyWhatIHave` keeps recipes with zero missing ingredients (SUG-12). Fewer than three items means fewer passed. When none passes, `noSafeRecipe` says so and lists the closest checked options and the conflicts (SUG-17). Missing ingredients are a plain list to copy; there are no shopping lists (SUG-10). Answered within the SUG-13 target (5 s at p90, from configuration). 503 `rules_unavailable` or `reference_data_unavailable` when Cek Aman cannot run: no suggestion is ever returned without a completed result.
  ///
  /// Parameters:
  ///
  /// * [SuggestionRequest] suggestionRequest (required):
  Future<SuggestionSet?> requestSuggestions(SuggestionRequest suggestionRequest, { Future<void>? abortTrigger, }) async {
    final response = await requestSuggestionsWithHttpInfo(suggestionRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SuggestionSet',) as SuggestionSet;
    
    }
    return null;
  }
}
