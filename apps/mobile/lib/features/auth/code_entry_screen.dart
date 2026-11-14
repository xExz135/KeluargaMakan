// O2b Code (ACC-01, screens.md O2b).
//
// One autofill field (one-time-code hint, no SMS read permission) drawn as
// `codeLength` boxes; auto-submit on the last digit, "Lanjut" for a retry.
// The code lives only in this field: it is not saved, restored or logged,
// the keyboard is asked not to learn it, and it is cleared after every try.
//
// States (contract-alignment.md 5): wrong code (boxes cleared), expired and
// too many wrong codes (boxes locked until a new code), 429 (wait from
// Retry-After, resend disabled), code sending unavailable, no internet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_result.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_entry.dart';
import 'auth_routes.dart';
import 'countdown.dart';
import 'sign_in_draft.dart';
import 'sign_in_failure.dart';
import 'widgets/code_boxes.dart';
import 'widgets/onboarding_scaffold.dart';

class CodeEntryScreen extends ConsumerStatefulWidget {
  const CodeEntryScreen({super.key, required this.channel});

  final api.SignInChannel channel;

  @override
  ConsumerState<CodeEntryScreen> createState() => _CodeEntryState();
}

class _CodeEntryState extends ConsumerState<CodeEntryScreen> with SecondTicker {
  final _code = TextEditingController();
  final _focus = FocusNode(debugLabel: 'signIn.code');
  SignInProblem? _problem;

  /// Expired or too many wrong codes: only a new code helps.
  bool _locked = false;

  /// 429 on verify (wrong codes per destination and day, or per address):
  /// neither verifying nor a new code works until then.
  DateTime? _verifyBlockedUntil;

