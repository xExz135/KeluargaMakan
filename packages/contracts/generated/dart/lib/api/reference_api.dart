//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class ReferenceApi {
  ReferenceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get the whole reference ingredient catalog
  ///
  /// Every ingredient of the verified reference dataset with its names, local and regional names, kitchen category and brands, for the copy the phone keeps for offline search (KIT-04). `referenceVersion` changes whenever the data changes. When the dataset is not loaded or fails verification the answer is 503 `reference_data_unavailable`, never an empty catalog. No safety data (components, allergens, halal) is included: only Cek Aman uses those. The `ETag` identifies the dataset; a phone that sends it back in `If-None-Match` gets 304 with no body while its copy is current, so refreshing the copy is cheap.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] ifNoneMatch:
  ///   The `ETag` of the catalog the phone already has.
  Future<Response> listReferenceIngredientsWithHttpInfo({ String? ifNoneMatch, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/reference/ingredients';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (ifNoneMatch != null) {
      headerParams[r'If-None-Match'] = parameterToString(ifNoneMatch);
    }

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

  /// Get the whole reference ingredient catalog
  ///
  /// Every ingredient of the verified reference dataset with its names, local and regional names, kitchen category and brands, for the copy the phone keeps for offline search (KIT-04). `referenceVersion` changes whenever the data changes. When the dataset is not loaded or fails verification the answer is 503 `reference_data_unavailable`, never an empty catalog. No safety data (components, allergens, halal) is included: only Cek Aman uses those. The `ETag` identifies the dataset; a phone that sends it back in `If-None-Match` gets 304 with no body while its copy is current, so refreshing the copy is cheap.
  ///
  /// Parameters:
  ///
  /// * [String] ifNoneMatch:
  ///   The `ETag` of the catalog the phone already has.
  Future<ReferenceIngredientCatalog?> listReferenceIngredients({ String? ifNoneMatch, Future<void>? abortTrigger, }) async {
    final response = await listReferenceIngredientsWithHttpInfo(ifNoneMatch: ifNoneMatch, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ReferenceIngredientCatalog',) as ReferenceIngredientCatalog;
    
    }
    return null;
  }

  /// List the standard allergen list
  ///
  /// The PRF-04 standard allergen list in display order, from the Cek Aman rule-set vocabulary. Clients show localized labels for each code.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listStandardAllergensWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/reference/allergens';

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

  /// List the standard allergen list
  ///
  /// The PRF-04 standard allergen list in display order, from the Cek Aman rule-set vocabulary. Clients show localized labels for each code.
  Future<StandardAllergenList?> listStandardAllergens({ Future<void>? abortTrigger, }) async {
    final response = await listStandardAllergensWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'StandardAllergenList',) as StandardAllergenList;
    
    }
    return null;
  }

  /// Search the reference ingredients by name or local name
  ///
  /// Searches the standard Indonesian ingredient list by name (Indonesian or English) and by local or regional name, for example kemangi, daun salam, tempe or kecap manis (KIT-04). Matching ignores case, accents and spacing (Unicode NFKC); exact and starting matches come first. The same search picks ingredients for likes and dislikes (PRF-06) and for a rule mapping (PRF-08; QUESTIONS #49). The query is sent in the body so it never appears in a URL or an access log. An empty `items` means no ingredient matched; when the reference dataset is not loaded or fails verification the answer is 503 `reference_data_unavailable`, never an empty list.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [IngredientSearchRequest] ingredientSearchRequest (required):
  Future<Response> searchReferenceIngredientsWithHttpInfo(IngredientSearchRequest ingredientSearchRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/reference/ingredients/search';

    // ignore: prefer_final_locals
    Object? postBody = ingredientSearchRequest;

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

  /// Search the reference ingredients by name or local name
  ///
  /// Searches the standard Indonesian ingredient list by name (Indonesian or English) and by local or regional name, for example kemangi, daun salam, tempe or kecap manis (KIT-04). Matching ignores case, accents and spacing (Unicode NFKC); exact and starting matches come first. The same search picks ingredients for likes and dislikes (PRF-06) and for a rule mapping (PRF-08; QUESTIONS #49). The query is sent in the body so it never appears in a URL or an access log. An empty `items` means no ingredient matched; when the reference dataset is not loaded or fails verification the answer is 503 `reference_data_unavailable`, never an empty list.
  ///
  /// Parameters:
  ///
  /// * [IngredientSearchRequest] ingredientSearchRequest (required):
  Future<IngredientSearchResult?> searchReferenceIngredients(IngredientSearchRequest ingredientSearchRequest, { Future<void>? abortTrigger, }) async {
    final response = await searchReferenceIngredientsWithHttpInfo(ingredientSearchRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientSearchResult',) as IngredientSearchResult;
    
    }
    return null;
  }
}
