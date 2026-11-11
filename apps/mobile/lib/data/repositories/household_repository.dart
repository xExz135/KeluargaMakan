// The household (ACC-03, ACC-04, NFR-16). Cached on the phone so the name
// and time zone are known offline.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../../core/time/household_time.dart';
import '../decoders.dart';
import '../local_cache.dart';
import '../models/household.dart';

final class HouseholdRepository {
  HouseholdRepository({
    required this._caller,
    required api.ApiClient client,
    required this._cache,
    required this._onTimeZone,
  }) : _api = api.HouseholdApi(client);

  final ApiCaller _caller;
  final api.HouseholdApi _api;
  final LocalCache _cache;
  final void Function(HouseholdTimeZone?) _onTimeZone;

  /// The household from the API, or the cached copy when the API cannot be
  /// reached. `household_required` (409) means onboarding continues at O3.
  Future<ApiResult<HouseholdInfo>> getHousehold() async {
    final result = await _caller.call(
      'getHousehold',
      () => _api.getHouseholdWithHttpInfo(),
      decodeHousehold,
    );
    if (result case Err(failure: NetworkFailure())) {
      final cached = await _cache.household();
      if (cached != null) {
        _onTimeZone(cached.timeZone);
        return Ok(cached);
      }
    }
    return _remember(result);
  }

  /// Creates the household with the manager's profile (ACC-04). Reuse the
  /// same [idempotencyKey] when retrying the same request.
  Future<ApiResult<HouseholdInfo>> createHousehold(
    api.HouseholdCreate body, {
    required String idempotencyKey,
  }) async => _remember(
    await _caller.call(
      'createHousehold',
      () => _api.createHouseholdWithHttpInfo(
        body,
        idempotencyKey: idempotencyKey,
      ),
      decodeHousehold,
    ),
  );

  Future<ApiResult<HouseholdInfo>> updateHousehold(
    api.HouseholdUpdate body,
  ) async => _remember(
    await _caller.call(
      'updateHousehold',
      () => _api.updateHouseholdWithHttpInfo(body),
      decodeHousehold,
    ),
  );

  /// The cached household, for startup.
  Future<HouseholdInfo?> cached() async {
    final cached = await _cache.household();
    if (cached != null) _onTimeZone(cached.timeZone);
    return cached;
  }

  Future<ApiResult<HouseholdInfo>> _remember(
    ApiResult<HouseholdInfo> result,
  ) async {
    if (result case Ok(:final value)) {
      await _cache.saveHousehold(value);
      _onTimeZone(value.timeZone);
    }
    return result;
  }
}

final householdRepositoryProvider = Provider<HouseholdRepository>(
  (ref) => HouseholdRepository(
    caller: ref.watch(apiCallerProvider),
    client: ref.watch(apiClientProvider),
    cache: ref.watch(localCacheProvider),
    onTimeZone: ref.read(knownHouseholdTimeZoneProvider.notifier).set,
  ),
);
