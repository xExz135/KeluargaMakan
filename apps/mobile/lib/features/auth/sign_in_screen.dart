// O2 Sign in (ACC-01, ACC-02, screens.md O2).
//
// Phone number or email with a code. "Lanjut dengan Google" shows only when
// `auth.googleSignInEnabled` is on (off by default: the server answers 503
// until T-018, INT-13). No Apple sign-in (Android only).
//
// Not built: the legal line with links to the terms and privacy policy. The
// in-app legal reader (settings-privacy S8) does not exist yet and the texts
// wait for legal review, which the owner deferred for private use
// (DECISIONS 2026-11-11). See the T-027 report.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_entry.dart';
import 'auth_routes.dart';
import 'google_id_token.dart';
import 'widgets/onboarding_scaffold.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _phoneFocus = FocusNode(debugLabel: 'signIn.phone');
  bool _googleBusy = false;

  @override
  void dispose() {
    _phoneFocus.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _google() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _googleBusy = true);
    final token = await ref.read(googleIdTokenSourceProvider).requestIdToken();
    if (!mounted) return;
    switch (token) {
      case GoogleSignInCancelled():
        setState(() => _googleBusy = false);
        return;
      case GoogleSignInNotAvailable():
        setState(() => _googleBusy = false);
        _googleUnavailable(l10n);
        return;
      case GoogleIdToken(:final idToken):
        final result = await ref
            .read(appEntryProvider.notifier)
            .signInWithGoogle(idToken);
        if (!mounted) return;
        setState(() => _googleBusy = false);
        switch (result) {
          case Ok():
            break;
          case Err(failure: NetworkFailure()):
            _snack(l10n.onboardingWelcomeOffline);
          case Err(:final failure)
              when failure.problemCode ==
                      ApiErrorCode.signInMethodUnavailable ||
                  failure is NotConfiguredFailure:
            _googleUnavailable(l10n);
          case Err():
            _snack(l10n.onboardingSigninErrorGoogle);
        }
    }
  }

  /// contract-alignment.md 5: snackbar, focus moves to "Pakai nomor HP".
  void _googleUnavailable(AppLocalizations l10n) {
    _snack(l10n.onboardingSigninGoogleUnavailable);
    _phoneFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final googleEnabled = ref
        .watch(appConfigProvider)
        .get(ConfigKeys.googleSignInEnabled);
    final busy = _googleBusy;
    return OnboardingScaffold(
      title: l10n.onboardingSigninTitle,
      children: [
        Text(l10n.onboardingSigninBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: SpacingTokens.xl),
        if (googleEnabled) ...[
          OnboardingButton(
            key: const Key('signIn.google'),
            label: l10n.onboardingSigninGoogle,
            loadingLabel: busy ? l10n.commonLoading : null,
            onPressed: _google,
          ),
          const SizedBox(height: SpacingTokens.m),
        ],
        OnboardingButton(
          key: const Key('signIn.phone'),
          focusNode: _phoneFocus,
          kind: googleEnabled
              ? OnboardingButtonKind.outlined
              : OnboardingButtonKind.filled,
          icon: Icons.phone_android,
          label: l10n.onboardingSigninPhone,
          onPressed: busy ? null : () => context.go(AuthRoutes.phone),
        ),
        const SizedBox(height: SpacingTokens.m),
        OnboardingButton(
          key: const Key('signIn.email'),
          kind: OnboardingButtonKind.outlined,
          icon: Icons.mail_outline,
          label: l10n.onboardingSigninEmail,
          onPressed: busy ? null : () => context.go(AuthRoutes.email),
        ),
      ],
    );
  }
}
