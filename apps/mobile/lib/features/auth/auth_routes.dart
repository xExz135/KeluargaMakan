// Onboarding and sign-in routes (flow.md 1). Nested so Android back goes
// one step up: code → number or email → sign-in choice → welcome.

import 'package:keluargamakan_api/api.dart' as api;

abstract final class AuthRoutes {
  /// O1.
  static const welcome = '/welcome';

  /// O2.
  static const signIn = '/welcome/sign-in';

  /// O2a, by channel.
  static const phone = '/welcome/sign-in/phone';
  static const email = '/welcome/sign-in/email';

  /// O2b, under the O2a screen it came from.
  static const phoneCode = '/welcome/sign-in/phone/code';
  static const emailCode = '/welcome/sign-in/email/code';

  /// O3, after the first sign-in (creates the household).
  static const name = '/name';

  /// Looking up the household of a signed-in account.
  static const starting = '/starting';

  static String contact(api.SignInChannel channel) =>
      channel == api.SignInChannel.email ? email : phone;

  static String code(api.SignInChannel channel) =>
      channel == api.SignInChannel.email ? emailCode : phoneCode;

  /// Every route a signed-out user may be on.
  static bool isSignedOutRoute(String location) =>
      location == welcome || location.startsWith('$welcome/');
}
