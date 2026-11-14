// Dapur Saya: the saved kitchen (KIT-01 to KIT-07) and the reference
// ingredient catalog with search (KIT-04).
//
// - The kitchen is household data, not health data: it may be cached for
//   offline viewing, bound to the signed-in account (LocalCache).
// - The catalog is public reference data: it is cached with its ETag and
//   refreshed with `If-None-Match`, so an unchanged catalog costs a 304.
// - Search queries go only in a POST body (never in a URL) and are never
//   logged: ApiCaller logs the operation name only.
// - `reference_data_unavailable` (503) is returned as a failure, never as
//   an empty catalog or "no results".
//
// No offline queue yet (T-034, QUESTIONS #68): writes need the API.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../kitchen_decoders.dart';
import '../local_cache.dart';
import '../models/kitchen.dart';
import '../models/sourced.dart';

final class KitchenRepository {
  KitchenRepository({
    required this._caller,
    required api.ApiClient client,
    required this._cache,
    required this._currentAccountId,
  }) : _kitchen = api.KitchenApi(client),
       _reference = api.ReferenceApi(client);

  final ApiCaller _caller;
  final api.KitchenApi _kitchen;
  final api.ReferenceApi _reference;
  final LocalCache _cache;
  final String? Function() _currentAccountId;

  // ------------------------------------------------------------ Kitchen

  /// The saved kitchen. Only when the API cannot be reached, the copy on
  /// this phone is returned (for the same account only).
  Future<ApiResult<KitchenList>> listItems() async {
    final account = _currentAccountId();
    final result = await _caller.call(
      'listKitchenItems',
      () => _kitchen.listKitchenItemsWithHttpInfo(),
      decodeKitchenList,
    );
    switch (result) {
      case Ok(:final value) when account != null:
        await _cache.saveKitchen(value, accountId: account);
      case Err(failure: NetworkFailure()):
        final cached = await _cache.kitchen();
        if (cached != null) return Ok(cached);
      case _:
        break;
    }
    return result;
  }

  /// Keeps [list] as the phone's copy for [accountId] (after a confirmed
  /// change). Does nothing once another account is signed in.
  Future<void> saveCopy(KitchenList list, {required String accountId}) =>
      _cache.saveKitchen(list, accountId: accountId);

  /// Adds a reference ingredient (KIT-04) or a custom one (KIT-05). A custom
  /// one needs [category]; a reference one needs it only when the catalog
  /// gives none. Reuse [idempotencyKey] when retrying after no answer.
  Future<ApiResult<KitchenEntry>> addItem(
    IngredientKey ingredient, {
    required api.KitchenCategory? category,
    required KitchenItemState state,
    required String idempotencyKey,
  }) {
    final body = switch (ingredient) {
      ReferenceIngredient(:final ingredientId) => api.KitchenItemCreate(
        ingredientId: api.Optional.present(ingredientId),
        category: category == null
            ? const api.Optional.absent()
            : api.Optional.present(category),
        state: api.Optional.present(state.toApi()),
      ),
      CustomIngredient(:final name) => api.KitchenItemCreate(
        customName: api.Optional.present(name),
        category: api.Optional.present(category),
        state: api.Optional.present(state.toApi()),
      ),
    };
    return _caller.call(
      'addKitchenItem',
      () => _kitchen.addKitchenItemWithHttpInfo(
        body,
        idempotencyKey: idempotencyKey,
      ),
      decodeKitchenItem,
    );
  }

  /// KIT-02: sets the item's state. Sending the same state again leaves the
  /// same result (contract).
  Future<ApiResult<KitchenEntry>> setState(
    String itemId,
    KitchenItemState state,
  ) => _caller.call(
    'updateKitchenItem',
    () => _kitchen.updateKitchenItemWithHttpInfo(
      itemId,
      api.KitchenItemUpdate(state: api.Optional.present(state.toApi())),
    ),
    decodeKitchenItem,
  );

  Future<ApiResult<void>> removeItem(String itemId) => _caller.callNoContent(
    'removeKitchenItem',
    () => _kitchen.removeKitchenItemWithHttpInfo(itemId),
  );

  // ------------------------------------------------------------ Catalog

  /// The catalog on this phone, if any.
  Future<IngredientCatalog?> cachedCatalog() => _cache.catalog();

  /// Downloads the catalog, or confirms the phone's copy with
  /// `If-None-Match` (304). Without an answer the phone's copy is returned
  /// as [FromCache]. A 503 `reference_data_unavailable` is a failure even
  /// when a copy exists: the server cannot vouch for it now.
  Future<ApiResult<IngredientCatalog>> refreshCatalog() async {
    final cached = await _cache.catalog();
    final etag = acceptableEtag(cached?.etag);
    final result = await _caller.callConditional(
      'listReferenceIngredients',
      () => _reference.listReferenceIngredientsWithHttpInfo(ifNoneMatch: etag),
      (json, etag) => decodeCatalog(json, etag: acceptableEtag(etag)),
    );
    switch (result) {
      case Ok(value: Modified(:final value)):
        await _cache.saveCatalog(value);
        return Ok(value);
      case Ok(value: NotModified()):
        if (cached == null) {
          // A 304 without a copy to confirm: the server's answer does not
          // fit the request. Fail closed rather than show nothing.
          return const Err(DecodeFailure('listReferenceIngredients'));
        }
        await _cache.touchCatalog();
        return Ok(cached.withSource(const FromNetwork()));
      case Err(failure: NetworkFailure()) when cached != null:
        return Ok(cached);
      case Err(:final failure):
        return Err(failure);
    }
  }

  /// KIT-04: searches the reference ingredients by name or local name. The
  /// query travels only in the request body.
  Future<ApiResult<List<IngredientHit>>> search(String query) => _caller.call(
    'searchReferenceIngredients',
    () => _reference.searchReferenceIngredientsWithHttpInfo(
      api.IngredientSearchRequest(query: query),
    ),
    decodeSearchResult,
  );
}

final kitchenRepositoryProvider = Provider<KitchenRepository>(
  (ref) => KitchenRepository(
    caller: ref.watch(apiCallerProvider),
    client: ref.watch(apiClientProvider),
    cache: ref.watch(localCacheProvider),
    currentAccountId: () => ref.read(sessionManagerProvider).current?.accountId,
  ),
);
