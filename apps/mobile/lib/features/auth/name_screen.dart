// O3 Your name (ACC-04, screens.md O3): creates the household with the
// manager's profile after the first sign-in.
//
// `createHousehold` gets the device's Indonesian zone (WIB, WITA or WIT, else
// WIB), the app language and the nickname, with an Idempotency-Key that is
// reused when the same name is sent again. `household_exists` (a retry after
// a lost answer) loads the household and continues silently.
//
// Consent and the rest of onboarding (O4 to O8) come with T-029; until then
// the app goes on to the shell.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_error_text.dart';
import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/theme/tokens.dart';
import '../../core/time/clock.dart';
import '../../core/time/household_time.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/household_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_entry.dart';
import 'widgets/onboarding_scaffold.dart';

/// Contract `ProfileName`: 1 to 30 characters.
const profileNameMaxLength = 30;

/// O3 is the first of the five steps O3 to O7 (flow.md 3).
const _progress = 1 / 5;

class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

enum _NameProblem { offline, generic }

class _NameScreenState extends ConsumerState<NameScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  FieldErrorKind? _fieldError;
  _NameProblem? _problem;

  /// The key belongs to one request body: a different name gets a new key,
  /// the same name sent again reuses it (no `idempotency_key_reused`).
  String? _keyFor;
  String? _idempotencyKey;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (_busy || name.isEmpty) return;
    if (_keyFor != name) {
      _keyFor = name;
      _idempotencyKey = randomUuidV4();
    }
    setState(() {
      _busy = true;
      _fieldError = null;
      _problem = null;
    });
    final households = ref.read(householdRepositoryProvider);
    final zone = HouseholdTimeZone.fromOffset(
      ref.read(clockProvider)().timeZoneOffset,
    );
    final result = await households.createHousehold(
      api.HouseholdCreate(
        timeZone: zone.ianaName,
        language: AppLocales.toApi(ref.read(localeControllerProvider)),
        managerProfile: api.ManagerProfileCreate(name: name),
      ),
      idempotencyKey: _idempotencyKey!,
    );
    if (!mounted) return;
    var outcome = result;
    if (result case Err(:final failure)
        when failure.problemCode == ApiErrorCode.householdExists) {
      outcome = await households.getHousehold();
      if (!mounted) return;
    }
    switch (outcome) {
      case Ok():
        ref.read(appEntryProvider.notifier).householdReady();
      case Err(:final failure) when failure.isSignedOut:
        // The session ended; the app moves to sign-in.
        setState(() => _busy = false);
      case Err(:final failure):
        setState(() {
          _busy = false;
          final fields = switch (failure) {
            ProblemFailure(:final problem)
                when problem.code == ApiErrorCode.validationFailed =>
              problem.fieldErrors,
            _ => const <ApiFieldError>[],
          };
          final nameError = fields
              .where((e) => e.pointer.endsWith('/name'))
              .firstOrNull;
          if (nameError != null) {
            _fieldError = nameError.kind;
          } else if (failure is NetworkFailure) {
            _problem = _NameProblem.offline;
          } else {
            _problem = _NameProblem.generic;
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = _name.text.trim().isEmpty;
    return OnboardingScaffold(
      title: l10n.onboardingNameTitle,
      progress: _progress,
      bottom: [
        OnboardingButton(
          key: const Key('name.continue'),
          label: l10n.commonContinue,
          loadingLabel: _busy ? l10n.commonLoading : null,
          onPressed: empty ? null : _submit,
        ),
      ],
      children: [
        TextField(
          key: const Key('name.field'),
          controller: _name,
          autofocus: true,
          readOnly: _busy,
          maxLength: profileNameMaxLength,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.nickname],
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _fieldError = null),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n.onboardingNameLabel,
            hintText: l10n.onboardingNameHint,
            helperText: l10n.onboardingNameHelper,
            helperMaxLines: 3,
            errorMaxLines: 3,
            errorText: _fieldError == null
                ? null
                : ApiErrorText.field(
                    l10n,
                    _fieldError!,
                    maxLength: profileNameMaxLength,
                  ),
          ),
        ),
        if (_problem != null) ...[
          const SizedBox(height: SpacingTokens.l),
          switch (_problem!) {
            _NameProblem.offline => InlineMessage(
              key: const Key('name.offline'),
              kind: InlineMessageKind.info,
              text: l10n.onboardingWelcomeOffline,
            ),
            _NameProblem.generic => InlineMessage(
              key: const Key('name.generic'),
              title: l10n.errorGenericTitle,
              text: l10n.errorGenericBody,
            ),
          },
        ],
      ],
    );
  }
}
