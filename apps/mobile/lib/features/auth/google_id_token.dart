// Where a Google ID token would come from (ACC-02, Android Credential
// Manager). Not built yet: Google sign-in waits for the server (T-018) and
// the owner's Firebase and Google project (QUESTIONS #16), and the app has no
// Google SDK. The button is hidden unless `auth.googleSignInEnabled` is on
// (INT-13: phone or email is the sign-in method meanwhile).

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class GoogleIdTokenSource {
  /// The ID token, or null when Google sign-in is not available on this
  /// phone or the user closed the sheet.
  Future<GoogleIdTokenResult> requestIdToken();
}

sealed class GoogleIdTokenResult {
  const GoogleIdTokenResult();
}

final class GoogleIdToken extends GoogleIdTokenResult {
  const GoogleIdToken(this.idToken);

  final String idToken;

  @override
  String toString() => 'GoogleIdToken(<redacted>)';
}

/// The user closed the Google sheet: stay on O2 without a message.
final class GoogleSignInCancelled extends GoogleIdTokenResult {
  const GoogleSignInCancelled();
}

/// Google sign-in cannot run on this phone or in this build.
final class GoogleSignInNotAvailable extends GoogleIdTokenResult {
  const GoogleSignInNotAvailable();
}

final class UnavailableGoogleIdTokenSource implements GoogleIdTokenSource {
  const UnavailableGoogleIdTokenSource();

  @override
  Future<GoogleIdTokenResult> requestIdToken() async =>
      const GoogleSignInNotAvailable();
}

final googleIdTokenSourceProvider = Provider<GoogleIdTokenSource>(
  (ref) => const UnavailableGoogleIdTokenSource(),
);
