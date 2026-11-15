//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class KitchenApi {
  KitchenApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add an ingredient to the kitchen
  ///
  /// Adds a reference ingredient found by search (KIT-04) or a custom ingredient (KIT-05). A custom ingredient is stored with `ingredientId: null` and `isCustom: true`; Cek Aman gives it \"Check the label\" for every member with a hard rule (SAF-09). An unknown `ingredientId` gives 400 `validation_failed`. When the reference dataset cannot be verified, adding a reference ingredient gives 503 `reference_data_unavailable` (custom ingredients still work). If the ingredient is already in the kitchen nothing is duplicated: the existing item takes the requested state and is returned with 200. Returns 409 `kitchen_item_limit_reached` at the configured limit.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [KitchenItemCreate] kitchenItemCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> addKitchenItemWithHttpInfo(KitchenItemCreate kitchenItemCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/items';

    // ignore: prefer_final_locals
    Object? postBody = kitchenItemCreate;

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

  /// Add an ingredient to the kitchen
  ///
  /// Adds a reference ingredient found by search (KIT-04) or a custom ingredient (KIT-05). A custom ingredient is stored with `ingredientId: null` and `isCustom: true`; Cek Aman gives it \"Check the label\" for every member with a hard rule (SAF-09). An unknown `ingredientId` gives 400 `validation_failed`. When the reference dataset cannot be verified, adding a reference ingredient gives 503 `reference_data_unavailable` (custom ingredients still work). If the ingredient is already in the kitchen nothing is duplicated: the existing item takes the requested state and is returned with 200. Returns 409 `kitchen_item_limit_reached` at the configured limit.
  ///
  /// Parameters:
  ///
  /// * [KitchenItemCreate] kitchenItemCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<KitchenItem?> addKitchenItem(KitchenItemCreate kitchenItemCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await addKitchenItemWithHttpInfo(kitchenItemCreate, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'KitchenItem',) as KitchenItem;
    
    }
    return null;
  }

  /// Create an ingredient set
  ///
  /// A named group of kitchen items, for example \"Belanja mingguan\" (KIT-08). Unknown item IDs give 404 `not_found`. Returns 409 `ingredient_set_limit_reached` at the configured limit.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [IngredientSetInput] ingredientSetInput (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> createIngredientSetWithHttpInfo(IngredientSetInput ingredientSetInput, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/sets';

    // ignore: prefer_final_locals
    Object? postBody = ingredientSetInput;

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

  /// Create an ingredient set
  ///
  /// A named group of kitchen items, for example \"Belanja mingguan\" (KIT-08). Unknown item IDs give 404 `not_found`. Returns 409 `ingredient_set_limit_reached` at the configured limit.
  ///
  /// Parameters:
  ///
  /// * [IngredientSetInput] ingredientSetInput (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<IngredientSet?> createIngredientSet(IngredientSetInput ingredientSetInput, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await createIngredientSetWithHttpInfo(ingredientSetInput, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientSet',) as IngredientSet;
    
    }
    return null;
  }

  /// Delete an ingredient set
  ///
  /// The items stay in the kitchen.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] setId (required):
  ///   An ingredient set in the session's household.
  Future<Response> deleteIngredientSetWithHttpInfo(String setId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/sets/{setId}'
      .replaceAll('{setId}', setId);

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

  /// Delete an ingredient set
  ///
  /// The items stay in the kitchen.
  ///
  /// Parameters:
  ///
  /// * [String] setId (required):
  ///   An ingredient set in the session's household.
  Future<void> deleteIngredientSet(String setId, { Future<void>? abortTrigger, }) async {
    final response = await deleteIngredientSetWithHttpInfo(setId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// List the household's ingredient sets
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listIngredientSetsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/sets';

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

  /// List the household's ingredient sets
  Future<IngredientSetList?> listIngredientSets({ Future<void>? abortTrigger, }) async {
    final response = await listIngredientSetsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientSetList',) as IngredientSetList;
    
    }
    return null;
  }

  /// List the household's saved ingredients
  ///
  /// The saved kitchen of the session's household, the same on every phone signed in to it (KIT-01). Items come in KIT-03 category order. The default staples are created with the household as available and stay available until the user marks them out (KIT-07, ACC-05). Reference names come from the verified reference dataset; when it is not available the list is still returned, with `displayName` null.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listKitchenItemsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/items';

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

  /// List the household's saved ingredients
  ///
  /// The saved kitchen of the session's household, the same on every phone signed in to it (KIT-01). Items come in KIT-03 category order. The default staples are created with the household as available and stay available until the user marks them out (KIT-07, ACC-05). Reference names come from the verified reference dataset; when it is not available the list is still returned, with `displayName` null.
  Future<KitchenItemList?> listKitchenItems({ Future<void>? abortTrigger, }) async {
    final response = await listKitchenItemsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'KitchenItemList',) as KitchenItemList;
    
    }
    return null;
  }

  /// Mark every item in a set available
  ///
  /// \"Tandai semua ada\" (KIT-08): every item in the set becomes available in one call, stamped with the server time (KIT-16). No other item changes, and nothing becomes out. Sending it again leaves the same result. The response lists the set's items after the change; the client keeps the earlier states for its undo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] setId (required):
  ///   An ingredient set in the session's household.
  Future<Response> markIngredientSetAvailableWithHttpInfo(String setId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/sets/{setId}/mark-available'
      .replaceAll('{setId}', setId);

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

  /// Mark every item in a set available
  ///
  /// \"Tandai semua ada\" (KIT-08): every item in the set becomes available in one call, stamped with the server time (KIT-16). No other item changes, and nothing becomes out. Sending it again leaves the same result. The response lists the set's items after the change; the client keeps the earlier states for its undo.
  ///
  /// Parameters:
  ///
  /// * [String] setId (required):
  ///   An ingredient set in the session's household.
  Future<KitchenItemList?> markIngredientSetAvailable(String setId, { Future<void>? abortTrigger, }) async {
    final response = await markIngredientSetAvailableWithHttpInfo(setId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'KitchenItemList',) as KitchenItemList;
    
    }
    return null;
  }

  /// Remove an ingredient from the kitchen
  ///
  /// Removes the item and its set memberships. A default staple can be removed too; marking it out keeps it in the list instead (KIT-07).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] itemId (required):
  ///   A kitchen item in the session's household.
  Future<Response> removeKitchenItemWithHttpInfo(String itemId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/items/{itemId}'
      .replaceAll('{itemId}', itemId);

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

  /// Remove an ingredient from the kitchen
  ///
  /// Removes the item and its set memberships. A default staple can be removed too; marking it out keeps it in the list instead (KIT-07).
  ///
  /// Parameters:
  ///
  /// * [String] itemId (required):
  ///   A kitchen item in the session's household.
  Future<void> removeKitchenItem(String itemId, { Future<void>? abortTrigger, }) async {
    final response = await removeKitchenItemWithHttpInfo(itemId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Rename an ingredient set or change its items
  ///
  /// The whole set is replaced, so an offline edit sent again is safe.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] setId (required):
  ///   An ingredient set in the session's household.
  ///
  /// * [IngredientSetInput] ingredientSetInput (required):
  Future<Response> replaceIngredientSetWithHttpInfo(String setId, IngredientSetInput ingredientSetInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/sets/{setId}'
      .replaceAll('{setId}', setId);

    // ignore: prefer_final_locals
    Object? postBody = ingredientSetInput;

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

  /// Rename an ingredient set or change its items
  ///
  /// The whole set is replaced, so an offline edit sent again is safe.
  ///
  /// Parameters:
  ///
  /// * [String] setId (required):
  ///   An ingredient set in the session's household.
  ///
  /// * [IngredientSetInput] ingredientSetInput (required):
  Future<IngredientSet?> replaceIngredientSet(String setId, IngredientSetInput ingredientSetInput, { Future<void>? abortTrigger, }) async {
    final response = await replaceIngredientSetWithHttpInfo(setId, ingredientSetInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'IngredientSet',) as IngredientSet;
    
    }
    return null;
  }

  /// Send queued kitchen changes and fetch changes from other phones
  ///
  /// KIT-16 offline sync. The phone sends the changes it queued while offline, oldest first, and the cursor of its last sync. Each change names its ingredient (a reference ID or a custom name), so an item added offline needs no server ID. The server places each change on its own clock at the time it was made (now minus `ageMs`, so a phone with a wrong clock still orders correctly) and keeps, per ingredient, the latest change: an older change than the stored one is `superseded` and the stored item is returned. Every change has a `changeId`; sending it again returns its first result without applying it twice, so replaying the queue is safe. Change IDs belong to the household and are kept for a configured period; the same ID with a different change is `rejected` with `idempotency_key_reused`. A change rejected for a reason that can pass (`reference_data_unavailable`, `kitchen_item_limit_reached`) is not remembered: send it again later with the same `changeId`. Each change is dated at the server's time minus its `ageMs`, never later. An `ageMs` below 0 or older than the server's limit (at most 30 days) is `rejected` with `validation_failed`, on its own. A removal is kept too: a change older than the removal is `superseded`, so an old queued change cannot bring an item back, and a change that would add an item but is older than the removals the server still keeps is `superseded` as well. The response carries every item changed or removed since the cursor and a new cursor. When `cursor` is null, not issued by this server for this household, or older than the kept removals, the response has all items and `full: true`; it never carries another household's data. A rejected change (for example an unknown ingredient, a name or brand that cannot be stored, or the item limit) never stops the rest. A request without the schema's shape is refused whole with 400.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [KitchenSyncRequest] kitchenSyncRequest (required):
  Future<Response> syncKitchenWithHttpInfo(KitchenSyncRequest kitchenSyncRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/sync';

    // ignore: prefer_final_locals
    Object? postBody = kitchenSyncRequest;

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

  /// Send queued kitchen changes and fetch changes from other phones
  ///
  /// KIT-16 offline sync. The phone sends the changes it queued while offline, oldest first, and the cursor of its last sync. Each change names its ingredient (a reference ID or a custom name), so an item added offline needs no server ID. The server places each change on its own clock at the time it was made (now minus `ageMs`, so a phone with a wrong clock still orders correctly) and keeps, per ingredient, the latest change: an older change than the stored one is `superseded` and the stored item is returned. Every change has a `changeId`; sending it again returns its first result without applying it twice, so replaying the queue is safe. Change IDs belong to the household and are kept for a configured period; the same ID with a different change is `rejected` with `idempotency_key_reused`. A change rejected for a reason that can pass (`reference_data_unavailable`, `kitchen_item_limit_reached`) is not remembered: send it again later with the same `changeId`. Each change is dated at the server's time minus its `ageMs`, never later. An `ageMs` below 0 or older than the server's limit (at most 30 days) is `rejected` with `validation_failed`, on its own. A removal is kept too: a change older than the removal is `superseded`, so an old queued change cannot bring an item back, and a change that would add an item but is older than the removals the server still keeps is `superseded` as well. The response carries every item changed or removed since the cursor and a new cursor. When `cursor` is null, not issued by this server for this household, or older than the kept removals, the response has all items and `full: true`; it never carries another household's data. A rejected change (for example an unknown ingredient, a name or brand that cannot be stored, or the item limit) never stops the rest. A request without the schema's shape is refused whole with 400.
  ///
  /// Parameters:
  ///
  /// * [KitchenSyncRequest] kitchenSyncRequest (required):
  Future<KitchenSyncResponse?> syncKitchen(KitchenSyncRequest kitchenSyncRequest, { Future<void>? abortTrigger, }) async {
    final response = await syncKitchenWithHttpInfo(kitchenSyncRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'KitchenSyncResponse',) as KitchenSyncResponse;
    
    }
    return null;
  }

  /// Change an ingredient's state or details
  ///
  /// One tap toggles available and out (KIT-02). Only the fields present are changed. The change is stamped with the server time and wins over any earlier change to the same ingredient (KIT-16); sending the same change again leaves the same result. `quantity` and `brand` are optional and may be null to clear them (KIT-09). A `brandId` must be one of the ingredient's catalog `brands` in the verified reference data (400 otherwise; 503 `reference_data_unavailable` without the data); only reference ingredients take one. A typed `customName` brand is kept as text and never counts as a recorded brand, so Cek Aman keeps \"Check the label\" for brand-varying ingredients (SAF-07).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] itemId (required):
  ///   A kitchen item in the session's household.
  ///
  /// * [KitchenItemUpdate] kitchenItemUpdate (required):
  Future<Response> updateKitchenItemWithHttpInfo(String itemId, KitchenItemUpdate kitchenItemUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/kitchen/items/{itemId}'
      .replaceAll('{itemId}', itemId);

    // ignore: prefer_final_locals
    Object? postBody = kitchenItemUpdate;

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

  /// Change an ingredient's state or details
  ///
  /// One tap toggles available and out (KIT-02). Only the fields present are changed. The change is stamped with the server time and wins over any earlier change to the same ingredient (KIT-16); sending the same change again leaves the same result. `quantity` and `brand` are optional and may be null to clear them (KIT-09). A `brandId` must be one of the ingredient's catalog `brands` in the verified reference data (400 otherwise; 503 `reference_data_unavailable` without the data); only reference ingredients take one. A typed `customName` brand is kept as text and never counts as a recorded brand, so Cek Aman keeps \"Check the label\" for brand-varying ingredients (SAF-07).
  ///
  /// Parameters:
  ///
  /// * [String] itemId (required):
  ///   A kitchen item in the session's household.
  ///
  /// * [KitchenItemUpdate] kitchenItemUpdate (required):
  Future<KitchenItem?> updateKitchenItem(String itemId, KitchenItemUpdate kitchenItemUpdate, { Future<void>? abortTrigger, }) async {
    final response = await updateKitchenItemWithHttpInfo(itemId, kitchenItemUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'KitchenItem',) as KitchenItem;
    
    }
    return null;
  }
}
