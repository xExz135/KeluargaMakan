//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class PreferencesApi {
  PreferencesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Replace a profile's likes and dislikes
  ///
  /// Likes and dislikes are ingredients or dishes (PRF-06). A dislike is not an allergy and is never treated as a hard rule. The whole object is replaced.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [LikesDislikesInput] likesDislikesInput (required):
  Future<Response> replaceLikesDislikesWithHttpInfo(String profileId, LikesDislikesInput likesDislikesInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/likes-dislikes'
      .replaceAll('{profileId}', profileId);

    // ignore: prefer_final_locals
    Object? postBody = likesDislikesInput;

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

  /// Replace a profile's likes and dislikes
  ///
  /// Likes and dislikes are ingredients or dishes (PRF-06). A dislike is not an allergy and is never treated as a hard rule. The whole object is replaced.
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [LikesDislikesInput] likesDislikesInput (required):
  Future<LikesDislikes?> replaceLikesDislikes(String profileId, LikesDislikesInput likesDislikesInput, { Future<void>? abortTrigger, }) async {
    final response = await replaceLikesDislikesWithHttpInfo(profileId, likesDislikesInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LikesDislikes',) as LikesDislikes;
    
    }
    return null;
  }

  /// Replace a profile's soft preferences
  ///
  /// Soft preferences may be relaxed when selected members conflict (PRF-05, PRF-12). They are not hard rules and are never health data. The whole object is replaced, so an offline edit replayed later is safe to send again.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [SoftPreferencesInput] softPreferencesInput (required):
  Future<Response> replaceSoftPreferencesWithHttpInfo(String profileId, SoftPreferencesInput softPreferencesInput, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}/preferences'
      .replaceAll('{profileId}', profileId);

    // ignore: prefer_final_locals
    Object? postBody = softPreferencesInput;

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

  /// Replace a profile's soft preferences
  ///
  /// Soft preferences may be relaxed when selected members conflict (PRF-05, PRF-12). They are not hard rules and are never health data. The whole object is replaced, so an offline edit replayed later is safe to send again.
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [SoftPreferencesInput] softPreferencesInput (required):
  Future<SoftPreferences?> replaceSoftPreferences(String profileId, SoftPreferencesInput softPreferencesInput, { Future<void>? abortTrigger, }) async {
    final response = await replaceSoftPreferencesWithHttpInfo(profileId, softPreferencesInput, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SoftPreferences',) as SoftPreferences;
    
    }
    return null;
  }
}
