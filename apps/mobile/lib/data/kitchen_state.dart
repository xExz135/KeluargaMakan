// The saved kitchen as Dapur Saya shows it (KIT-01 to KIT-09), with the
// offline queue and sync (KIT-16, SRS 19.4), and the reference catalog kept
// for search (KIT-04).
//
// Every edit (a tap, an add, a removal, an amount or a brand, "Tandai semua
// ada") goes the same way, with or without internet:
// 1. It shows on screen at once, from local state (NFR-02, under 200 ms
//    (target), measured in T-081).
// 2. It is queued on the phone with a stable change ID and the time it was
//    made (lib/sync/kitchen_change.dart), collapsed per ingredient where the
//    result is the same, and kept across restarts (LocalCache outbox).
// 3. The sync sends the queue, oldest first, with the cursor of the last
//    sync, and applies what the server answers: the latest change wins per
//    ingredient on the server's clock. Applied changes leave the queue; a
//    change that lost to a newer one shows the server's item and says so;
//    a change refused for good goes back with a message; a change refused
//    for now stays queued and is sent again with the same change ID.
// 4. Without an answer, the queue stays, the screen says "Belum terkirim",
//    and the sync is tried again with backoff and jitter (lib/sync/
//    backoff.dart), when the connection returns and when the app resumes.
// A change older than the server accepts (kitchen.sync.maxChangeAgeHours)
// is dropped with a message instead of being sent forever.
//
// The screen shows the server's last confirmed items with the queued
// changes applied on top, in order. Nothing here is a safety result: a
// custom item or a typed brand only carries what Cek Aman turns into "Cek
// label" (SAF-07, SAF-09), and the app never derives a safety state.
//
// Everything belongs to one account: the state is rebuilt empty when the
// session ends or another account signs in (currentAccountIdProvider,
// security review T-027 M1); answers for the previous session are dropped;
// the queue is read, written and sent only for its own account (LocalCache,
// runAsAccount).

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../core/api/api_client.dart';
import '../core/api/api_problem.dart';
import '../core/api/api_result.dart';
import '../core/config/app_config.dart';
import '../core/config/config_keys.dart';
import '../sync/backoff.dart';
import '../sync/device_clock.dart';
import '../sync/kitchen_change.dart';
import '../sync/sync_signals.dart';
import 'local_cache.dart';
import 'models/kitchen.dart';
import 'models/sourced.dart';
import 'repositories/auth_repository.dart' show randomUuidV4;
import 'repositories/kitchen_repository.dart';

// ------------------------------------------------------------ State

sealed class KitchenState {
  const KitchenState();
}

final class KitchenLoading extends KitchenState {
  const KitchenLoading();
}

/// Why queued changes are still waiting.
enum KitchenSyncProblem {
  /// No answer from the API: no connection.
  offline,

  /// The API answered with an error, or refused changes for now.
  failed,
}

@immutable
final class KitchenSyncStatus {
  const KitchenSyncStatus({
    this.pendingCount = 0,
    this.sending = false,
    this.problem,
  });

  /// Changes on this phone the server has not confirmed yet.
  final int pendingCount;

  /// A sync is on its way.
  final bool sending;

  /// Why the last sync did not go through; null when it did.
  final KitchenSyncProblem? problem;

  bool get isSaved => pendingCount == 0 && !sending;

  @override
  bool operator ==(Object other) =>
      other is KitchenSyncStatus &&
      other.pendingCount == pendingCount &&
      other.sending == sending &&
      other.problem == problem;

  @override
  int get hashCode => Object.hash(pendingCount, sending, problem);

  @override
  String toString() =>
      'KitchenSyncStatus($pendingCount, sending: $sending, $problem)';
}

final class KitchenLoaded extends KitchenState {
  const KitchenLoaded(
    this.list, {
    this.pending = const {},
    this.sync = const KitchenSyncStatus(),
  });

  /// The server's items with the queued changes applied.
  final KitchenList list;