  /// 429 on resend.
  DateTime? _resendBlockedUntil;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    if (stillWaiting()) startTicking();
  }

  @override
  bool stillWaiting() {
    final draft = ref.read(signInDraftProvider);
    return secondsUntil(_resendAt(draft)) > 0 ||
        secondsUntil(_verifyBlockedUntil) > 0;
  }

  @override
  void dispose() {
    _code
      ..clear()
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  DateTime? _resendAt(SignInDraft? draft) {
    DateTime? latest = draft?.resendAvailableAt;
    for (final t in [_resendBlockedUntil, _verifyBlockedUntil]) {
      if (t != null && (latest == null || t.isAfter(latest))) latest = t;
    }
    return latest;
  }

  bool get _inputBlocked => _locked || secondsUntil(_verifyBlockedUntil) > 0;

  void _onChanged(String value, SignInDraft draft) {
    if (_problem == SignInProblem.wrongCode ||
        _problem == SignInProblem.generic ||
        _problem == SignInProblem.offline) {
      setState(() => _problem = null);
    } else {
      setState(() {});
    }
    if (value.length == draft.codeLength) _verify(draft);
  }

  Future<void> _verify(SignInDraft draft) async {
    final code = _code.text;
    if (_verifying || _inputBlocked || code.length != draft.codeLength) return;
    setState(() => _verifying = true);
    final result = await ref
        .read(authRepositoryProvider)
        .verifySignInCode(challengeId: draft.challenge.challengeId, code: code);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _code.clear();
        ref.read(appEntryProvider.notifier).signedIn(value);
        ref.read(signInDraftProvider.notifier).clear();
      case Err(:final failure):
        final problem = SignInProblem.of(failure);
        setState(() {
          _verifying = false;
          switch (problem) {
            case SignInProblem.wrongCode || SignInProblem.invalidInput:
              _problem = SignInProblem.wrongCode;
              _code.clear();
            case SignInProblem.expired || SignInProblem.attemptsExceeded:
              _problem = problem;
              _locked = true;
              _code.clear();
            case SignInProblem.tooMany:
              _problem = problem;
              _verifyBlockedUntil = now().add(retryWait(failure));
              _code.clear();
              startTicking();
            case SignInProblem.unavailable ||
                SignInProblem.offline ||
                SignInProblem.generic:
              // Code and attempt count are unchanged (contract: a 503 leaves
              // them as they were); keep the digits for "Lanjut".
              _problem = problem;
          }
        });
        if (!_inputBlocked) _focus.requestFocus();
    }
  }

  Future<void> _resend(SignInDraft draft) async {
    if (_resending || secondsUntil(_resendAt(draft)) > 0) return;
    setState(() => _resending = true);
    final result = await ref
        .read(authRepositoryProvider)
        .requestSignInCode(
          channel: draft.channel,
          destination: draft.destination,
          language: AppLocales.toApi(ref.read(localeControllerProvider)),
        );
    if (!mounted) return;
    setState(() {
      _resending = false;
      switch (result) {
        case Ok(value: final challenge):
          ref
              .read(signInDraftProvider.notifier)
              .set(
                SignInDraft(
                  channel: draft.channel,
                  destination: draft.destination,
                  maskedDestination: draft.maskedDestination,
                  challenge: challenge,
                  resendAvailableAt: localResendAt(challenge, now()),
                ),
              );
          _code.clear();
          _problem = null;
          _locked = false;
          _resendBlockedUntil = null;
        case Err(:final failure):
          final problem = SignInProblem.of(failure);
          if (problem == SignInProblem.tooMany) {
            _resendBlockedUntil = now().add(retryWait(failure));
          }
          _problem = problem == SignInProblem.invalidInput
              ? SignInProblem.generic
              : problem;
      }
    });
    if (stillWaiting()) startTicking();
    if (!_inputBlocked) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(signInDraftProvider);
    if (draft == null) {
      // The route redirects to O2a; nothing to show meanwhile.
      return const Scaffold(body: SizedBox.shrink());
    }
    final resendSeconds = secondsUntil(_resendAt(draft));
    final blockedSeconds = secondsUntil(_verifyBlockedUntil);
    final waitSeconds = blockedSeconds > 0
        ? blockedSeconds
        : secondsUntil(_resendBlockedUntil);
    final problem = _problem == SignInProblem.tooMany && waitSeconds == 0
        ? null
        : _problem;
    final complete = _code.text.length == draft.codeLength;
    final String resendLabel;
    if (resendSeconds <= 0) {
      resendLabel = l10n.onboardingCodeResend;
    } else if (resendSeconds > 60) {
      resendLabel = l10n.onboardingCodeResendInMinutes(
        SecondTicker.minutesFor(resendSeconds),
      );
    } else {
      resendLabel = l10n.onboardingCodeResendIn(resendSeconds);
    }

    return OnboardingScaffold(
      title: l10n.onboardingCodeTitle,
      bottom: [
        OnboardingButton(
          key: const Key('code.continue'),
          label: l10n.commonContinue,
          loadingLabel: _verifying ? l10n.commonLoading : null,
          onPressed: complete && !_inputBlocked ? () => _verify(draft) : null,
        ),
      ],
      children: [
        Text(
          l10n.onboardingCodeBodyLength(
            draft.codeLength,
            draft.maskedDestination,
          ),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: SpacingTokens.xl),
        CodeBoxes(
          controller: _code,
          focusNode: _focus,
          length: draft.codeLength,
          enabled: !_inputBlocked && !_verifying,
          semanticsLabel: l10n.onboardingCodeFieldLabel(draft.codeLength),
          onChanged: (value) => _onChanged(value, draft),
        ),
        if (problem != null) ...[
          const SizedBox(height: SpacingTokens.l),
          SignInProblemMessage(
            problem: problem,
            waitMinutes: SecondTicker.minutesFor(waitSeconds),
          ),
        ],
        const SizedBox(height: SpacingTokens.l),
        OnboardingButton(
          key: const Key('code.resend'),
          kind: OnboardingButtonKind.outlined,
          label: resendLabel,
          loadingLabel: _resending ? l10n.commonLoading : null,
          onPressed: resendSeconds > 0 ? null : () => _resend(draft),
        ),
        const SizedBox(height: SpacingTokens.s),
        OnboardingButton(
          key: const Key('code.change'),
          kind: OnboardingButtonKind.text,
          label: l10n.onboardingCodeChange,
          onPressed: () => context.go(AuthRoutes.contact(widget.channel)),
        ),
      ],
    );
  }
}
