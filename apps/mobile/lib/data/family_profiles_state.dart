// The family as Keluarga Saya, who's eating and suggestions read it.
//
// The states are explicit so no screen can mistake a failure for a family
// without rules (QUESTIONS #39):
// - [FamilyRulesUnavailable]: the server could not read the rules
//   (`rules_unavailable`). Full-area error; who's eating and suggestions are
//   blocked, because Cek Aman cannot run without the rules.
// - [FamilyLoadFailed]: anything else, including a payload this app version
//   cannot decode. Nothing is shown from it.
// - [FamilyLoaded] from the cache: names only, every member [RulesNotLoaded].
//
// The state belongs to one account: it is rebuilt empty when the session
// ends or another account signs in (currentAccountIdProvider, security
// review T-027 M1), and an answer for the previous account is dropped.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_result.dart';
import 'models/family.dart';
import 'repositories/profiles_repository.dart';

sealed class FamilyProfilesState {
  const FamilyProfilesState();
}

final class FamilyLoading extends FamilyProfilesState {
  const FamilyLoading();
}

final class FamilyLoaded extends FamilyProfilesState {
  const FamilyLoaded(this.profiles);

  final FamilyProfiles profiles;
}

final class FamilyRulesUnavailable extends FamilyProfilesState {
  const FamilyRulesUnavailable();
}

final class FamilyLoadFailed extends FamilyProfilesState {
  const FamilyLoadFailed(this.failure);

  final ApiFailure failure;
}

/// Maps a repository result to a state.
FamilyProfilesState familyStateFrom(ApiResult<FamilyProfiles> result) =>
    switch (result) {
      Ok(:final value) => FamilyLoaded(value),
      Err(:final failure) when failure.isRulesUnavailable =>
        const FamilyRulesUnavailable(),
      Err(:final failure) => FamilyLoadFailed(failure),
    };

final class FamilyProfilesController extends Notifier<FamilyProfilesState> {
  @override
  FamilyProfilesState build() {
    final account = ref.watch(currentAccountIdProvider);
    // A load still running for the previous account must not be joined.
    _loading = null;
    _generation++;
    if (account != null) Future.microtask(reload);
    return const FamilyLoading();
  }

  Future<void>? _loading;
  int _generation = 0;

  /// Loads the profiles, showing [FamilyLoading] meanwhile. A reload asked
  /// for while one is running joins it, so an older answer can never
  /// overwrite a newer state.
  Future<void> reload() => _start(quiet: false);

  /// Reads the profiles again after a write, keeping the current state on
  /// screen until the answer comes (T-028). The read always starts after
  /// the call: a load already running may have been answered before the
  /// write, so it is awaited first and not joined.
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
    if (ref.read(currentAccountIdProvider) == null) return;
    final generation = _generation;
    if (!quiet || state is! FamilyLoaded) state = const FamilyLoading();
    final result = await ref.read(profilesRepositoryProvider).listProfiles();
    if (!ref.mounted || generation != _generation) return;
    state = familyStateFrom(result);
  }
}

/// The member with [profileId] in a loaded family, or null.
FamilyMember? memberIn(FamilyProfilesState state, String profileId) =>
    switch (state) {
      FamilyLoaded(:final profiles) =>
        profiles.members.where((m) => m.id == profileId).firstOrNull,
      _ => null,
    };

final familyProfilesProvider =
    NotifierProvider<FamilyProfilesController, FamilyProfilesState>(
      FamilyProfilesController.new,
    );