  /// IDs of items with a change the server has not confirmed yet.
  final Set<String> pending;
  final KitchenSyncStatus sync;
}

final class KitchenLoadFailed extends KitchenState {
  const KitchenLoadFailed(this.failure);

  final ApiFailure failure;
}

// ------------------------------------------------------------ Notices

/// Something the screen should tell the user about the sync. Compared by
/// identity, so the same event twice is shown twice.
sealed class KitchenNotice {
  const KitchenNotice();
}

/// A change was refused for good and taken back. [item] is the ingredient
/// as the server has it, or null when it has none; [ingredient] names it.
final class KitchenChangeRefused extends KitchenNotice {
  const KitchenChangeRefused(this.ingredient, this.item, this.errorCode);

  final IngredientKey ingredient;
  final KitchenEntry? item;
  final String errorCode;

  @override
  String toString() => 'KitchenChangeRefused($errorCode)';
}

/// An add was refused because the kitchen is full.
final class KitchenLimitReached extends KitchenNotice {
  const KitchenLimitReached(this.maxItems);

  final int maxItems;

  @override
  String toString() => 'KitchenLimitReached($maxItems)';
}

/// A newer change from another phone won over a change made here
/// (`kitchen.sync.overwritten`).
final class KitchenOverwritten extends KitchenNotice {
  const KitchenOverwritten(this.ingredient, this.item);

  final IngredientKey ingredient;
  final KitchenEntry? item;

  @override
  String toString() => 'KitchenOverwritten()';
}

/// Changes older than the server accepts were dropped, not sent.
final class KitchenChangesExpired extends KitchenNotice {
  const KitchenChangesExpired(this.count, {required this.maxAgeHours});

  final int count;
  final int maxAgeHours;

  @override
  String toString() => 'KitchenChangesExpired($count)';
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

// ------------------------------------------------------------ Edits

/// What an add did.
sealed class KitchenAddResult {
  const KitchenAddResult();
}

/// Shown at once and queued (or already in the kitchen, now with that
/// state).
final class KitchenAdded extends KitchenAddResult {
  const KitchenAdded(this.item);

  final KitchenEntry item;
}

/// The kitchen is at its limit; nothing was queued.
final class KitchenAddAtLimit extends KitchenAddResult {
  const KitchenAddAtLimit(this.maxItems);

  final int maxItems;
}

/// Nothing to add to: the kitchen is not loaded.
final class KitchenAddUnavailable extends KitchenAddResult {
  const KitchenAddUnavailable();
}

/// Rejection codes that can pass later (contract: "not remembered, send it
/// again with the same changeId"). Codes this app does not know count as
/// temporary too: the change waits, and the age limit is the last bound.
/// `kitchen_item_limit_reached` is handled on its own: the user has to free
/// space, so the add goes back with a message.
bool _isTemporary(String code) => switch (code) {
  'reference_data_unavailable' ||
  'service_unavailable' ||
  'internal_error' ||
  'rate_limited' => true,
  _ => ApiErrorCode.fromWire(code) == ApiErrorCode.internalError,
};

/// What a sync pass ended with.
enum _Pass { done, more, failed, stopped }

// ------------------------------------------------------------ Controller

final class KitchenController extends Notifier<KitchenState> {
  @override
  KitchenState build() {
    final account = ref.watch(currentAccountIdProvider);
    // Nothing from the previous account survives (T-027 M1).
    _account = account;
    _epoch = ref.read(sessionManagerProvider).epoch;
    _generation++;
    _loading = null;
    _syncing = null;
    _again = false;
    _list = null;
    _order = [];
    _confirmed = {};
    _cursor = null;
    _queue = [];
    _inFlight = {};
    _localIds = {};
    _persist = Future.value();
    _failures = 0;
    _isolate = 0;
    _problem = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    if (account == null) return const KitchenLoading();

    final online = ref.read(connectivitySignalProvider).changes.listen((up) {
      if (up) _comeBack();
    });
    final resumed = ref.read(appResumeSignalProvider).resumed.listen((_) {
      _comeBack();
    });
    ref.onDispose(() {
      online.cancel();
      resumed.cancel();
      _retryTimer?.cancel();
      _retryTimer = null;
    });
    Future.microtask(reload);
    return const KitchenLoading();
  }

