//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class MealsApi {
  MealsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Record a cooked meal and its feedback
  ///
  /// The cooked-meal record (QUESTIONS #19) written when cooking ends (CKM-10), with the one-tap household feedback and optional per-person feedback (PRF-13). The phone makes `mealId` (a random UUID) when cooking ends and sends the whole record each time, so the offline queue can replay it safely. Records are keyed by household and meal ID, so an ID another household used is simply a new meal here. The copy made last on the phone wins (`ageMs`, server bounds): a late older copy is ignored and the stored record is returned. Rate-limited (429). Feedback and recent meals adjust ranking for the household and the people who ate from the next request on (PRF-14, SUG-07, SUG-08). Every eater and rated member must be in the household (404 `not_found` otherwise); a rating for someone who did not eat is 400. Kept for the configured meal-history retention (DAT-04, QUESTIONS #19). No nutrition is recorded in V1.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] mealId (required):
  ///   A cooked meal of the session's household: a random UUID in lower case that the phone makes when cooking ends, so the record can be sent again safely. Keyed per household.
  ///
  /// * [CookedMealInput] cookedMealInput (required):
  Future<Response> recordCookedMealWithHttpInfo(String mealId, CookedMealInput cookedMealInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/meals/{mealId}'
      .replaceAll('{mealId}', mealId);

    // ignore: prefer_final_locals
    Object? postBody = cookedMealInput;

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

  /// Record a cooked meal and its feedback
  ///
  /// The cooked-meal record (QUESTIONS #19) written when cooking ends (CKM-10), with the one-tap household feedback and optional per-person feedback (PRF-13). The phone makes `mealId` (a random UUID) when cooking ends and sends the whole record each time, so the offline queue can replay it safely. Records are keyed by household and meal ID, so an ID another household used is simply a new meal here. The copy made last on the phone wins (`ageMs`, server bounds): a late older copy is ignored and the stored record is returned. Rate-limited (429). Feedback and recent meals adjust ranking for the household and the people who ate from the next request on (PRF-14, SUG-07, SUG-08). Every eater and rated member must be in the household (404 `not_found` otherwise); a rating for someone who did not eat is 400. Kept for the configured meal-history retention (DAT-04, QUESTIONS #19). No nutrition is recorded in V1.
  ///
  /// Parameters:
  ///
  /// * [String] mealId (required):
  ///   A cooked meal of the session's household: a random UUID in lower case that the phone makes when cooking ends, so the record can be sent again safely. Keyed per household.
  ///
  /// * [CookedMealInput] cookedMealInput (required):
  Future<CookedMeal?> recordCookedMeal(String mealId, CookedMealInput cookedMealInput, { Future<void>? abortTrigger, }) async {
    final response = await recordCookedMealWithHttpInfo(mealId, cookedMealInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CookedMeal',) as CookedMeal;
    
    }
    return null;
  }
}
