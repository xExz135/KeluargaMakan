// The saved kitchen as Dapur Saya shows it (KIT-01 to KIT-07), and the
// reference catalog kept for search (KIT-04).
//
// KIT-02 toggles are optimistic: the tapped item changes on screen at once
// (NFR-02, under 200 ms (target), measured in T-081) and the change is then
// sent. Per item at most one request is in flight; taps during it only move
// the wanted state, and the latest one is sent next, so the server ends on
// the last tap. A failure puts the item back to the state the server last
// confirmed and posts a [KitchenNotice]. There is no offline queue yet
// (T-034, QUESTIONS #68): without internet the item goes back and the
// notice says that internet is needed.
//
// Both states belong to one account: they are rebuilt empty when the
// session ends or another account signs in (currentAccountIdProvider,
// security review T-027 M1). An answer for the previous account is dropped
// and never written to the phone's copy.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../core/api/api_client.dart';
import '../core/api/api_problem.dart';
import '../core/api/api_result.dart';
import 'ingredient_search.dart' show foldIngredientName;
import 'models/kitchen.dart';
import 'models/sourced.dart';
import 'repositories/auth_repository.dart' show randomUuidV4;
import 'repositories/kitchen_repository.dart';

// ------------------------------------------------------------ Kitchen

sealed class KitchenState {
  const KitchenState();
}

final class KitchenLoading extends KitchenState {
  const KitchenLoading();
}

final class KitchenLoaded extends KitchenState {
  const KitchenLoaded(this.list, {this.sending = const {}});

  /// With the wanted state of items still being sent.
  final KitchenList list;

  /// IDs of items whose change is on its way to the server.
  final Set<String> sending;
}

final class KitchenLoadFailed extends KitchenState {
  const KitchenLoadFailed(this.failure);

  final ApiFailure failure;
}

/// A change that did not go through, for the screen to explain. Compared
/// by identity, so the same failure twice is shown twice.
final class KitchenNotice {
  KitchenNotice(this.entry, this.failure);

  /// The item as the server last confirmed it (its state was put back).
  final KitchenEntry entry;
  final ApiFailure failure;

  @override
  String toString() => 'KitchenNotice(${entry.id}, $failure)';
}

final class KitchenNotices extends Notifier<KitchenNotice?> {
  @override
  KitchenNotice? build() {
    ref.watch(currentAccountIdProvider);
    return null;
  }

  void post(KitchenNotice notice) => state = notice;
}

final kitchenNoticesProvider = NotifierProvider<KitchenNotices, KitchenNotice?>(
  KitchenNotices.new,
);

final class KitchenController extends Notifier<KitchenState> {
  @override
  KitchenState build() {
    final account = ref.watch(currentAccountIdProvider);
    // Nothing from the previous account survives (T-027 M1).
    _account = account;
    _epoch = ref.read(sessionManagerProvider).epoch;
    _loading = null;
    _generation++;
    _order = [];
    _confirmed = {};
    _wanted = {};
    _sending = {};
    _addKeys = {};
    _list = null;
    if (account != null) Future.microtask(reload);
    return const KitchenLoading();
  }

  String? _account;

  /// The session epoch this state belongs to (LocalCache, T-033 review).
  int _epoch = 0;
  Future<void>? _loading;
  int _generation = 0;

  /// The last list from the API or the phone's copy, without local changes.
  KitchenList? _list;
  List<String> _order = [];
  Map<String, KitchenEntry> _confirmed = {};
  Map<String, KitchenItemState> _wanted = {};
  Set<String> _sending = {};

  /// Idempotency keys of adds that got no answer, reused on the retry.
  Map<String, String> _addKeys = {};

  KitchenRepository get _repo => ref.read(kitchenRepositoryProvider);

  /// Loads the kitchen, showing [KitchenLoading] meanwhile. A reload asked
  /// for while one is running joins it.
  Future<void> reload() => _start(quiet: false);

  /// Reads the kitchen again, keeping the current list on screen.
  Future<void> refresh() async {
    final running = _loading;
    if (running != null) await running;
    if (!ref.mounted) return;
    await _start(quiet: true);
  }

  Future<void> _start({required bool quiet}) {
    final running = _loading;
    if (running != null) return running;
    late final Future<void> load;
    load = _load(quiet: quiet).whenComplete(() {
      if (identical(_loading, load)) _loading = null;
    });
    return _loading = load;
  }