  String? _account;

  /// The session epoch this state belongs to (LocalCache, T-033 review).
  int _epoch = 0;
  int _generation = 0;
  Future<void>? _loading;
  Future<ApiFailure?>? _syncing;
  bool _again = false;

  /// The last list from the API or the phone's copy, without local changes.
  KitchenList? _list;
  List<String> _order = [];
  Map<String, KitchenEntry> _confirmed = {};
  String? _cursor;

  /// Queued changes, oldest first (also on the phone, LocalCache outbox).
  List<QueuedChange> _queue = [];

  /// Change IDs of the sync on its way. They are never collapsed.
  Set<String> _inFlight = {};

  /// Screen IDs of items added here that the server has not confirmed, per
  /// ingredient key, so an item keeps its ID until the server's arrives.
  Map<String, String> _localIds = {};

  /// Queue writes, in order. A sync waits for it, so every change it sends
  /// is stamped and stored first.
  Future<void> _persist = Future.value();
  int _seq = 0;

  int _failures = 0;

  /// After a whole request was refused (400), this many passes send one
  /// change each, to find the one that cannot be stored.
  int _isolate = 0;
  KitchenSyncProblem? _problem;
  Timer? _retryTimer;

  KitchenRepository get _repo => ref.read(kitchenRepositoryProvider);
  LocalCache get _cache => ref.read(localCacheProvider);
  AppConfig get _config => ref.read(appConfigProvider);

  // ---------------------------------------------------------- loading

  /// Loads the kitchen: the phone's copy and queue first (shown at once),
  /// then a sync. A reload asked for while one is running joins it.
  Future<void> reload() {
    final running = _loading;
    if (running != null) return running;
    late final Future<void> load;
    load = _load().whenComplete(() {
      if (identical(_loading, load)) _loading = null;
    });
    return _loading = load;
  }

  /// Sends the queue and fetches changes from other phones, keeping the
  /// list on screen (pull to refresh). Loads first if nothing is shown.
  Future<void> refresh() async {
    final running = _loading;
    if (running != null) await running;
    if (!ref.mounted) return;
    if (_list == null) return reload();
    _failures = 0;
    await _sync();
  }

  /// "Kirim sekarang": tries the sync now, whatever the backoff says.
  Future<void> syncNow() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    _failures = 0;
    if (_list == null) return reload();
    await _sync();
  }

  /// The connection came back or the app resumed.
  void _comeBack() {
    if (!ref.mounted || _account == null) return;
    if (_list == null) {
      if (state is KitchenLoadFailed) unawaited(reload());
      return;
    }
    if (_queue.isEmpty && _problem == null) return;
    unawaited(syncNow());
  }

