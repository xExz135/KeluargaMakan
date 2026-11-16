//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class LibraryApi {
  LibraryApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get a library recipe image
  ///
  /// The image bytes of a published recipe image (LIB-03, SUG-09). Recipe images are food photos from the content team, never photos of people. An image ID never changes its bytes, but an image can be withdrawn: the phone checks again with `If-None-Match` before each use (304 while it is current), a withdrawn or retired image answers 404, and the phone drops cached images that the current `libraryVersion` no longer uses. No JSON schema in this contract carries an image, a URL or a link.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] imageId (required):
  ///   A library recipe image.
  ///
  /// * [String] ifNoneMatch:
  ///   The `ETag` of the copy the client already has. The server checks authentication first and answers 304 only when this equals the current `ETag`. The client accepts a 304 only for a request in which it sent the `ETag` it has stored, and treats any other 304 as an error (it keeps checking cached results as stale).
  Future<Response> getLibraryImageWithHttpInfo(String imageId, { String? ifNoneMatch, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/library/images/{imageId}'
      .replaceAll('{imageId}', imageId);

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

  /// Get a library recipe image
  ///
  /// The image bytes of a published recipe image (LIB-03, SUG-09). Recipe images are food photos from the content team, never photos of people. An image ID never changes its bytes, but an image can be withdrawn: the phone checks again with `If-None-Match` before each use (304 while it is current), a withdrawn or retired image answers 404, and the phone drops cached images that the current `libraryVersion` no longer uses. No JSON schema in this contract carries an image, a URL or a link.
  ///
  /// Parameters:
  ///
  /// * [String] imageId (required):
  ///   A library recipe image.
  ///
  /// * [String] ifNoneMatch:
  ///   The `ETag` of the copy the client already has. The server checks authentication first and answers 304 only when this equals the current `ETag`. The client accepts a 304 only for a request in which it sent the `ETag` it has stored, and treats any other 304 as an error (it keeps checking cached results as stale).
  Future<MultipartFile?> getLibraryImage(String imageId, { String? ifNoneMatch, Future<void>? abortTrigger, }) async {
    final response = await getLibraryImageWithHttpInfo(imageId, ifNoneMatch: ifNoneMatch, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MultipartFile',) as MultipartFile;
    
    }
    return null;
  }

  /// Open a recipe for the selected eaters
  ///
  /// The recipe screen (CKM-01): ingredients with what is in the kitchen and what is missing, steps with timers, time, servings scaled to the eaters' portions (SUG-16), the halal status from Cek Aman's ingredient data (LIB-05) and the per-member Cek Aman result for exactly the selected eaters (SAF-02, SAF-04, SAF-05, PRF-11). It is a POST because the request names who is eating and every check is logged with its rule set and data versions (SAF-14); it changes no household data. The recipe is returned whatever its result, so the manager can see why it is Not safe; there is no way to override that result (SAF-12). `adaptationId` opens the adapted version a suggestion returned (LIB-06); the server keeps it for a configured time, then answers 409 `adaptation_expired` and the client opens the library recipe instead. `substitutionIds` and `variantId` apply checked substitutions and variants (SAF-11, CKM-09): the whole recipe is checked again with them, and one that is not offered for these eaters answers 409 `substitution_not_available`. A recipe that is not published (or retired) answers 404 `not_found`. 503 `rules_unavailable` or `reference_data_unavailable` when Cek Aman cannot run; the recipe is never returned without a result. With every AI service down the library recipe, its result and content-team substitutions still work (AI-08).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] recipeId (required):
  ///   A library recipe (stable across its versions).
  ///
  /// * [RecipeDetailRequest] recipeDetailRequest (required):
  Future<Response> getRecipeDetailWithHttpInfo(String recipeId, RecipeDetailRequest recipeDetailRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/library/recipes/{recipeId}/detail'
      .replaceAll('{recipeId}', recipeId);

    // ignore: prefer_final_locals
    Object? postBody = recipeDetailRequest;

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

  /// Open a recipe for the selected eaters
  ///
  /// The recipe screen (CKM-01): ingredients with what is in the kitchen and what is missing, steps with timers, time, servings scaled to the eaters' portions (SUG-16), the halal status from Cek Aman's ingredient data (LIB-05) and the per-member Cek Aman result for exactly the selected eaters (SAF-02, SAF-04, SAF-05, PRF-11). It is a POST because the request names who is eating and every check is logged with its rule set and data versions (SAF-14); it changes no household data. The recipe is returned whatever its result, so the manager can see why it is Not safe; there is no way to override that result (SAF-12). `adaptationId` opens the adapted version a suggestion returned (LIB-06); the server keeps it for a configured time, then answers 409 `adaptation_expired` and the client opens the library recipe instead. `substitutionIds` and `variantId` apply checked substitutions and variants (SAF-11, CKM-09): the whole recipe is checked again with them, and one that is not offered for these eaters answers 409 `substitution_not_available`. A recipe that is not published (or retired) answers 404 `not_found`. 503 `rules_unavailable` or `reference_data_unavailable` when Cek Aman cannot run; the recipe is never returned without a result. With every AI service down the library recipe, its result and content-team substitutions still work (AI-08).
  ///
  /// Parameters:
  ///
  /// * [String] recipeId (required):
  ///   A library recipe (stable across its versions).
  ///
  /// * [RecipeDetailRequest] recipeDetailRequest (required):
  Future<RecipeDetail?> getRecipeDetail(String recipeId, RecipeDetailRequest recipeDetailRequest, { Future<void>? abortTrigger, }) async {
    final response = await getRecipeDetailWithHttpInfo(recipeId, recipeDetailRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecipeDetail',) as RecipeDetail;
    
    }
    return null;
  }

  /// List the regions the library filters by
  ///
  /// The regions published recipes come from, with their display names from the content team, for the region filter (LIB-08) and regional variants (LIB-04). Content data, not a fixed list in the app.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listLibraryRegionsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/library/regions';

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

  /// List the regions the library filters by
  ///
  /// The regions published recipes come from, with their display names from the content team, for the region filter (LIB-08) and regional variants (LIB-04). Content data, not a fixed list in the app.
  Future<LibraryRegionList?> listLibraryRegions({ Future<void>? abortTrigger, }) async {
    final response = await listLibraryRegionsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LibraryRegionList',) as LibraryRegionList;
    
    }
    return null;
  }

  /// List checked substitutions and variants for the selected eaters
  ///
  /// Ingredient substitutions (CKM-09) and content-team variants such as \"serve Kakak's portion before adding terasi\" (SAF-11), each with its own Cek Aman result for exactly the selected eaters (SAF-02, AI-01). An option that would be Not safe for any selected member, or that could not be checked, is never listed; it is counted in `hiddenCount`. Where the content team defined none, none is offered. Options suggested by AI are only listed when AI is available and pass the same check; with AI down the content-team options still work (AI-08). Each option also carries `recipeSafetyWith`, the whole recipe checked with that one option applied. Using options re-checks the whole recipe with all of them through `getRecipeDetail`. 409 `adaptation_expired`, 404 `not_found` and the 503 codes as for `getRecipeDetail`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] recipeId (required):
  ///   A library recipe (stable across its versions).
  ///
  /// * [SubstitutionRequest] substitutionRequest (required):
  Future<Response> listRecipeSubstitutionsWithHttpInfo(String recipeId, SubstitutionRequest substitutionRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/library/recipes/{recipeId}/substitutions'
      .replaceAll('{recipeId}', recipeId);

    // ignore: prefer_final_locals
    Object? postBody = substitutionRequest;

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

  /// List checked substitutions and variants for the selected eaters
  ///
  /// Ingredient substitutions (CKM-09) and content-team variants such as \"serve Kakak's portion before adding terasi\" (SAF-11), each with its own Cek Aman result for exactly the selected eaters (SAF-02, AI-01). An option that would be Not safe for any selected member, or that could not be checked, is never listed; it is counted in `hiddenCount`. Where the content team defined none, none is offered. Options suggested by AI are only listed when AI is available and pass the same check; with AI down the content-team options still work (AI-08). Each option also carries `recipeSafetyWith`, the whole recipe checked with that one option applied. Using options re-checks the whole recipe with all of them through `getRecipeDetail`. 409 `adaptation_expired`, 404 `not_found` and the 503 codes as for `getRecipeDetail`.
  ///
  /// Parameters:
  ///
  /// * [String] recipeId (required):
  ///   A library recipe (stable across its versions).
  ///
  /// * [SubstitutionRequest] substitutionRequest (required):
  Future<SubstitutionList?> listRecipeSubstitutions(String recipeId, SubstitutionRequest substitutionRequest, { Future<void>? abortTrigger, }) async {
    final response = await listRecipeSubstitutionsWithHttpInfo(recipeId, substitutionRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubstitutionList',) as SubstitutionList;
    
    }
    return null;
  }

  /// Browse and search the recipe library for the selected eaters
  ///
  /// Lists published library recipes (LIB-08): with no `query` and no filters it is the browse list; `query` matches recipe names and ingredient names, local names included; `regionIds`, `mealTypes` and `timeAvailable` filter. Only published recipes with a recorded tester and test date are ever served (LIB-01). Every item carries a completed Cek Aman result for exactly the selected eaters (SAF-02, PRF-11); an item Cek Aman could not check is left out, never returned without a result. Recipes that are Not safe for a selected member are left out and counted in `hiddenNotSafe` unless `includeNotSafe` is true; when included they carry their Not safe result, never a softer one. The query travels in the body, so it never appears in a URL or an access log, and is never stored. Pages follow `nextCursor`; a cursor works only with the same request body (400 otherwise). A selected member that is not in the household answers 404 `not_found`. When a member's rules cannot be read the answer is 503 `rules_unavailable`, and without verified reference data or library it is 503 `reference_data_unavailable`, never an unchecked list. Works with every AI service down (AI-08).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [LibrarySearchRequest] librarySearchRequest (required):
  Future<Response> searchLibraryRecipesWithHttpInfo(LibrarySearchRequest librarySearchRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/library/recipes/search';

    // ignore: prefer_final_locals
    Object? postBody = librarySearchRequest;

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

  /// Browse and search the recipe library for the selected eaters
  ///
  /// Lists published library recipes (LIB-08): with no `query` and no filters it is the browse list; `query` matches recipe names and ingredient names, local names included; `regionIds`, `mealTypes` and `timeAvailable` filter. Only published recipes with a recorded tester and test date are ever served (LIB-01). Every item carries a completed Cek Aman result for exactly the selected eaters (SAF-02, PRF-11); an item Cek Aman could not check is left out, never returned without a result. Recipes that are Not safe for a selected member are left out and counted in `hiddenNotSafe` unless `includeNotSafe` is true; when included they carry their Not safe result, never a softer one. The query travels in the body, so it never appears in a URL or an access log, and is never stored. Pages follow `nextCursor`; a cursor works only with the same request body (400 otherwise). A selected member that is not in the household answers 404 `not_found`. When a member's rules cannot be read the answer is 503 `rules_unavailable`, and without verified reference data or library it is 503 `reference_data_unavailable`, never an unchecked list. Works with every AI service down (AI-08).
  ///
  /// Parameters:
  ///
  /// * [LibrarySearchRequest] librarySearchRequest (required):
  Future<LibrarySearchResult?> searchLibraryRecipes(LibrarySearchRequest librarySearchRequest, { Future<void>? abortTrigger, }) async {
    final response = await searchLibraryRecipesWithHttpInfo(librarySearchRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LibrarySearchResult',) as LibrarySearchResult;
    
    }
    return null;
  }
}
