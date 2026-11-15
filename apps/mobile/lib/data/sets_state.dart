// KIT-08 ingredient sets (screens.md K5).
//
// - The list is shown from the phone's copy without internet.
// - "Tandai semua ada" works without internet: it is a set of ordinary
//   kitchen changes, queued like any tap (KitchenController.markAvailable).
// - Creating, renaming, changing and deleting a set need internet in V1.
//   Sets name server item IDs, an item added without internet has none
//   yet, and the sync contract carries no set changes, so a set edit made
//   offline could not be ordered against other phones (QUESTIONS #74).
//   The input is kept and the screen says internet is needed.
// - A create without an answer keeps its Idempotency-Key for the retry of
//   that same set, so it cannot be created twice.
// Set names are the user's own text: never logged.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_problem.dart';
import '../core/api/api_result.dart';
import 'models/kitchen.dart';
import 'models/sourced.dart';
import 'repositories/auth_repository.dart' show randomUuidV4;
import 'repositories/kitchen_repository.dart';

sealed class SetsState {
  const SetsState();
}

final class SetsLoading extends SetsState {
  const SetsLoading();
}

final class SetsLoaded extends SetsState {
  const SetsLoaded(this.sets);

  final IngredientSets sets;
}

final class SetsLoadFailed extends SetsState {
  const SetsLoadFailed(this.failure);

  final ApiFailure failure;
}

final class SetsController extends Notifier<SetsState> {
  @override
  SetsState build() {
    final account = ref.watch(currentAccountIdProvider);
    _account = account;
    _epoch = ref.read(sessionManagerProvider).epoch;
    _generation++;
    _loading = null;
    _createKeys = {};
    if (account != null) Future.microtask(reload);
    return const SetsLoading();
  }

  String? _account;
  int _epoch = 0;
  int _generation = 0;
  Future<void>? _loading;

  /// Idempotency-Keys of creates that got no answer, per name and items.
  Map<String, String> _createKeys = {};

  KitchenRepository get _repo => ref.read(kitchenRepositoryProvider);

  bool _current(int generation) {
    if (!ref.mounted || generation != _generation) return false;
    final session = ref.read(sessionManagerProvider);
    return !session.isEnding &&
        session.epoch == _epoch &&
        session.current?.accountId == _account;
  }

  /// Loads the sets; joins a load that is running.
  Future<void> reload() {
    final running = _loading;
    if (running != null) return running;
    late final Future<void> load;
    load = _load().whenComplete(() {
      if (identical(_loading, load)) _loading = null;
    });
    return _loading = load;
  }

  Future<void> _load() async {
    if (_account == null) return;
    final generation = _generation;
    final result = await _repo.listSets();
    if (!_current(generation)) return;
    switch (result) {
      case Ok(:final value):
        state = SetsLoaded(value);
      case Err(:final failure):
        if (state is! SetsLoaded) state = SetsLoadFailed(failure);
    }
  }

  IngredientSets? get _sets => switch (state) {
    SetsLoaded(:final sets) => sets,
    _ => null,
  };

  Future<void> _keep(IngredientSets sets) async {
    state = SetsLoaded(sets);
    final account = _account;
    if (account == null) return;
    await _repo.saveSets(sets, accountId: account, epoch: _epoch);
  }

  /// Creates a set with [itemIds] (server item IDs). Online only.
  Future<ApiResult<IngredientSetInfo>> create(
    String name,
    List<String> itemIds,
  ) async {
    final account = _account;
    if (account == null) return const Err(NetworkFailure());
    final generation = _generation;
    final requestId = '$name|${itemIds.join(',')}';
    final key = _createKeys[requestId] ??= randomUuidV4();
    final result = await _repo.createSet(
      accountId: account,
      name: name,
      itemIds: itemIds,
      idempotencyKey: key,
    );
    if (!_current(generation)) return result;
    switch (result) {
      case Ok(:final value):
        _createKeys.remove(requestId);
        final sets = _sets;
        if (sets != null) {
          await _keep(
            sets.copyWith(
              items: [
                for (final s in sets.items)
                  if (s.id != value.id) s,
                value,
              ],
              source: const FromNetwork(),
            ),
          );
        } else {
          await reload();
        }
      case Err(failure: NetworkFailure()):
        break; // The same key on the retry.
      case Err():
        _createKeys.remove(requestId);
    }
    return result;
  }

  /// Renames [setId] or changes its items. Online only; sending it again is
  /// safe.
  Future<ApiResult<IngredientSetInfo>> replace(
    String setId,
    String name,
    List<String> itemIds,
  ) async {
    final account = _account;
    if (account == null) return const Err(NetworkFailure());
    final generation = _generation;
    final result = await _repo.replaceSet(
      setId,
      accountId: account,
      name: name,
      itemIds: itemIds,
    );
    if (!_current(generation)) return result;
    final sets = _sets;
    switch (result) {
      case Ok(:final value) when sets != null:
        await _keep(
          sets.copyWith(
            items: [for (final s in sets.items) s.id == setId ? value : s],
            source: const FromNetwork(),
          ),
        );
      case Err(:final failure)
          when failure.problemCode == ApiErrorCode.notFound && sets != null:
        // Deleted on another phone.
        await _keep(
          sets.copyWith(
            items: [
              for (final s in sets.items)
                if (s.id != setId) s,
            ],
          ),
        );
      case _:
        break;
    }
    return result;
  }

  /// Deletes [setId]; its items stay in the kitchen. Online only.
  Future<ApiResult<void>> delete(String setId) async {
    final account = _account;
    if (account == null) return const Err(NetworkFailure());
    final generation = _generation;
    final result = await _repo.deleteSet(setId, accountId: account);
    if (!_current(generation)) return result;
    final gone = switch (result) {
      Ok() => true,
      Err(:final failure) => failure.problemCode == ApiErrorCode.notFound,
    };
    final sets = _sets;
    if (gone && sets != null) {
      await _keep(
        sets.copyWith(
          items: [
            for (final s in sets.items)
              if (s.id != setId) s,
          ],
        ),
      );
    }
    return gone ? const Ok(null) : result;
  }
}

final setsProvider = NotifierProvider<SetsController, SetsState>(
  SetsController.new,
);