  Future<void> _load({required bool quiet}) async {
    if (_account == null) return;
    final generation = _generation;
    if (!quiet || state is! KitchenLoaded) state = const KitchenLoading();
    ApiResult<KitchenList> result;
    try {
      result = await _repo.listItems();
    } on Object catch (e) {
      // Never left on the skeleton (security review T-033 M1). Only the
      // type is logged.
      debugPrint('Kitchen load failed (${e.runtimeType})');
      result = const Err(DecodeFailure('listKitchenItems'));
    }
    if (!_current(generation)) return;
    switch (result) {
      case Ok(:final value):
        _replace(value);
        _emit();
      case Err(:final failure):
        // A quiet refresh that fails keeps what is on screen.
        if (!quiet || _list == null) state = KitchenLoadFailed(failure);
    }
  }

  /// Still the same load and the same signed-in account. The session is
  /// asked directly: the account change reaches this provider only on its
  /// next rebuild.
  bool _current(int generation) {
    if (!ref.mounted || generation != _generation) return false;
    final session = ref.read(sessionManagerProvider);
    return !session.isEnding &&
        session.epoch == _epoch &&
        session.current?.accountId == _account;
  }

  void _replace(KitchenList list) {
    _list = list;
    _order = [for (final i in list.items) i.id];
    _confirmed = {for (final i in list.items) i.id: i};
    // An ingredient the server now shows needs no retried add: a later add
    // of it is a new action with a new key (security review T-033 L4).
    list.items.forEach(_forgetAddKeys);
    // Items gone from the server lose their pending wishes.
    _wanted.removeWhere((id, _) => !_confirmed.containsKey(id));
  }

  void _emit() {
    final list = _list;
    if (list == null) return;
    state = KitchenLoaded(
      list.copyWith(
        items: [
          for (final id in _order)
            if (_confirmed[id] case final item?)
              switch (_wanted[id]) {
                final wanted? when wanted != item.state => item.withState(
                  wanted,
                ),
                _ => item,
              },
        ],
      ),
      sending: Set.unmodifiable(_sending),
    );
  }

  /// The confirmed list, as kept on the phone.
  KitchenList? get _confirmedList =>
      _list?.copyWith(items: [for (final id in _order) ?_confirmed[id]]);

  Future<void> _saveCopy() async {
    final list = _confirmedList;
    final account = _account;
    if (list == null || account == null || list.source is! FromNetwork) {
      return;
    }
    await _repo.saveCopy(list, accountId: account, epoch: _epoch);
  }

  /// KIT-02: one tap switches [itemId] between available and out, on
  /// screen at once, then on the server.
  void toggle(String itemId) {
    final item = _confirmed[itemId];
    if (item == null || state is! KitchenLoaded) return;
    final shown = _wanted[itemId] ?? item.state;
    _wanted[itemId] = shown.flipped;
    _emit();
    _send(itemId);
  }

  Future<void> _send(String itemId) async {
    if (_sending.contains(itemId)) return; // The running loop sends it.
    final generation = _generation;
    _sending.add(itemId);
    _emit();
    var changed = false;
    while (true) {
      final wanted = _wanted[itemId];
      final have = _confirmed[itemId];
      if (wanted == null || have == null || wanted == have.state) break;
      final result = await _repo.setState(itemId, wanted);
      if (!_current(generation)) return;
      switch (result) {
        case Ok(:final value):
          _confirmed[itemId] = value;
          changed = true;
          if (value.state != wanted) {
            // The server kept another state (a newer state this app reads
            // as out, or a server rule). Its answer wins; nothing is sent
            // again until the next tap (security review T-033 L3).
            _wanted.remove(itemId);
          }
        case Err(:final failure):
          _wanted.remove(itemId);
          if (failure.problemCode == ApiErrorCode.notFound) {
            // Removed on another phone.
            _confirmed.remove(itemId);
            _order.remove(itemId);
            changed = true;
          }
          // An ended session has its own dialog (T-027).
          if (!failure.isSignedOut) {
            ref
                .read(kitchenNoticesProvider.notifier)
                .post(KitchenNotice(have, failure));
          }
      }
      if (result is Err || _wanted[itemId] == null) break;
    }
    _sending.remove(itemId);
    if (_wanted[itemId] == _confirmed[itemId]?.state) _wanted.remove(itemId);
    _emit();
    if (changed) await _afterWrite(generation);
  }

  /// After a confirmed write: keep the phone's copy current, and when the
  /// list on screen came from the phone, read the server's list again.
  Future<void> _afterWrite(int generation) async {
    if (!_current(generation)) return;
    if (_list?.source is FromCache) {
      await refresh();
    } else {
      await _saveCopy();
    }
  }

