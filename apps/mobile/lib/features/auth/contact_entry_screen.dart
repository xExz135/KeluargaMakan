// O2a Number or email (ACC-01, screens.md O2a).
//
// Phone: fixed "+62", numeric keyboard, "08…" accepted (the trunk 0 is
// dropped; the server canonicalizes). Email: email keyboard. "Kirim kode"
// requests a code in the app language (`SignInCodeRequest.language`).
//
// What the user typed stays in this screen's field and in memory
// (SignInDraft); it is never stored or logged.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_result.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_routes.dart';
import 'contact_format.dart';
import 'countdown.dart';
import 'sign_in_draft.dart';
import 'sign_in_failure.dart';
import 'widgets/onboarding_scaffold.dart';

class ContactEntryScreen extends ConsumerStatefulWidget {
  const ContactEntryScreen({super.key, required this.channel});

  final api.SignInChannel channel;

  @override
  ConsumerState<ContactEntryScreen> createState() => _ContactEntryState();
}

class _ContactEntryState extends ConsumerState<ContactEntryScreen>
    with SecondTicker {
  final _field = TextEditingController();
  bool _invalid = false;
  bool _busy = false;
  SignInProblem? _problem;
  DateTime? _limitedUntil;

  bool get _isPhone => widget.channel == api.SignInChannel.phone;

  @override
  bool stillWaiting() => secondsUntil(_limitedUntil) > 0;

  late final SignInDraftController _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(signInDraftProvider.notifier);
  }

  @override
  void dispose() {
    _field.dispose();
    // Leaving O2a (back to O2, or on to the app after sign-in) drops the
    // number or email from memory. After the frame: providers cannot change
    // while the tree is being torn down.
    final draft = _draft;
    Future.microtask(draft.clear);
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || secondsUntil(_limitedUntil) > 0) return;
    final String? destination;
    final String masked;
    if (_isPhone) {
      final national = IndonesianPhone.national(_field.text);
      destination = national == null ? null : IndonesianPhone.e164(_field.text);
      masked = national == null ? '' : IndonesianPhone.masked(national);
    } else {
      destination = EmailAddress.normalized(_field.text);
      masked = destination == null ? '' : EmailAddress.masked(destination);
    }
    if (destination == null) {
      setState(() {
        _invalid = true;
        _problem = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _invalid = false;
      _problem = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .requestSignInCode(
          channel: widget.channel,
          destination: destination,
          language: AppLocales.toApi(ref.read(localeControllerProvider)),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(value: final challenge):
        ref
            .read(signInDraftProvider.notifier)
            .set(
              SignInDraft(
                channel: widget.channel,
                destination: destination,
                maskedDestination: masked,
                challenge: challenge,
                resendAvailableAt: localResendAt(challenge, now()),
              ),
            );
        context.go(AuthRoutes.code(widget.channel));
      case Err(:final failure):
        final problem = SignInProblem.of(failure);
        setState(() {
          if (problem == SignInProblem.invalidInput) {
            _invalid = true;
          } else if (problem == SignInProblem.tooMany) {
            _limitedUntil = now().add(retryWait(failure, maxRetryWait(ref)));
            _problem = problem;
            startTicking();
          } else {
            _problem = problem;
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final limitedSeconds = secondsUntil(_limitedUntil);
    final problem = _problem == SignInProblem.tooMany && limitedSeconds == 0
        ? null
        : _problem;
    final errorText = !_invalid
        ? null
        : (_isPhone
              ? l10n.onboardingPhoneErrorInvalid
              : l10n.onboardingEmailErrorInvalid);
    return OnboardingScaffold(
      title: _isPhone ? l10n.onboardingSigninPhone : l10n.onboardingSigninEmail,
      bottom: [
        OnboardingButton(
          key: const Key('contact.send'),
          label: l10n.onboardingPhoneSend,
          loadingLabel: _busy ? l10n.commonLoading : null,
          onPressed: limitedSeconds > 0 ? null : _submit,
        ),
      ],
      children: [
        TextField(
          key: const Key('contact.field'),
          controller: _field,
          autofocus: true,
          readOnly: _busy,
          keyboardType: _isPhone
              ? TextInputType.phone
              : TextInputType.emailAddress,
          autofillHints: [
            _isPhone
                ? AutofillHints.telephoneNumberNational
                : AutofillHints.email,
          ],
          inputFormatters: _isPhone
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9 +()-]'))]
              : null,
          autocorrect: false,
          enableSuggestions: false,
          // The keyboard must not learn the number or email (security
          // review T-027 L2).
          enableIMEPersonalizedLearning: false,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_invalid) setState(() => _invalid = false);
          },
          decoration: InputDecoration(
            labelText: _isPhone
                ? l10n.onboardingPhoneLabel
                : l10n.onboardingEmailLabel,
            prefixText: _isPhone ? '${IndonesianPhone.countryPrefix} ' : null,
            helperText: _isPhone ? l10n.onboardingPhoneHelper : null,
            helperMaxLines: 3,
            errorText: errorText,
            errorMaxLines: 4,
          ),
        ),
        if (problem != null) ...[
          const SizedBox(height: SpacingTokens.l),
          SignInProblemMessage(
            problem: problem,
            waitMinutes: SecondTicker.minutesFor(limitedSeconds),
          ),
        ],
      ],
    );
  }
}
