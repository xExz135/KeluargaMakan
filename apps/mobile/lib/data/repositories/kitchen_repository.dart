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
// - Item changes go through the sync (KIT-16): the queued changes and the
//   cursor in, the outcome of each change and what changed since out. The
//   request is bound to the account the changes belong to
//   ([runAsAccount]). Ingredient sets (KIT-08) are written online only.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../../core/api/auth_http_client.dart' show runAsAccount;
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

  /// Keeps [list] as the phone's copy for [accountId], with the cursor of
  /// the sync that gave it. Does nothing once that session is ending or
  /// over, or another account is signed in. Best effort.
  Future<void> saveCopy(
    KitchenList list, {
    required String accountId,
    required int epoch,
    String? cursor,
  }) => _cache.saveKitchen(
    list,
    accountId: accountId,
    epoch: epoch,
    cursor: cursor,
  );

  /// The phone's copy and its sync cursor, for the signed-in account.
  Future<({KitchenList list, String? cursor})?> cachedKitchen() =>
      _cache.kitchenWithCursor();

  /// KIT-16: sends [changes] (oldest first) with the [cursor] of the last
  /// sync and returns the outcome of each and what changed since. Sent only
  /// with [accountId]'s session; another account's session makes it a
  /// [NetworkFailure] without anything being sent.
  Future<ApiResult<KitchenSyncAnswer>> sync({
    required String accountId,
    required String? cursor,
    required List<api.KitchenChange> changes,
  }) {
    final sent = [for (final c in changes) c.changeId];
    return runAsAccount(
      accountId,
      () => _caller.call(
        'syncKitchen',
        () => _kitchen.syncKitchenWithHttpInfo(
          api.KitchenSyncRequest(cursor: cursor, changes: changes),
        ),
        (json) =>
            decodeSyncAnswer(json, sent: sent, cursorSent: cursor != null),
      ),
    );
  }

  // ------------------------------------------------------------ Sets

  /// KIT-08: the household's sets. Without an answer, the phone's copy.
  Future<ApiResult<IngredientSets>> listSets() async {
    final account = _currentAccountId();
    final epoch = _cache.epoch;
    final result = await _caller.call(
      'listIngredientSets',
      () => _kitchen.listIngredientSetsWithHttpInfo(),
      decodeIngredientSets,
    );
    switch (result) {
      case Ok(:final value) when account != null:
        await _cache.saveSets(value, accountId: account, epoch: epoch);
      case Err(failure: NetworkFailure()):
        final cached = await _cache.sets();
        if (cached != null) return Ok(cached);
      case _:
        break;
    }
    return result;
  }

  /// Keeps [sets] as the phone's copy (after a confirmed change).
  Future<void> saveSets(
    IngredientSets sets, {
    required String accountId,
    required int epoch,
  }) => _cache.saveSets(sets, accountId: accountId, epoch: epoch);

  // Set writes are sent only with [accountId]'s session, like the sync
  // (security review T-034 M1): a set name never reaches another
  // household's endpoint.

  Future<ApiResult<IngredientSetInfo>> createSet({
    required String accountId,
    required String name,
    required List<String> itemIds,
    required String idempotencyKey,
  }) => runAsAccount(
    accountId,
    () => _caller.call(
      'createIngredientSet',
      () => _kitchen.createIngredientSetWithHttpInfo(
        api.IngredientSetInput(name: name, itemIds: itemIds.toSet()),
        idempotencyKey: idempotencyKey,
      ),
      decodeIngredientSet,
    ),
  );

  /// Replaces the set's name and items; sending it again is safe.
  Future<ApiResult<IngredientSetInfo>> replaceSet(
    String setId, {
    required String accountId,
    required String name,
    required List<String> itemIds,
  }) => runAsAccount(
    accountId,
    () => _caller.call(
      'replaceIngredientSet',
      () => _kitchen.replaceIngredientSetWithHttpInfo(
        setId,
        api.IngredientSetInput(name: name, itemIds: itemIds.toSet()),
      ),
      decodeIngredientSet,
    ),
  );

  /// The items stay in the kitchen.
  Future<ApiResult<void>> deleteSet(
    String setId, {
    required String accountId,
  }) => runAsAccount(
    accountId,
    () => _caller.callNoContent(
      'deleteIngredientSet',
      () => _kitchen.deleteIngredientSetWithHttpInfo(setId),
    ),
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
