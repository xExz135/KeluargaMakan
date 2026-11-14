// Where the app starts and what follows sign-in and sign-out (flow.md 1 and
// 5; ACC-01, ACC-13).
//
// - No session: onboarding O1 (or O2 after the session expired).
// - Session, household unknown on this phone: look it up (`/starting`).
// - Account without a household: O3, which creates it (ACC-04).
// - Household known: the shell (Beranda).
//
// The router redirects on every change. Consent and the rest of onboarding
// (O4 to O8) come with T-029; until then a created household goes straight
// to the shell.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/api/session_manager.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/household_repository.dart';
import 'sign_in_draft.dart';

@immutable
sealed class AppEntry {
  const AppEntry();
}

/// Signed out. [atSignIn] opens O2 instead of O1 (after an expired session).
final class EntrySignedOut extends AppEntry {
  const EntrySignedOut({this.atSignIn = false});

  final bool atSignIn;

  @override
  String toString() => 'EntrySignedOut(atSignIn: $atSignIn)';
}

/// Signed in; the household is being looked up. [failed] when the last try
/// did not reach the API. [returning] after a sign-in on this phone, to greet
/// a returning user (`onboarding.welcomeBack`).
final class EntryResolving extends AppEntry {
  const EntryResolving({this.returning = false, this.failed = false});

  final bool returning;
  final bool failed;

  @override
  String toString() => 'EntryResolving(failed: $failed)';
}

/// Signed in to an account without a household: O3 creates it.
final class EntryNeedsHousehold extends AppEntry {
  const EntryNeedsHousehold();
}

final class EntryReady extends AppEntry {
  const EntryReady();
}

/// One-time messages shown over whatever screen comes next.
enum EntryNotice {
  /// Snackbar `onboarding.welcomeBack`.
  welcomeBack,

  /// Dialog `error.api.signedOut` (contract-alignment.md 5).
  sessionExpired,

  /// Snackbar: signed out, but cached data could not be removed.
  localDataNotCleared,
}

/// The next notice to show; the notice host clears it once shown.
final class EntryNoticeController extends Notifier<EntryNotice?> {
  @override
  EntryNotice? build() => null;

  void post(EntryNotice notice) => state = notice;

  void clear() => state = null;
}

final entryNoticeProvider =
    NotifierProvider<EntryNoticeController, EntryNotice?>(
      EntryNoticeController.new,
    );

/// Tests start the app at a given entry without a session.
final initialAppEntryProvider = Provider<AppEntry?>((ref) => null);

final class AppEntryController extends Notifier<AppEntry> {
  bool _dataNotClearedReported = false;

  @override
  AppEntry build() {
    final session = ref.read(sessionManagerProvider);
    final sub = session.ended.listen(_onEnded, onError: _onEndedWithError);
    ref.onDispose(sub.cancel);
    return ref.read(initialAppEntryProvider) ??
        (session.isSignedIn ? const EntryResolving() : const EntrySignedOut());
  }

  EntryNoticeController get _notices => ref.read(entryNoticeProvider.notifier);

  void _onEnded(SessionEndReason reason) => _signedOut(reason);

  /// SessionManager reports a session that ended without its local data
  /// removed (mobile security review).
  void _onEndedWithError(Object error) {
    final reason = error is SessionDataNotCleared
        ? error.reason
        : SessionEndReason.signedOut;
    _signedOut(reason);
    _dataNotClearedReported = true;
    _notices.post(EntryNotice.localDataNotCleared);
  }

  void _signedOut(SessionEndReason reason) {
    if (state is EntrySignedOut) return;
    final expired = reason == SessionEndReason.expired;
    state = EntrySignedOut(atSignIn: expired);
    if (expired) _notices.post(EntryNotice.sessionExpired);
  }

  /// Startup found a cached household for this session (restoreSession).
  void restoredWithHousehold() {
    if (state is EntryResolving) state = const EntryReady();
  }

  /// After a successful sign-in (ACC-01, ACC-13).
  void signedIn(SignedIn signedIn) {
    state = signedIn.account.householdId == null
        ? const EntryNeedsHousehold()
        : const EntryResolving(returning: true);
  }

  /// Verifies a sign-in code and, when it works, moves the app on and drops
  /// the sign-in draft, whatever happened to the screen meanwhile. The
  /// tokens are stored by the repository either way, so the app state must
  /// follow even if the code screen was left (security review T-027 L1).
  Future<ApiResult<SignedIn>> verifyCode({
    required String challengeId,
    required String code,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .verifySignInCode(challengeId: challengeId, code: code);
    if (!ref.mounted) return result;
    if (result case Ok(:final value)) {
      signedIn(value);
      ref.read(signInDraftProvider.notifier).clear();
    }
    return result;
  }

  /// Google sign-in (ACC-02), completed here for the same reason.
  Future<ApiResult<SignedIn>> signInWithGoogle(String idToken) async {
    final result = await ref
        .read(authRepositoryProvider)
        .signInWithGoogle(idToken);
    if (!ref.mounted) return result;
    if (result case Ok(:final value)) signedIn(value);
    return result;
  }

  /// O3 created the household, or found it already created.
  void householdReady() => state = const EntryReady();

  /// Looks up the household of the signed-in account.
  Future<void> resolveHousehold() async {
    final current = state;
    if (current is! EntryResolving) return;
    final returning = current.returning;
    state = EntryResolving(returning: returning);
    final repo = ref.read(householdRepositoryProvider);
    if (await repo.cached() != null) {
      _ready(returning: returning);
      return;
    }
    final result = await repo.getHousehold();
    if (state is! EntryResolving) return;
    switch (result) {
      case Ok():
        _ready(returning: returning);
      case Err(:final failure)
          when failure.problemCode == ApiErrorCode.householdRequired:
        state = const EntryNeedsHousehold();
      case Err(:final failure) when failure.isSignedOut:
        // The session ended; [ended] moves the app to sign-in.
        break;
      case Err():
        state = EntryResolving(returning: returning, failed: true);
    }
  }

  void _ready({required bool returning}) {
    state = const EntryReady();
    if (returning) _notices.post(EntryNotice.welcomeBack);
  }

  /// Signs out on this phone (ACC-13). Works without a connection. The app
  /// moves to signed out even if something fails on the way (security
  /// review T-027 L4); a failure is reported once.
  Future<void> signOut() async {
    _dataNotClearedReported = false;
    var outcome = SignOutOutcome.localDataNotCleared;
    try {
      outcome = await ref.read(authRepositoryProvider).signOut();
    } on Object {
      // Not expected (SessionManager.end does not throw); the outcome stays
      // "not cleared", so the user is told.
    } finally {
      // [ended] may already have moved the state; a repeat is harmless.
      if (ref.mounted && state is! EntrySignedOut) {
        state = const EntrySignedOut();
      }
    }
    // Removing local data can fail on the first try and work on the retry
    // inside SessionManager.end; signOut still reports it, so it is shown
    // here unless [ended] already reported it.
    await Future<void>.delayed(Duration.zero);
    if (!ref.mounted) return;
    if (outcome == SignOutOutcome.localDataNotCleared &&
        !_dataNotClearedReported) {
      _notices.post(EntryNotice.localDataNotCleared);
    }
  }
}

final appEntryProvider = NotifierProvider<AppEntryController, AppEntry>(
  AppEntryController.new,
);
