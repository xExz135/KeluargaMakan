//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class ProfilesApi {
  ProfilesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add a family member profile
  ///
  /// Adds a member (PRF-01). Infant, child and teen age groups are flagged as children (PRF-18) and need the manager's confirmation as parent or guardian, which is recorded as a consent record (SET-10); without it the server returns 409 `guardian_confirmation_required`. Health data stays off for every new profile, children included, until a health-data consent is recorded (SET-10, ACC-08). Returns 409 `profile_limit_reached` at the configured limit (PRF-02).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ProfileCreate] profileCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Response> createProfileWithHttpInfo(ProfileCreate profileCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles';

    // ignore: prefer_final_locals
    Object? postBody = profileCreate;

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

  /// Add a family member profile
  ///
  /// Adds a member (PRF-01). Infant, child and teen age groups are flagged as children (PRF-18) and need the manager's confirmation as parent or guardian, which is recorded as a consent record (SET-10); without it the server returns 409 `guardian_confirmation_required`. Health data stays off for every new profile, children included, until a health-data consent is recorded (SET-10, ACC-08). Returns 409 `profile_limit_reached` at the configured limit (PRF-02).
  ///
  /// Parameters:
  ///
  /// * [ProfileCreate] profileCreate (required):
  ///
  /// * [String] idempotencyKey:
  ///   A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period.
  Future<Profile?> createProfile(ProfileCreate profileCreate, { String? idempotencyKey, Future<void>? abortTrigger, }) async {
    final response = await createProfileWithHttpInfo(profileCreate, idempotencyKey: idempotencyKey, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Profile',) as Profile;
    
    }
    return null;
  }

  /// Delete a profile and all of its data
  ///
  /// Removes the member from suggestions, safety results and plans at once and deletes the profile's data (PRF-01, SET-07). The manager's own profile cannot be deleted here (409 `manager_profile_not_deletable`); the manager deletes the whole account instead.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<Response> deleteProfileWithHttpInfo(String profileId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}'
      .replaceAll('{profileId}', profileId);

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

  /// Delete a profile and all of its data
  ///
  /// Removes the member from suggestions, safety results and plans at once and deletes the profile's data (PRF-01, SET-07). The manager's own profile cannot be deleted here (409 `manager_profile_not_deletable`); the manager deletes the whole account instead.
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<void> deleteProfile(String profileId, { Future<void>? abortTrigger, }) async {
    final response = await deleteProfileWithHttpInfo(profileId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get one profile
  ///
  /// Fails with 503 `rules_unavailable` when the member's rules cannot be read (QUESTIONS
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<Response> getProfileWithHttpInfo(String profileId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}'
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

  /// Get one profile
  ///
  /// Fails with 503 `rules_unavailable` when the member's rules cannot be read (QUESTIONS
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  Future<Profile?> getProfile(String profileId, { Future<void>? abortTrigger, }) async {
    final response = await getProfileWithHttpInfo(profileId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Profile',) as Profile;
    
    }
    return null;
  }

  /// List the household's profiles
  ///
  /// Returns every profile with its hard rules, preferences, likes and portions. The manager's own profile comes first. `maxProfiles` is the configured limit (PRF-02, at least 12, target). If any member's rules cannot be read or decrypted the whole request fails with 503 `rules_unavailable`; it never returns that member with an empty rule list (QUESTIONS #39).
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listProfilesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles';

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

  /// List the household's profiles
  ///
  /// Returns every profile with its hard rules, preferences, likes and portions. The manager's own profile comes first. `maxProfiles` is the configured limit (PRF-02, at least 12, target). If any member's rules cannot be read or decrypted the whole request fails with 503 `rules_unavailable`; it never returns that member with an empty rule list (QUESTIONS #39).
  Future<ProfileList?> listProfiles({ Future<void>? abortTrigger, }) async {
    final response = await listProfilesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ProfileList',) as ProfileList;
    
    }
    return null;
  }

  /// Edit a profile
  ///
  /// Only the fields present are changed. Setting `portionSize` or `ricePortion` to null returns it to the age-group default from configuration (PRF-07). Changing an adult profile to an infant, child or teen age group needs `guardianConfirmation` (SET-10). The child flag follows the age group and cannot be set directly (PRF-18).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [ProfileUpdate] profileUpdate (required):
  Future<Response> updateProfileWithHttpInfo(String profileId, ProfileUpdate profileUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/household/profiles/{profileId}'
      .replaceAll('{profileId}', profileId);

    // ignore: prefer_final_locals
    Object? postBody = profileUpdate;

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

  /// Edit a profile
  ///
  /// Only the fields present are changed. Setting `portionSize` or `ricePortion` to null returns it to the age-group default from configuration (PRF-07). Changing an adult profile to an infant, child or teen age group needs `guardianConfirmation` (SET-10). The child flag follows the age group and cannot be set directly (PRF-18).
  ///
  /// Parameters:
  ///
  /// * [String] profileId (required):
  ///
  /// * [ProfileUpdate] profileUpdate (required):
  Future<Profile?> updateProfile(String profileId, ProfileUpdate profileUpdate, { Future<void>? abortTrigger, }) async {
    final response = await updateProfileWithHttpInfo(profileId, profileUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Profile',) as Profile;
    
    }
    return null;
  }
}
