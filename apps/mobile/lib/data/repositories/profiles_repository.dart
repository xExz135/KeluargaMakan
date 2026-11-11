// Keluarga Saya profiles, soft preferences and likes (PRF-01, PRF-05 to
// PRF-07, PRF-18). Profiles are cached without health data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../decoders.dart';
import '../local_cache.dart';
import '../models/family.dart';

final class ProfilesRepository {
  ProfilesRepository({
    required this._caller,
    required api.ApiClient client,
    required this._cache,
  }) : _profiles = api.ProfilesApi(client),
       _preferences = api.PreferencesApi(client);

  final ApiCaller _caller;
  final api.ProfilesApi _profiles;
  final api.PreferencesApi _preferences;
  final LocalCache _cache;

  /// Every profile with its rules.
  ///
  /// - `rules_unavailable` (503) and decode failures are returned as
  ///   failures, never as profiles without rules (QUESTIONS #39).
  /// - Only when the API cannot be reached, the cached profiles are returned,
  ///   each with [RulesNotLoaded].
  Future<ApiResult<FamilyProfiles>> listProfiles() async {
    final result = await _caller.call(
      'listProfiles',
      () => _profiles.listProfilesWithHttpInfo(),
      decodeProfileList,
    );
    switch (result) {
      case Ok(:final value):
        await _cache.saveProfiles(value.members);
      case Err(failure: NetworkFailure()):
        final cached = await _cache.profiles();
        if (cached != null) return Ok(cached);
      case Err():
        break;
    }
    return result;
  }

  Future<ApiResult<FamilyMember>> getProfile(String profileId) => _caller.call(
    'getProfile',
    () => _profiles.getProfileWithHttpInfo(profileId),
    decodeProfile,
  );

  /// Adds a member (PRF-01). A child profile needs `guardianConfirmation`
  /// (SET-10). Reuse the same [idempotencyKey] when retrying.
  Future<ApiResult<FamilyMember>> createProfile(
    api.ProfileCreate body, {
    required String idempotencyKey,
  }) => _caller.call(
    'createProfile',
    () => _profiles.createProfileWithHttpInfo(
      body,
      idempotencyKey: idempotencyKey,
    ),
    decodeProfile,
  );

  Future<ApiResult<FamilyMember>> updateProfile(
    String profileId,
    api.ProfileUpdate body,
  ) => _caller.call(
    'updateProfile',
    () => _profiles.updateProfileWithHttpInfo(profileId, body),
    decodeProfile,
  );

  Future<ApiResult<void>> deleteProfile(String profileId) async {
    final result = await _caller.callNoContent(
      'deleteProfile',
      () => _profiles.deleteProfileWithHttpInfo(profileId),
    );
    if (result is Ok<void>) await _cache.removeProfile(profileId);
    return result;
  }

  Future<ApiResult<api.SoftPreferences>> replaceSoftPreferences(
    String profileId,
    api.SoftPreferencesInput body,
  ) => _caller.call(
    'replaceSoftPreferences',
    () => _preferences.replaceSoftPreferencesWithHttpInfo(profileId, body),
    decodeWith(api.SoftPreferences.fromJson, 'soft preferences'),
  );

  Future<ApiResult<api.LikesDislikes>> replaceLikesDislikes(
    String profileId,
    api.LikesDislikesInput body,
  ) => _caller.call(
    'replaceLikesDislikes',
    () => _preferences.replaceLikesDislikesWithHttpInfo(profileId, body),
    decodeWith(api.LikesDislikes.fromJson, 'likes and dislikes'),
  );
}

final profilesRepositoryProvider = Provider<ProfilesRepository>(
  (ref) => ProfilesRepository(
    caller: ref.watch(apiCallerProvider),
    client: ref.watch(apiClientProvider),
    cache: ref.watch(localCacheProvider),
  ),
);
