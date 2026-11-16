//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class AdminApi {
  AdminApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Start a draft change to the ingredient data
  ///
  /// A content editor proposes a new ingredient, a change to one, or its retirement (SAF-06, SAF-07, SAF-13). The content is validated against the reference ingredient schema (400 `validation_failed` with pointers into `content`). Nothing reaches Cek Aman until a second person approves it and it is published in a reference release (two-step approval, QUESTIONS #20). Every change is attributed to the staff member and versioned (DAT-06). Values come from the content team; this API never fills them in.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [IngredientDraftCreate] ingredientDraftCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> createIngredientDraftWithHttpInfo(IngredientDraftCreate ingredientDraftCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/reference/ingredient-drafts';

    // ignore: prefer_final_locals
    Object? postBody = ingredientDraftCreate;

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

  /// Start a draft change to the ingredient data
  ///
  /// A content editor proposes a new ingredient, a change to one, or its retirement (SAF-06, SAF-07, SAF-13). The content is validated against the reference ingredient schema (400 `validation_failed` with pointers into `content`). Nothing reaches Cek Aman until a second person approves it and it is published in a reference release (two-step approval, QUESTIONS #20). Every change is attributed to the staff member and versioned (DAT-06). Values come from the content team; this API never fills them in.
  ///
  /// Parameters:
  ///
  /// * [IngredientDraftCreate] ingredientDraftCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<IngredientDraft?> createIngredientDraft(IngredientDraftCreate ingredientDraftCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await createIngredientDraftWithHttpInfo(ingredientDraftCreate, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientDraft',) as IngredientDraft;
    
    }
    return null;
  }

  /// Start a new recipe or a new version of one
  ///
  /// A content editor drafts a new library recipe, or a new version of a published one (`recipeId`), with the LIB-03 fields, regional variant link (LIB-04), and content-team substitutions and variants (SAF-11). Halal status and nutrition are never entered: halal comes from Cek Aman's ingredient data (LIB-05) and nutrition from the reviewed calculation (T-042). A draft is never served to households.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RecipeDraftCreate] recipeDraftCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> createRecipeDraftWithHttpInfo(RecipeDraftCreate recipeDraftCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipe-drafts';

    // ignore: prefer_final_locals
    Object? postBody = recipeDraftCreate;

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

  /// Start a new recipe or a new version of one
  ///
  /// A content editor drafts a new library recipe, or a new version of a published one (`recipeId`), with the LIB-03 fields, regional variant link (LIB-04), and content-team substitutions and variants (SAF-11). Halal status and nutrition are never entered: halal comes from Cek Aman's ingredient data (LIB-05) and nutrition from the reviewed calculation (T-042). A draft is never served to households.
  ///
  /// Parameters:
  ///
  /// * [RecipeDraftCreate] recipeDraftCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<RecipeDraft?> createRecipeDraft(RecipeDraftCreate recipeDraftCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await createRecipeDraftWithHttpInfo(recipeDraftCreate, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecipeDraft',) as RecipeDraft;
    
    }
    return null;
  }

  /// Approve or reject an ingredient draft
  ///
  /// The second step of the two-step approval (QUESTIONS #20): a safety reviewer who is not the author approves or rejects a draft in review. The author answers 409 `second_person_required`. An approved change goes live with the next reference release, which records the new data version (SAF-13, DAT-06, T-050); a rejected one goes back to the author with the note.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [DraftDecisionInput] draftDecisionInput (required):
  Future<Response> decideIngredientDraftWithHttpInfo(String draftId, DraftDecisionInput draftDecisionInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/reference/ingredient-drafts/{draftId}/decision'
      .replaceAll('{draftId}', draftId);

    // ignore: prefer_final_locals
    Object? postBody = draftDecisionInput;

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

  /// Approve or reject an ingredient draft
  ///
  /// The second step of the two-step approval (QUESTIONS #20): a safety reviewer who is not the author approves or rejects a draft in review. The author answers 409 `second_person_required`. An approved change goes live with the next reference release, which records the new data version (SAF-13, DAT-06, T-050); a rejected one goes back to the author with the note.
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [DraftDecisionInput] draftDecisionInput (required):
  Future<IngredientDraft?> decideIngredientDraft(String draftId, DraftDecisionInput draftDecisionInput, { Future<void>? abortTrigger, }) async {
    final response = await decideIngredientDraftWithHttpInfo(draftId, draftDecisionInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientDraft',) as IngredientDraft;
    
    }
    return null;
  }

  /// Approve and publish, or reject, a recipe draft
  ///
  /// A safety reviewer who is not the author (409 `second_person_required`, QUESTIONS #81) approves or rejects a draft in review. Approval publishes it as the recipe's next version at once, without an app release (LIB-11, NFR-20); households get it on their next request, each check recording the recipe version (DAT-06). Approval needs the test record (409 `recipe_not_tested`, LIB-01).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [DraftDecisionInput] draftDecisionInput (required):
  Future<Response> decideRecipeDraftWithHttpInfo(String draftId, DraftDecisionInput draftDecisionInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipe-drafts/{draftId}/decision'
      .replaceAll('{draftId}', draftId);

    // ignore: prefer_final_locals
    Object? postBody = draftDecisionInput;

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

  /// Approve and publish, or reject, a recipe draft
  ///
  /// A safety reviewer who is not the author (409 `second_person_required`, QUESTIONS #81) approves or rejects a draft in review. Approval publishes it as the recipe's next version at once, without an app release (LIB-11, NFR-20); households get it on their next request, each check recording the recipe version (DAT-06). Approval needs the test record (409 `recipe_not_tested`, LIB-01).
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [DraftDecisionInput] draftDecisionInput (required):
  Future<RecipeDraft?> decideRecipeDraft(String draftId, DraftDecisionInput draftDecisionInput, { Future<void>? abortTrigger, }) async {
    final response = await decideRecipeDraftWithHttpInfo(draftId, draftDecisionInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecipeDraft',) as RecipeDraft;
    
    }
    return null;
  }

  /// Discard an ingredient draft
  ///
  /// The author discards a draft that is not approved yet (409 `draft_not_editable` otherwise). It is kept as `discarded` for the audit trail.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  Future<Response> discardIngredientDraftWithHttpInfo(String draftId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/reference/ingredient-drafts/{draftId}'
      .replaceAll('{draftId}', draftId);

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

  /// Discard an ingredient draft
  ///
  /// The author discards a draft that is not approved yet (409 `draft_not_editable` otherwise). It is kept as `discarded` for the audit trail.
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  Future<void> discardIngredientDraft(String draftId, { Future<void>? abortTrigger, }) async {
    final response = await discardIngredientDraftWithHttpInfo(draftId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Discard a recipe draft
  ///
  /// The author discards a draft that is not published (409 `draft_not_editable` otherwise). It is kept as `discarded` for the audit trail.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  Future<Response> discardRecipeDraftWithHttpInfo(String draftId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipe-drafts/{draftId}'
      .replaceAll('{draftId}', draftId);

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

  /// Discard a recipe draft
  ///
  /// The author discards a draft that is not published (409 `draft_not_editable` otherwise). It is kept as `discarded` for the audit trail.
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  Future<void> discardRecipeDraft(String draftId, { Future<void>? abortTrigger, }) async {
    final response = await discardRecipeDraftWithHttpInfo(draftId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get a library recipe with every published version
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] recipeId (required):
  ///   A library recipe (stable across its versions).
  Future<Response> getAdminRecipeWithHttpInfo(String recipeId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipes/{recipeId}'
      .replaceAll('{recipeId}', recipeId);

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

  /// Get a library recipe with every published version
  ///
  /// Parameters:
  ///
  /// * [String] recipeId (required):
  ///   A library recipe (stable across its versions).
  Future<AdminRecipe?> getAdminRecipe(String recipeId, { Future<void>? abortTrigger, }) async {
    final response = await getAdminRecipeWithHttpInfo(recipeId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminRecipe',) as AdminRecipe;
    
    }
    return null;
  }

  /// Get an ingredient draft
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  Future<Response> getIngredientDraftWithHttpInfo(String draftId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/reference/ingredient-drafts/{draftId}'
      .replaceAll('{draftId}', draftId);

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

  /// Get an ingredient draft
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  Future<IngredientDraft?> getIngredientDraft(String draftId, { Future<void>? abortTrigger, }) async {
    final response = await getIngredientDraftWithHttpInfo(draftId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientDraft',) as IngredientDraft;
    
    }
    return null;
  }

  /// Get a recipe draft
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  Future<Response> getRecipeDraftWithHttpInfo(String draftId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipe-drafts/{draftId}'
      .replaceAll('{draftId}', draftId);

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

  /// Get a recipe draft
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  Future<RecipeDraft?> getRecipeDraft(String draftId, { Future<void>? abortTrigger, }) async {
    final response = await getRecipeDraftWithHttpInfo(draftId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecipeDraft',) as RecipeDraft;
    
    }
    return null;
  }

  /// Get one wrong-result report
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] reportId (required):
  Future<Response> getSafetyReportWithHttpInfo(String reportId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/safety-reports/{reportId}'
      .replaceAll('{reportId}', reportId);

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

  /// Get one wrong-result report
  ///
  /// Parameters:
  ///
  /// * [String] reportId (required):
  Future<AdminSafetyReport?> getSafetyReport(String reportId, { Future<void>? abortTrigger, }) async {
    final response = await getSafetyReportWithHttpInfo(reportId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminSafetyReport',) as AdminSafetyReport;
    
    }
    return null;
  }

  /// List library recipes with their versions
  ///
  /// Published and retired library recipes (LIB-11), newest change first.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RecipeLifecycleStatus] status:
  ///   Only recipes in this state.
  ///
  /// * [String] cursor:
  ///   `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed.
  ///
  /// * [int] limit:
  ///   Items per page (default and upper limit from configuration).
  Future<Response> listAdminRecipesWithHttpInfo({ RecipeLifecycleStatus? status, String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipes';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (cursor != null) {
      queryParams.addAll(_queryParams('', 'cursor', cursor));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
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

  /// List library recipes with their versions
  ///
  /// Published and retired library recipes (LIB-11), newest change first.
  ///
  /// Parameters:
  ///
  /// * [RecipeLifecycleStatus] status:
  ///   Only recipes in this state.
  ///
  /// * [String] cursor:
  ///   `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed.
  ///
  /// * [int] limit:
  ///   Items per page (default and upper limit from configuration).
  Future<AdminRecipeList?> listAdminRecipes({ RecipeLifecycleStatus? status, String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    final response = await listAdminRecipesWithHttpInfo(status: status, cursor: cursor, limit: limit, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminRecipeList',) as AdminRecipeList;
    
    }
    return null;
  }

  /// List reference ingredient drafts
  ///
  /// Drafts of ingredient data changes, newest first, optionally by status (INT-15, SAF-13).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DraftStatus] status:
  ///   Only drafts in this state.
  ///
  /// * [String] cursor:
  ///   `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed.
  ///
  /// * [int] limit:
  ///   Items per page (default and upper limit from configuration).
  Future<Response> listIngredientDraftsWithHttpInfo({ DraftStatus? status, String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/reference/ingredient-drafts';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (cursor != null) {
      queryParams.addAll(_queryParams('', 'cursor', cursor));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
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

  /// List reference ingredient drafts
  ///
  /// Drafts of ingredient data changes, newest first, optionally by status (INT-15, SAF-13).
  ///
  /// Parameters:
  ///
  /// * [DraftStatus] status:
  ///   Only drafts in this state.
  ///
  /// * [String] cursor:
  ///   `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed.
  ///
  /// * [int] limit:
  ///   Items per page (default and upper limit from configuration).
  Future<IngredientDraftList?> listIngredientDrafts({ DraftStatus? status, String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    final response = await listIngredientDraftsWithHttpInfo(status: status, cursor: cursor, limit: limit, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientDraftList',) as IngredientDraftList;
    
    }
    return null;
  }

  /// List recipe drafts
  ///
  /// Drafts of new recipes and new recipe versions, newest first, optionally by status (LIB-11).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DraftStatus] status:
  ///   Only drafts in this state.
  ///
  /// * [String] cursor:
  ///   `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed.
  ///
  /// * [int] limit:
  ///   Items per page (default and upper limit from configuration).
  Future<Response> listRecipeDraftsWithHttpInfo({ DraftStatus? status, String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipe-drafts';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (cursor != null) {
      queryParams.addAll(_queryParams('', 'cursor', cursor));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
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

  /// List recipe drafts
  ///
  /// Drafts of new recipes and new recipe versions, newest first, optionally by status (LIB-11).
  ///
  /// Parameters:
  ///
  /// * [DraftStatus] status:
  ///   Only drafts in this state.
  ///
  /// * [String] cursor:
  ///   `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed.
  ///
  /// * [int] limit:
  ///   Items per page (default and upper limit from configuration).
  Future<RecipeDraftList?> listRecipeDrafts({ DraftStatus? status, String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    final response = await listRecipeDraftsWithHttpInfo(status: status, cursor: cursor, limit: limit, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecipeDraftList',) as RecipeDraftList;
    
    }
    return null;
  }

  /// List wrong-result reports for review
  ///
  /// The content team's review queue (SAF-15), oldest open report first. Reports show rule types and pseudonymous member labels, never names, household or member IDs.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SafetyReportStatus] status:
  ///   Only reports in this state.
  ///
  /// * [String] cursor:
  ///   `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed.
  ///
  /// * [int] limit:
  ///   Items per page (default and upper limit from configuration).
  Future<Response> listSafetyReportsWithHttpInfo({ SafetyReportStatus? status, String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/safety-reports';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (cursor != null) {
      queryParams.addAll(_queryParams('', 'cursor', cursor));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
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

  /// List wrong-result reports for review
  ///
  /// The content team's review queue (SAF-15), oldest open report first. Reports show rule types and pseudonymous member labels, never names, household or member IDs.
  ///
  /// Parameters:
  ///
  /// * [SafetyReportStatus] status:
  ///   Only reports in this state.
  ///
  /// * [String] cursor:
  ///   `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed.
  ///
  /// * [int] limit:
  ///   Items per page (default and upper limit from configuration).
  Future<AdminSafetyReportList?> listSafetyReports({ SafetyReportStatus? status, String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    final response = await listSafetyReportsWithHttpInfo(status: status, cursor: cursor, limit: limit, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminSafetyReportList',) as AdminSafetyReportList;
    
    }
    return null;
  }

  /// Record the cook's test of a recipe draft
  ///
  /// A content editor records who tested this exact draft revision in a real kitchen and when (LIB-01, NFR-23), from the cook's sign-off. Staff accounts only: no household client, service or AI can call it, and a recipe is never published without this record and a second person's approval. It records a fact; it never marks anything safe.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [RecipeTestRecordInput] recipeTestRecordInput (required):
  Future<Response> recordRecipeTestWithHttpInfo(String draftId, RecipeTestRecordInput recipeTestRecordInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipe-drafts/{draftId}/test-record'
      .replaceAll('{draftId}', draftId);

    // ignore: prefer_final_locals
    Object? postBody = recipeTestRecordInput;

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

  /// Record the cook's test of a recipe draft
  ///
  /// A content editor records who tested this exact draft revision in a real kitchen and when (LIB-01, NFR-23), from the cook's sign-off. Staff accounts only: no household client, service or AI can call it, and a recipe is never published without this record and a second person's approval. It records a fact; it never marks anything safe.
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [RecipeTestRecordInput] recipeTestRecordInput (required):
  Future<RecipeDraft?> recordRecipeTest(String draftId, RecipeTestRecordInput recipeTestRecordInput, { Future<void>? abortTrigger, }) async {
    final response = await recordRecipeTestWithHttpInfo(draftId, recipeTestRecordInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecipeDraft',) as RecipeDraft;
    
    }
    return null;
  }

  /// Retire a library recipe
  ///
  /// Takes a published recipe out of the library without an app release (LIB-11): it is no longer searched, suggested or opened (404 for households). Its versions stay for the audit trail and the safety log. A newer version than `expectedVersion` answers 409 `draft_changed`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] recipeId (required):
  ///   A library recipe (stable across its versions).
  ///
  /// * [RecipeRetireInput] recipeRetireInput (required):
  Future<Response> retireRecipeWithHttpInfo(String recipeId, RecipeRetireInput recipeRetireInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipes/{recipeId}/retire'
      .replaceAll('{recipeId}', recipeId);

    // ignore: prefer_final_locals
    Object? postBody = recipeRetireInput;

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

  /// Retire a library recipe
  ///
  /// Takes a published recipe out of the library without an app release (LIB-11): it is no longer searched, suggested or opened (404 for households). Its versions stay for the audit trail and the safety log. A newer version than `expectedVersion` answers 409 `draft_changed`.
  ///
  /// Parameters:
  ///
  /// * [String] recipeId (required):
  ///   A library recipe (stable across its versions).
  ///
  /// * [RecipeRetireInput] recipeRetireInput (required):
  Future<AdminRecipe?> retireRecipe(String recipeId, RecipeRetireInput recipeRetireInput, { Future<void>? abortTrigger, }) async {
    final response = await retireRecipeWithHttpInfo(recipeId, recipeRetireInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminRecipe',) as AdminRecipe;
    
    }
    return null;
  }

  /// Confirm or reject a wrong-result report
  ///
  /// A safety reviewer marks an open report confirmed or rejected and may name the fix (for example an ingredient draft). A confirmed report adds a case to the Cek Aman regression suite (NFR-07). A reviewed report answers 409 `report_already_reviewed`. Reviewing changes no safety result: only a published data or rule-set change does.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] reportId (required):
  ///
  /// * [SafetyReportReviewInput] safetyReportReviewInput (required):
  Future<Response> reviewSafetyReportWithHttpInfo(String reportId, SafetyReportReviewInput safetyReportReviewInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/safety-reports/{reportId}/review'
      .replaceAll('{reportId}', reportId);

    // ignore: prefer_final_locals
    Object? postBody = safetyReportReviewInput;

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

  /// Confirm or reject a wrong-result report
  ///
  /// A safety reviewer marks an open report confirmed or rejected and may name the fix (for example an ingredient draft). A confirmed report adds a case to the Cek Aman regression suite (NFR-07). A reviewed report answers 409 `report_already_reviewed`. Reviewing changes no safety result: only a published data or rule-set change does.
  ///
  /// Parameters:
  ///
  /// * [String] reportId (required):
  ///
  /// * [SafetyReportReviewInput] safetyReportReviewInput (required):
  Future<AdminSafetyReport?> reviewSafetyReport(String reportId, SafetyReportReviewInput safetyReportReviewInput, { Future<void>? abortTrigger, }) async {
    final response = await reviewSafetyReportWithHttpInfo(reportId, safetyReportReviewInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminSafetyReport',) as AdminSafetyReport;
    
    }
    return null;
  }

  /// Send an ingredient draft for review
  ///
  /// The author sends a valid draft to a safety reviewer (`in_review`). A draft with validation errors answers 400; a newer revision 409 `draft_changed`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [DraftRevisionInput] draftRevisionInput (required):
  Future<Response> submitIngredientDraftWithHttpInfo(String draftId, DraftRevisionInput draftRevisionInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/reference/ingredient-drafts/{draftId}/submit'
      .replaceAll('{draftId}', draftId);

    // ignore: prefer_final_locals
    Object? postBody = draftRevisionInput;

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

  /// Send an ingredient draft for review
  ///
  /// The author sends a valid draft to a safety reviewer (`in_review`). A draft with validation errors answers 400; a newer revision 409 `draft_changed`.
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [DraftRevisionInput] draftRevisionInput (required):
  Future<IngredientDraft?> submitIngredientDraft(String draftId, DraftRevisionInput draftRevisionInput, { Future<void>? abortTrigger, }) async {
    final response = await submitIngredientDraftWithHttpInfo(draftId, draftRevisionInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientDraft',) as IngredientDraft;
    
    }
    return null;
  }

  /// Send a recipe draft for review
  ///
  /// The author sends a valid draft for approval (`in_review`). It needs a test record for the current revision (409 `recipe_not_tested`) and every ingredient line resolved to a reference ingredient (409 `recipe_ingredients_unresolved`); a newer revision answers 409 `draft_changed`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [DraftRevisionInput] draftRevisionInput (required):
  Future<Response> submitRecipeDraftWithHttpInfo(String draftId, DraftRevisionInput draftRevisionInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipe-drafts/{draftId}/submit'
      .replaceAll('{draftId}', draftId);

    // ignore: prefer_final_locals
    Object? postBody = draftRevisionInput;

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

  /// Send a recipe draft for review
  ///
  /// The author sends a valid draft for approval (`in_review`). It needs a test record for the current revision (409 `recipe_not_tested`) and every ingredient line resolved to a reference ingredient (409 `recipe_ingredients_unresolved`); a newer revision answers 409 `draft_changed`.
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [DraftRevisionInput] draftRevisionInput (required):
  Future<RecipeDraft?> submitRecipeDraft(String draftId, DraftRevisionInput draftRevisionInput, { Future<void>? abortTrigger, }) async {
    final response = await submitRecipeDraftWithHttpInfo(draftId, draftRevisionInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecipeDraft',) as RecipeDraft;
    
    }
    return null;
  }

  /// Replace an ingredient draft's content
  ///
  /// Only the author, and only while the draft is `draft` or `rejected` (409 `draft_not_editable` otherwise). `expectedRevision` is the revision the editor started from; a newer one answers 409 `draft_changed`. Editing a rejected draft returns it to `draft`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [IngredientDraftUpdate] ingredientDraftUpdate (required):
  Future<Response> updateIngredientDraftWithHttpInfo(String draftId, IngredientDraftUpdate ingredientDraftUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/reference/ingredient-drafts/{draftId}'
      .replaceAll('{draftId}', draftId);

    // ignore: prefer_final_locals
    Object? postBody = ingredientDraftUpdate;

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

  /// Replace an ingredient draft's content
  ///
  /// Only the author, and only while the draft is `draft` or `rejected` (409 `draft_not_editable` otherwise). `expectedRevision` is the revision the editor started from; a newer one answers 409 `draft_changed`. Editing a rejected draft returns it to `draft`.
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [IngredientDraftUpdate] ingredientDraftUpdate (required):
  Future<IngredientDraft?> updateIngredientDraft(String draftId, IngredientDraftUpdate ingredientDraftUpdate, { Future<void>? abortTrigger, }) async {
    final response = await updateIngredientDraftWithHttpInfo(draftId, ingredientDraftUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientDraft',) as IngredientDraft;
    
    }
    return null;
  }

  /// Replace a recipe draft's content
  ///
  /// As for ingredient drafts: author only, while `draft` or `rejected`, with `expectedRevision` (409 `draft_not_editable`, 409 `draft_changed`). Changing the content clears a recorded test, which must be recorded again for the changed recipe (LIB-01).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [RecipeDraftUpdate] recipeDraftUpdate (required):
  Future<Response> updateRecipeDraftWithHttpInfo(String draftId, RecipeDraftUpdate recipeDraftUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/recipe-drafts/{draftId}'
      .replaceAll('{draftId}', draftId);

    // ignore: prefer_final_locals
    Object? postBody = recipeDraftUpdate;

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

  /// Replace a recipe draft's content
  ///
  /// As for ingredient drafts: author only, while `draft` or `rejected`, with `expectedRevision` (409 `draft_not_editable`, 409 `draft_changed`). Changing the content clears a recorded test, which must be recorded again for the changed recipe (LIB-01).
  ///
  /// Parameters:
  ///
  /// * [String] draftId (required):
  ///   A staff draft of reference data or of a recipe.
  ///
  /// * [RecipeDraftUpdate] recipeDraftUpdate (required):
  Future<RecipeDraft?> updateRecipeDraft(String draftId, RecipeDraftUpdate recipeDraftUpdate, { Future<void>? abortTrigger, }) async {
    final response = await updateRecipeDraftWithHttpInfo(draftId, recipeDraftUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecipeDraft',) as RecipeDraft;
    
    }
    return null;
  }

  /// Upload a recipe image
  ///
  /// A content editor uploads a food photo for a recipe (LIB-03, LIB-11). Never a photo of a person. The server strips metadata, stores a fixed-size copy and returns its ID for `AdminRecipeContent.imageIds`. Size and dimension limits come from configuration (400 otherwise).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] body (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> uploadLibraryImageWithHttpInfo(MultipartFile body, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/admin/library-images';

    // ignore: prefer_final_locals
    Object? postBody = body;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (idempotencyKey != null) {
      headerParams[r'Idempotency-Key'] = parameterToString(idempotencyKey);
    }

    const contentTypes = <String>['image/webp', 'image/jpeg'];


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

  /// Upload a recipe image
  ///
  /// A content editor uploads a food photo for a recipe (LIB-03, LIB-11). Never a photo of a person. The server strips metadata, stores a fixed-size copy and returns its ID for `AdminRecipeContent.imageIds`. Size and dimension limits come from configuration (400 otherwise).
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] body (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<LibraryImage?> uploadLibraryImage(MultipartFile body, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await uploadLibraryImageWithHttpInfo(body, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LibraryImage',) as LibraryImage;
    
    }
    return null;
  }
}