  /// Adds [ingredient] (KIT-04, KIT-05) as [state]. An ingredient already in
  /// the kitchen is not duplicated: the server returns the existing item
  /// with the requested state. The same request after no answer reuses its
  /// Idempotency-Key, so it cannot be added twice.
  Future<ApiResult<KitchenEntry>> add(
    IngredientKey ingredient, {
    api.KitchenCategory? category,
    KitchenItemState state = KitchenItemState.available,
  }) async {
    final generation = _generation;
    final requestId =
        '${_fingerprint(ingredient)}|${category?.toJson()}|${state.wire}';
    final key = _addKeys[requestId] ??= randomUuidV4();
    final result = await _repo.addItem(
      ingredient,
      category: category,
      state: state,
      idempotencyKey: key,
    );
    if (!_current(generation)) return result;
    switch (result) {
      case Ok(:final value):
        _addKeys.remove(requestId);
        if (!_confirmed.containsKey(value.id)) _order.add(value.id);
        _confirmed[value.id] = value;
        _wanted.remove(value.id);
        _emit();
        await _afterWrite(generation);
      case Err(failure: NetworkFailure()):
        break; // Same key on the retry.
      case Err():
        _addKeys.remove(requestId);
    }
    return result;
  }

  static String _fingerprint(IngredientKey ingredient) => switch (ingredient) {
    ReferenceIngredient(:final ingredientId) => 'r:$ingredientId',
    CustomIngredient(:final name) => 'c:${foldIngredientName(name)}',
  };

  /// Drops kept Idempotency-Keys of [item]'s ingredient: once it is in the
  /// list or removed, the add they belonged to is settled.
  void _forgetAddKeys(KitchenEntry item) {
    final prefix = '${_fingerprint(item.key)}|';
    _addKeys.removeWhere((requestId, _) => requestId.startsWith(prefix));
  }

  /// Removes [itemId] (KIT-01). Default staples can be removed too
  /// (KIT-07).
  Future<ApiResult<void>> remove(String itemId) async {
    final generation = _generation;
    final result = await _repo.removeItem(itemId);
    if (!_current(generation)) return result;
    final gone = switch (result) {
      Ok() => true,
      // Already removed on another phone.
      Err(:final failure) => failure.problemCode == ApiErrorCode.notFound,
    };
    if (gone) {
      if (_confirmed[itemId] case final removed?) _forgetAddKeys(removed);
      _confirmed.remove(itemId);
      _order.remove(itemId);
      _wanted.remove(itemId);
      _emit();
      await _afterWrite(generation);
    }
    return result;
  }
}

final kitchenProvider = NotifierProvider<KitchenController, KitchenState>(
  KitchenController.new,
);

// ------------------------------------------------------------ Catalog

sealed class CatalogState {
  const CatalogState();
}

final class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

/// A catalog to search: fresh, or the phone's copy without internet.
final class CatalogReady extends CatalogState {
  const CatalogReady(this.catalog);

  final IngredientCatalog catalog;
}

/// 503 `reference_data_unavailable`: the server has no verified reference
/// data right now. Never shown as "no results".
final class CatalogUnavailable extends CatalogState {
  const CatalogUnavailable();
}

/// No internet and no copy on this phone (`kitchen.search.offlineNoCache`).
final class CatalogMissing extends CatalogState {
  const CatalogMissing();
}

final class CatalogFailed extends CatalogState {
  const CatalogFailed(this.failure);

  final ApiFailure failure;
}

final class CatalogController extends Notifier<CatalogState> {
  @override
  CatalogState build() {
    final account = ref.watch(currentAccountIdProvider);
    _generation++;
    _loading = null;
    if (account != null) Future.microtask(refresh);
    return const CatalogLoading();
  }

  int _generation = 0;
  Future<void>? _loading;

  /// Downloads the catalog, or confirms the phone's copy (304). Joins a
  /// refresh that is already running.
  Future<void> refresh() {
    final running = _loading;
    if (running != null) return running;
    late final Future<void> load;
    load = _refresh().whenComplete(() {
      if (identical(_loading, load)) _loading = null;
    });
    return _loading = load;
  }

  Future<void> _refresh() async {
    final generation = _generation;
    final repo = ref.read(kitchenRepositoryProvider);
    if (state is! CatalogReady) {
      final cached = await repo.cachedCatalog();
      if (!ref.mounted || generation != _generation) return;
      if (cached != null) state = CatalogReady(cached);
    }
    final result = await repo.refreshCatalog();
    if (!ref.mounted || generation != _generation) return;
    state = switch (result) {
      Ok(:final value) => CatalogReady(value),
      Err(:final failure)
          when failure.problemCode == ApiErrorCode.referenceDataUnavailable =>
        const CatalogUnavailable(),
      Err(failure: NetworkFailure()) => const CatalogMissing(),
      Err(:final failure) => CatalogFailed(failure),
    };
  }
}

final catalogProvider = NotifierProvider<CatalogController, CatalogState>(
  CatalogController.new,
);
