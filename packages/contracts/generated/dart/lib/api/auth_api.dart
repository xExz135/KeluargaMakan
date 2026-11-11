//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;


class AuthApi {
  AuthApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Exchange a refresh token for new tokens
  ///
  /// Rotates the refresh token. Each refresh token works once; reusing an old one revokes the whole session and returns 401 `refresh_token_invalid`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SessionRefresh] sessionRefresh (required):
  Future<Response> refreshSessionWithHttpInfo(SessionRefresh sessionRefresh, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/refresh';

    // ignore: prefer_final_locals
    Object? postBody = sessionRefresh;

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

  /// Exchange a refresh token for new tokens
  ///
  /// Rotates the refresh token. Each refresh token works once; reusing an old one revokes the whole session and returns 401 `refresh_token_invalid`.
  ///
  /// Parameters:
  ///
  /// * [SessionRefresh] sessionRefresh (required):
  Future<SessionTokens?> refreshSession(SessionRefresh sessionRefresh, { Future<void>? abortTrigger, }) async {
    final response = await refreshSessionWithHttpInfo(sessionRefresh, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SessionTokens',) as SessionTokens;
    
    }
    return null;
  }

  /// Send a sign-in code to a phone number or email
  ///
  /// Sends a one-time verification code (ACC-01). The response is the same whether or not an account exists for the destination, so it cannot be used to discover accounts. Code length, expiry and the resend wait come from configuration. Requests are rate-limited per destination and per device; a limited request returns 429 with `Retry-After`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SignInCodeRequest] signInCodeRequest (required):
  Future<Response> requestSignInCodeWithHttpInfo(SignInCodeRequest signInCodeRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/code/request';

    // ignore: prefer_final_locals
    Object? postBody = signInCodeRequest;

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

  /// Send a sign-in code to a phone number or email
  ///
  /// Sends a one-time verification code (ACC-01). The response is the same whether or not an account exists for the destination, so it cannot be used to discover accounts. Code length, expiry and the resend wait come from configuration. Requests are rate-limited per destination and per device; a limited request returns 429 with `Retry-After`.
  ///
  /// Parameters:
  ///
  /// * [SignInCodeRequest] signInCodeRequest (required):
  Future<SignInCodeChallenge?> requestSignInCode(SignInCodeRequest signInCodeRequest, { Future<void>? abortTrigger, }) async {
    final response = await requestSignInCodeWithHttpInfo(signInCodeRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SignInCodeChallenge',) as SignInCodeChallenge;
    
    }
    return null;
  }

  /// Exchange a Google ID token for a session
  ///
  /// Signs in with a Google ID token obtained on Android through Credential Manager (ACC-02). The server verifies the token with Google. When Google sign-in is unavailable the server returns 503 `sign_in_method_unavailable` and the client offers phone or email sign-in instead (INT-13). Apple sign-in is not part of this API.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [GoogleSignIn] googleSignIn (required):
  Future<Response> signInWithGoogleWithHttpInfo(GoogleSignIn googleSignIn, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/google';

    // ignore: prefer_final_locals
    Object? postBody = googleSignIn;

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

  /// Exchange a Google ID token for a session
  ///
  /// Signs in with a Google ID token obtained on Android through Credential Manager (ACC-02). The server verifies the token with Google. When Google sign-in is unavailable the server returns 503 `sign_in_method_unavailable` and the client offers phone or email sign-in instead (INT-13). Apple sign-in is not part of this API.
  ///
  /// Parameters:
  ///
  /// * [GoogleSignIn] googleSignIn (required):
  Future<Session?> signInWithGoogle(GoogleSignIn googleSignIn, { Future<void>? abortTrigger, }) async {
    final response = await signInWithGoogleWithHttpInfo(googleSignIn, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Session',) as Session;
    
    }
    return null;
  }

  /// Sign out on this device
  ///
  /// Revokes the current session (its access and refresh tokens). Household data is kept on the server, so the user can sign in again on any device (ACC-13). The client clears its local session afterwards.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> signOutWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/sign-out';

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

  /// Sign out on this device
  ///
  /// Revokes the current session (its access and refresh tokens). Household data is kept on the server, so the user can sign in again on any device (ACC-13). The client clears its local session afterwards.
  Future<void> signOut({ Future<void>? abortTrigger, }) async {
    final response = await signOutWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Verify a sign-in code and start a session
  ///
  /// Verifies the code for a challenge (ACC-01). On first sign-in a manager account is created with no household (`account.householdId` is null); the client then creates the household. On a later sign-in, including on a new device, the existing household is returned unchanged (ACC-13). Wrong codes count towards an attempt limit from configuration.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SignInCodeVerification] signInCodeVerification (required):
  Future<Response> verifySignInCodeWithHttpInfo(SignInCodeVerification signInCodeVerification, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/auth/code/verify';

    // ignore: prefer_final_locals
    Object? postBody = signInCodeVerification;

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

  /// Verify a sign-in code and start a session
  ///
  /// Verifies the code for a challenge (ACC-01). On first sign-in a manager account is created with no household (`account.householdId` is null); the client then creates the household. On a later sign-in, including on a new device, the existing household is returned unchanged (ACC-13). Wrong codes count towards an attempt limit from configuration.
  ///
  /// Parameters:
  ///
  /// * [SignInCodeVerification] signInCodeVerification (required):
  Future<Session?> verifySignInCode(SignInCodeVerification signInCodeVerification, { Future<void>? abortTrigger, }) async {
    final response = await verifySignInCodeWithHttpInfo(signInCodeVerification, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Session',) as Session;
    
    }
    return null;
  }
}
