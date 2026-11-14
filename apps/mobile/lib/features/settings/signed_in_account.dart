// "Masuk sebagai {account}" in Settings (ACC-13): which phone number or email
// this account signs in with, masked, so the user knows what to use on
// another phone. Read from the API each time Settings opens; never cached.
// Hidden when it cannot be loaded.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_result.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/contact_format.dart';

/// The masked sign-in contact, or null (Google-only, or not loaded).
String? maskedAccountContact(api.Account account) {
  final phone = account.phone;
  if (phone != null) {
    final national = IndonesianPhone.national(phone);
    if (national != null) return IndonesianPhone.masked(national);
  }
  final email = account.email;
  if (email != null && email.contains('@')) return EmailAddress.masked(email);
  return null;
}

final signedInAccountProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final auth = ref.watch(authRepositoryProvider);
  if (!auth.isSignedIn) return null;
  return switch (await auth.getAccount()) {
    Ok(:final value) => maskedAccountContact(value),
    Err() => null,
  };
});
