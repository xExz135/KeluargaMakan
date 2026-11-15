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
    final epoch = _cache.epoch;
    final result = await _caller.call(
      'listKitchenItems',
      () => _kitchen.listKitchenItemsWithHttpInfo(),
      decodeKitchenList,
    );
    switch (result) {
      case Ok(:final value) when account != null:
        await _cache.saveKitchen(value, accountId: account, epoch: epoch);
      case Err(failure: NetworkFailure()):
        final cached = await _cache.kitchen();
        if (cached != null) return Ok(cached);
      case _:
        break;
    }
    return result;
  }

  /// The session epoch now, for [saveCopy] (LocalCache).
  int get sessionEpoch => _cache.epoch;

  /// Keeps [list] as the phone's copy for [accountId] (after a confirmed
  /// change). Does nothing once that session is ending or over, or another
  /// account is signed in. Best effort.
  Future<void> saveCopy(
    KitchenList list, {
    required String accountId,
    required int epoch,
  }) => _cache.saveKitchen(list, accountId: accountId, epoch: epoch);

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
  ///
  /// A 304 counts only as the answer to the tag that was sent: when nothing
  /// was sent, or the 304 names another tag, the catalog is downloaded once
  /// in full instead (security review T-033 L2).
  Future<ApiResult<IngredientCatalog>> refreshCatalog() async {
    final cached = await _cache.catalog();
    final sent = cached == null ? null : acceptableEtag(cached.etag);
    final result = await _download(sent);
    switch (result) {
      case Ok(value: Modified(:final value)):
        await _cache.saveCatalog(value);
        return Ok(value);
      case Ok(value: NotModified(:final etag)):
        final confirmed =
            cached != null && sent != null && (etag == null || etag == sent);
        if (confirmed) {
          await _cache.touchCatalog();
          return Ok(cached.withSource(const FromNetwork()));
        }
        // Not an answer to what was asked: one full download.
        final full = await _download(null);
        switch (full) {
          case Ok(value: Modified(:final value)):
            await _cache.saveCatalog(value);
            return Ok(value);
          case Ok(value: NotModified()):
            return const Err(DecodeFailure('listReferenceIngredients'));
          case Err(failure: NetworkFailure()) when cached != null:
            return Ok(cached);
          case Err(:final failure):
            return Err(failure);
        }
      case Err(failure: NetworkFailure()) when cached != null:
        return Ok(cached);
      case Err(:final failure):
        return Err(failure);
    }
  }

  Future<ApiResult<Conditional<IngredientCatalog>>> _download(
    String? ifNoneMatch,
  ) => _caller.callConditional(
    'listReferenceIngredients',
    () => _reference.listReferenceIngredientsWithHttpInfo(
      ifNoneMatch: ifNoneMatch,
    ),
    (json, etag) => decodeCatalog(json, etag: acceptableEtag(etag)),
  );

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