  Future<void> _load() async {
    if (_account == null) return;
    final generation = _generation;
    if (_list == null) {
      if (state is! KitchenLoaded) state = const KitchenLoading();
      final cached = await _repo.cachedKitchen();
      final queued = await _cache.outbox();
      if (!_current(generation)) return;
      if (queued != null && _queue.isEmpty) {
        _queue = [
          for (final c in queued)
            QueuedChange(
              seq: ++_seq,
              changeId: c.changeId,
              ingredient: c.ingredient,
              op: c.op,
              patch: c.patch,
              stamp: c.stamp,
            ),
        ];
      }
      if (cached != null) {
        _cursor = cached.cursor;
        _replace(cached.list, full: true);
        _emit();
      }
    }
    final failure = await _sync(initial: true);
    if (!_current(generation)) return;
    if (_list == null) {
      state = KitchenLoadFailed(failure ?? const DecodeFailure('syncKitchen'));
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

  // ---------------------------------------------------------- the list

  /// Takes [list] as the server's items: the whole kitchen when [full],
  /// otherwise the items changed since the last sync and [removed].
  void _replace(
    KitchenList list, {
    required bool full,
    List<String> removed = const [],
  }) {
    if (full || _list == null) {
      _order = [for (final i in list.items) i.id];
      _confirmed = {for (final i in list.items) i.id: i};
    } else {
      for (final item in list.items) {
        if (!_confirmed.containsKey(item.id)) _order.add(item.id);
        _confirmed[item.id] = item;
      }
      for (final id in removed) {
        _confirmed.remove(id);
        _order.remove(id);
      }
    }
    _list = list.copyWith(items: const []);
    final known = {for (final i in _confirmed.values) i.ingredientKey};
    _localIds.removeWhere((key, _) => known.contains(key));
  }

  /// The server's items in order, without local changes.
  List<KitchenEntry> get _confirmedItems => [
    for (final id in _order) ?_confirmed[id],
  ];

  /// The server's items with the queued changes applied, in order; items
  /// added here come last.
  List<KitchenEntry> _shownItems() {
    final byKey = <String, KitchenEntry>{
      for (final item in _confirmedItems) item.ingredientKey: item,
    };
    for (final change in _queue) {
      final key = change.key;
      if (change.op == KitchenChangeOp.remove) {
        byKey.remove(key);
        continue;
      }
      final base = byKey[key] ?? _localItem(change);
      byKey[key] = change.patch.applyTo(base, change.editedAt);
    }
    return byKey.values.toList();
  }

  KitchenEntry _localItem(QueuedChange change) {
    final id = _localIds.putIfAbsent(
      change.key,
      () => '${KitchenEntry.localIdPrefix}${change.changeId}',
    );
    final (ingredientId, customName) = switch (change.ingredient) {
      ReferenceIngredient(:final ingredientId) => (ingredientId, null),
      CustomIngredient(:final name) => (null, name),
    };
    final catalog = switch (ref.read(catalogProvider)) {
      CatalogReady(:final catalog) => catalog,
      _ => null,
    };
    final category =
        change.patch.category ??
        (ingredientId == null ? null : catalog?.byId(ingredientId)?.category) ??
        api.KitchenCategory.leftovers;
    return KitchenEntry(
      id: id,
      ingredientId: ingredientId,
      displayName: null,
      customName: customName,
      category: category,
      state: KitchenItemState.available,
      isDefaultStaple: false,
      usageRank: null,
      changedAt: change.editedAt,
      createdAt: change.editedAt,
    );
  }

  KitchenEntry? _shownById(String itemId) {
    final state = this.state;
    if (state is! KitchenLoaded) return null;
    return state.list.byId(itemId);
  }

  KitchenEntry? _shownByKey(String key) {
    final state = this.state;
    if (state is! KitchenLoaded) return null;
    return state.list.items.where((i) => i.ingredientKey == key).firstOrNull;
  }

  void _emit() {
    final list = _list;
    if (list == null || !ref.mounted) return;
    final items = _shownItems();
    final queuedKeys = {for (final c in _queue) c.key};
    state = KitchenLoaded(
      list.copyWith(items: items),
      pending: {
        for (final item in items)
          if (queuedKeys.contains(item.ingredientKey)) item.id,
      },
      sync: KitchenSyncStatus(
        pendingCount: _queue.length,
        sending: _inFlight.isNotEmpty,
        problem: _problem,
      ),
    );
  }

  // ---------------------------------------------------------- edits

  /// KIT-02: one tap switches [itemId] between available and out, on
  /// screen at once, then queued for the server.
  void toggle(String itemId) {
    final item = _shownById(itemId);
    if (item == null) return;
    _enqueue(
      item.key,
      KitchenChangeOp.upsert,
      KitchenPatch(state: item.state.flipped),
    );
  }

  /// KIT-09: sets or clears (null) the amount.
  void setQuantity(String itemId, KitchenAmount? amount) {
    final item = _shownById(itemId);
    if (item == null || item.quantity == amount) return;
    _enqueue(
      item.key,
      KitchenChangeOp.upsert,
      KitchenPatch(quantity: SetTo(amount)),
    );
  }

  /// KIT-09, SAF-07: sets or clears (null) the brand. A [ReferenceBrand]
  /// must be one of the ingredient's catalog brands; the server checks it,
  /// and a custom ingredient takes a typed brand only.
  void setBrand(String itemId, KitchenBrand? brand) {
    final item = _shownById(itemId);
    if (item == null || item.brand == brand) return;
    if (brand is ReferenceBrand && item.isCustom) return;
    _enqueue(
      item.key,
      KitchenChangeOp.upsert,
      KitchenPatch(brand: SetTo(brand)),
    );
  }

  /// Adds [ingredient] (KIT-04, KIT-05) as [state] with [category] (the
  /// catalog's, or the one picked). An ingredient already in the kitchen is
  /// not duplicated: it takes [state].
  KitchenAddResult add(
    IngredientKey ingredient, {
    required api.KitchenCategory? category,
    KitchenItemState state = KitchenItemState.available,
  }) {
    final current = this.state;
    final list = _list;
    if (current is! KitchenLoaded || list == null) {
      return const KitchenAddUnavailable();
    }
    final key = ingredientKeyOf(ingredient);
    final existing = _shownByKey(key);
    if (existing == null && current.list.items.length >= list.maxItems) {
      return KitchenAddAtLimit(list.maxItems);
    }
    _enqueue(
      ingredient,
      KitchenChangeOp.upsert,
      KitchenPatch(category: existing == null ? category : null, state: state),
    );
    final added = _shownByKey(key);
    return added == null ? const KitchenAddUnavailable() : KitchenAdded(added);
  }

  /// Removes [itemId] (KIT-01; default staples too, KIT-07) and returns the
  /// item as it was, for Undo ([restore]).
  KitchenEntry? remove(String itemId) {
    final item = _shownById(itemId);
    if (item == null) return null;
    _enqueue(item.key, KitchenChangeOp.remove, const KitchenPatch());
    return item;
  }

  /// Undo of [remove]: puts the item back as it was.
  void restore(KitchenEntry item) =>
      _enqueue(item.key, KitchenChangeOp.upsert, KitchenPatch.snapshotOf(item));

  /// KIT-08 "Tandai semua ada": every item of [itemIds] still in the
  /// kitchen becomes available; nothing becomes out. Returns the earlier
  /// states of the items that changed, for Undo ([restoreStates]).
  Map<String, KitchenItemState> markAvailable(Iterable<String> itemIds) {
    final changed = <String, KitchenItemState>{};
    for (final id in itemIds) {
      final item = _shownById(id);
      if (item == null || item.isAvailable) continue;
      changed[id] = item.state;
      _enqueue(
        item.key,
        KitchenChangeOp.upsert,
        const KitchenPatch(state: KitchenItemState.available),
        sync: false,
      );
    }
    if (changed.isNotEmpty) _scheduleSync();
    return changed;
  }

  /// Undo of [markAvailable].
  void restoreStates(Map<String, KitchenItemState> states) {
    for (final MapEntry(key: id, value: wanted) in states.entries) {
      final item = _shownById(id);
      if (item == null || item.state == wanted) continue;
      _enqueue(
        item.key,
        KitchenChangeOp.upsert,
        KitchenPatch(state: wanted),
        sync: false,
      );
    }
    _scheduleSync();
  }

  void _enqueue(
    IngredientKey ingredient,
    KitchenChangeOp op,
    KitchenPatch patch, {
    bool sync = true,
  }) {
    final account = _account;
    if (account == null || _list == null) return;
    final epoch = _epoch;
    // The time of the edit is read now, before anything waits.
    final stamp = ref.read(deviceClockProvider).read();
    final draft = QueuedChange(
      seq: ++_seq,
      changeId: randomUuidV4(),
      ingredient: ingredient,
      op: op,
      patch: patch,
      stamp: ClockReading(
        timeline: QueuedChange.pendingTimeline,
        elapsedMs: 0,
        wallMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    final replaced = changesReplacedBy(draft, _queue, inFlight: _inFlight);
    _queue = [
      for (final c in _queue)
        if (!replaced.contains(c.changeId)) c,
      draft,
    ];
    _emit();
    final generation = _generation;
    _persist = _persist.then((_) async {
      ClockReading reading;
      try {
        reading = await stamp;
      } on Object catch (e) {
        debugPrint('Clock read failed (${e.runtimeType})');
        reading = ClockReading(
          timeline: 'wall',
          elapsedMs: 0,
          wallMs: draft.stamp.wallMs,
        );
      }
      if (!_current(generation)) return;
      final stamped = QueuedChange(
        seq: draft.seq,
        changeId: draft.changeId,
        ingredient: draft.ingredient,
        op: draft.op,
        patch: draft.patch,
        stamp: reading,
      );
      final index = _queue.indexWhere((c) => c.changeId == draft.changeId);
      if (index < 0) {
        // Already replaced by a later change: only the replaced rows go.
        await _cache.unqueueKitchenChanges(replaced);
        return;
      }
      _queue[index] = stamped;
      await _cache.queueKitchenChange(
        stamped,
        replacing: replaced,
        accountId: account,
        epoch: epoch,
      );
    });
    if (sync) _scheduleSync();
  }

  void _scheduleSync() {
    // A backoff in progress decides when to try again.
    if (_retryTimer != null) return;
    scheduleMicrotask(() {
      if (ref.mounted) unawaited(_sync());
    });
  }

  // ---------------------------------------------------------- sync

  /// Runs the sync, or joins the one running (which then runs once more
  /// for changes made meanwhile). Returns the last pass's failure, if any.
  Future<ApiFailure?> _sync({bool initial = false}) {
    if (_account == null || (_list == null && !initial)) {
      return Future.value();
    }
    final running = _syncing;
    if (running != null) {
      _again = true;
      return running;
    }
    final generation = _generation;
    late final Future<ApiFailure?> pass;
    pass = _passes(generation).whenComplete(() {
      if (identical(_syncing, pass)) _syncing = null;
    });
    return _syncing = pass;
  }

  Future<ApiFailure?> _passes(int generation) async {
    while (true) {
      _again = false;
      final (outcome, failure) = await _pass(generation);
      if (!_current(generation)) return failure;
      switch (outcome) {
        case _Pass.more:
          continue;
        case _Pass.done when _again && _queue.isNotEmpty:
          continue;
        case _Pass.done || _Pass.failed || _Pass.stopped:
          return failure;
      }
    }
  }

  Future<(_Pass, ApiFailure?)> _pass(int generation) async {
    final account = _account;
    if (account == null) return (_Pass.stopped, null);
    await _persist;
    if (!_current(generation)) return (_Pass.stopped, null);

    final now = await ref.read(deviceClockProvider).read();
    if (!_current(generation)) return (_Pass.stopped, null);
    _dropExpired(now);

    final size = _isolate > 0
        ? 1
        : min(100, max(1, _config.get(ConfigKeys.kitchenSyncBatchSize)));
    // A change made while the clock was read has no stamp yet: it waits
    // for the next pass instead of being sent or expired with the phone's
    // uptime as its age (security review T-034 L1). Stamps arrive in queue
    // order, so unstamped changes are always at the end.
    final batch = _queue.takeWhile((c) => c.isStamped).take(size).toList();
    _inFlight = {for (final c in batch) c.changeId};
    _emit();
    final result = await _repo.sync(
      accountId: account,
      cursor: _cursor,
      changes: [
        for (final c in batch) c.toApi(ageMs: ageBetween(c.stamp, now)),
      ],
    );
    if (!_current(generation)) return (_Pass.stopped, null);
    _inFlight = {};
    if (_isolate > 0) _isolate--;

    switch (result) {
      case Ok(:final value):
        final waiting = _apply(value, batch);
        await _saveCopy();
        if (!_current(generation)) return (_Pass.stopped, null);
        if (waiting) {
          _problem = KitchenSyncProblem.failed;
          _emit();
          _scheduleRetry();
          return (_Pass.failed, null);
        }
        _problem = null;
        _failures = 0;
        _emit();
        final more = _queue.any((c) => !batch.contains(c));
        return (more ? _Pass.more : _Pass.done, null);
      case Err(:final failure):
        return _failed(failure, batch);
    }
  }

  (_Pass, ApiFailure?) _failed(ApiFailure failure, List<QueuedChange> batch) {
    if (failure.isSignedOut) {
      // The session ended; its own dialog explains it (T-027).
      _emit();
      return (_Pass.stopped, failure);
    }
    if (failure is ProblemFailure &&
        failure.code == ApiErrorCode.validationFailed &&
        failure.problem.status == 400 &&
        batch.isNotEmpty) {
      if (batch.length > 1) {
        // One change the server cannot read refuses the whole request:
        // send them one by one to find it.
        _isolate = batch.length;
      } else {
        _reject(batch.single, ApiErrorCode.validationFailed.wire);
      }
      _emit();
      return (_Pass.more, failure);
    }
    _problem = failure is NetworkFailure
        ? KitchenSyncProblem.offline
        : KitchenSyncProblem.failed;
    _emit();
    final retryAfter = switch (failure) {
      ProblemFailure(:final problem) => problem.retryAfterSeconds,
      _ => null,
    };
    _scheduleRetry(
      atLeast: retryAfter == null ? null : Duration(seconds: retryAfter),
    );
    return (_Pass.failed, failure);
  }

  /// Applies a sync answer: the server's items first, then each change's
  /// outcome. True when changes were refused for now and wait for a retry.
  bool _apply(KitchenSyncAnswer answer, List<QueuedChange> batch) {
    _replace(
      KitchenList(
        items: answer.items,
        maxItems: answer.maxItems,
        referenceVersion: answer.referenceVersion,
        source: const FromNetwork(),
      ),
      full: answer.full,
      removed: answer.removedItemIds,
    );
    _cursor = answer.cursor;

    final done = <String>{};
    var waiting = false;
    final notices = <KitchenNotice>[];
    for (final (i, result) in answer.results.indexed) {
      final change = batch[i];
      switch (result.outcome) {
        case KitchenSyncOutcome.applied:
          done.add(change.changeId);
        case KitchenSyncOutcome.superseded:
          done.add(change.changeId);
          final server = _confirmedByKey(change.key);
          final later = _queue.any(
            (c) => c.key == change.key && c.seq > change.seq,
          );
          if (!later && !_matches(change, server)) {
            notices.add(KitchenOverwritten(change.ingredient, server));
          }
        case KitchenSyncOutcome.rejected:
          final code = result.errorCode ?? ApiErrorCode.internalError.wire;
          if (code == ApiErrorCode.kitchenItemLimitReached.wire) {
            _dropFor(change, done);
            notices.add(KitchenLimitReached(answer.maxItems));
          } else if (_isTemporary(code)) {
            waiting = true;
          } else {
            _dropFor(change, done);
            notices.add(
              KitchenChangeRefused(
                change.ingredient,
                _confirmedByKey(change.key),
                code,
              ),
            );
          }
      }
    }
    _unqueue(done);
    for (final notice in notices) {
      ref.read(kitchenNoticesProvider.notifier).post(notice);
    }
    return waiting;
  }

  /// Whether the server's [item] already is what [change] asked for, so a
  /// superseded change needs no message.
  static bool _matches(QueuedChange change, KitchenEntry? item) {
    if (change.op == KitchenChangeOp.remove) return item == null;
    if (item == null) return false;
    final patch = change.patch;
    return (patch.state == null || patch.state == item.state) &&
        (patch.category == null || patch.category == item.category) &&
        switch (patch.quantity) {
          SetTo(:final value) => value == item.quantity,
          Keep() => true,
        } &&
        switch (patch.brand) {
          SetTo(:final value) => value == item.brand,
          Keep() => true,
        };
  }

  KitchenEntry? _confirmedByKey(String key) =>
      _confirmedItems.where((i) => i.ingredientKey == key).firstOrNull;

  /// Drops [change], and when the server has no item for its ingredient,
  /// every other queued change for it too: they cannot apply either.
  void _dropFor(QueuedChange change, Set<String> done) {
    done.add(change.changeId);
    if (_confirmedByKey(change.key) == null) {
      for (final c in _queue) {
        if (c.key == change.key && !_inFlight.contains(c.changeId)) {
          done.add(c.changeId);
        }
      }
    }
  }

  void _reject(QueuedChange change, String code) {
    final done = <String>{};
    _dropFor(change, done);
    _unqueue(done);
    ref
        .read(kitchenNoticesProvider.notifier)
        .post(
          KitchenChangeRefused(
            change.ingredient,
            _confirmedByKey(change.key),
            code,
          ),
        );
  }

  void _unqueue(Set<String> changeIds) {
    if (changeIds.isEmpty) return;
    _queue = [
      for (final c in _queue)
        if (!changeIds.contains(c.changeId)) c,
    ];
    final ids = changeIds.toList();
    _persist = _persist.then((_) => _cache.unqueueKitchenChanges(ids));
  }

  /// Drops changes the server would refuse for their age, with a message,
  /// instead of sending them forever.
  void _dropExpired(ClockReading now) {
    final hours = min(
      720,
      _config.get(ConfigKeys.kitchenSyncMaxChangeAgeHours),
    );
    final maxAgeMs = hours * 3600000;
    final expired = {
      for (final c in _queue)
        if (c.isStamped && ageBetween(c.stamp, now) > maxAgeMs) c.changeId,
    };
    if (expired.isEmpty) return;
    _unqueue(expired);
    _emit();
    ref
        .read(kitchenNoticesProvider.notifier)
        .post(KitchenChangesExpired(expired.length, maxAgeHours: hours));
  }

  void _scheduleRetry({Duration? atLeast}) {
    _failures++;
    var delay = Backoff.fromConfig(_config).delayFor(_failures);
    if (atLeast != null && atLeast > delay) delay = atLeast;
    _retryTimer?.cancel();
    final generation = _generation;
    _retryTimer = ref.read(syncTimersProvider).start(delay, () {
      _retryTimer = null;
      if (_current(generation)) unawaited(_sync());
    });
  }

  Future<void> _saveCopy() async {
    final list = _list;
    final account = _account;
    if (list == null || account == null) return;
    await _repo.saveCopy(
      list.copyWith(items: _confirmedItems),
      accountId: account,
      epoch: _epoch,
      cursor: _cursor,
    );
  }
}

final kitchenProvider = NotifierProvider<KitchenController, KitchenState>(
  KitchenController.new,
);

/// Starts the kitchen when its account has changes queued from an earlier
/// run, so they are sent without opening Dapur Saya first (KIT-16). Watched
/// by the signed-in shell.
final kitchenOutboxStarterProvider = Provider<void>((ref) {
  final account = ref.watch(currentAccountIdProvider);
  if (account == null) return;
  final cache = ref.read(localCacheProvider);
  unawaited(
    cache.outboxCount(account).then((count) {
      if (count > 0 &&
          ref.mounted &&
          ref.read(currentAccountIdProvider) == account) {
        ref.read(kitchenProvider);
      }
    }),
  );
});

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
