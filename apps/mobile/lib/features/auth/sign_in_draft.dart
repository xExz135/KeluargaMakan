// The sign-in in progress (ACC-01): where the code went and the challenge to
// verify it against. Memory only: the phone number or email is never
// written to storage or logs, and it is dropped once signed in. The code
// itself never leaves the code screen's field.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

@immutable
final class SignInDraft {
  const SignInDraft({
    required this.channel,
    required this.destination,
    required this.maskedDestination,
    required this.challenge,
    required this.resendAvailableAt,
  });

  final api.SignInChannel channel;

  /// What is sent to the API: E.164 or the trimmed email.
  final String destination;

  /// "0812 •••• 7890" or "r•••@contoh.com" (screens.md O2b).
  final String maskedDestination;
  final api.SignInCodeChallenge challenge;

  /// When "Kirim ulang" becomes available, on this phone's clock.
  final DateTime resendAvailableAt;

  int get codeLength => challenge.codeLength;

  // Holds a contact detail; never print it.
  @override
  String toString() => 'SignInDraft(${channel.toJson()})';
}

final class SignInDraftController extends Notifier<SignInDraft?> {
  @override
  SignInDraft? build() => null;

  void set(SignInDraft draft) => state = draft;

  void clear() => state = null;
}

final signInDraftProvider =
    NotifierProvider<SignInDraftController, SignInDraft?>(
      SignInDraftController.new,
    );
