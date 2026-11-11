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

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    Future.microtask(reload);
    return const FamilyLoading();
  }

  Future<void>? _loading;

  /// Loads the profiles. A reload asked for while one is running joins it,
  /// so an older answer can never overwrite a newer state.
  Future<void> reload() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    state = const FamilyLoading();
    final result = await ref.read(profilesRepositoryProvider).listProfiles();
    if (!ref.mounted) return;
    state = familyStateFrom(result);
  }
}

final familyProfilesProvider =
    NotifierProvider<FamilyProfilesController, FamilyProfilesState>(
      FamilyProfilesController.new,
    );
