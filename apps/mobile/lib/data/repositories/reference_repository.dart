// Public reference data: the standard allergen list (PRF-04), cached for
// offline use. The picker renders it in the API's order and never hard-codes
// it (contract-alignment.md 3).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../decoders.dart';
import '../local_cache.dart';
import '../models/household.dart';

final class ReferenceRepository {
  ReferenceRepository({
    required this._caller,
    required api.ApiClient client,
    required this._cache,
  }) : _api = api.ReferenceApi(client);

  final ApiCaller _caller;
  final api.ReferenceApi _api;
  final LocalCache _cache;

  Future<ApiResult<AllergenReference>> listStandardAllergens() async {
    final result = await _caller.call(
      'listStandardAllergens',
      () => _api.listStandardAllergensWithHttpInfo(),
      decodeAllergens,
    );
    switch (result) {
      case Ok(:final value):
        await _cache.saveAllergens(value);
      case Err(failure: NetworkFailure()):
        final cached = await _cache.allergens();
        if (cached != null) return Ok(cached);
      case Err():
        break;
    }
    return result;
  }
}

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => ReferenceRepository(
    caller: ref.watch(apiCallerProvider),
    client: ref.watch(apiClientProvider),
    cache: ref.watch(localCacheProvider),
  ),
);
