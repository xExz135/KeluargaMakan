// F4c Consent sheet for a member (ACC-08, SET-03, SET-10; screens.md F4c,
// contract-alignment.md 6.2 and 7). DRAFT texts: needs legal review.
//
// - The text is the server's `ConsentText` for `health_data` and the
//   member's audience (adult or child, QUESTIONS #62). App strings are only
//   the chrome around it.
// - The decision is sent at once with the consent state the manager was
//   shown (`expectedConsent`), from a fresh API read. It is never queued
//   offline. The Idempotency-Key is reused only to resend the same decision
//   after no answer.
// - 409 `consent_changed`: the member is read again and the manager is asked
//   again; the next decision gets a new key.
// - Rules picked before the sheet stay in the caller's memory; nothing about
//   them is sent or stored here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/tokens.dart';
import '../../core/time/household_time.dart';
import '../../data/family_profiles_state.dart';
import '../../data/models/family.dart';
import '../../data/repositories/auth_repository.dart' show randomUuidV4;
import '../../data/repositories/consent_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart';
import 'labels.dart';
import 'rule_draft.dart';

enum ConsentOutcome {
  /// Consent recorded as given: rules may be saved now.
  given,

  /// Recorded as declined: no rules are stored.
  declined,

  /// Nothing recorded (closed, or continued without the text).
  notRecorded,
}

/// Opens F4c for [profileId]. [rules] are the picked rules shown as the
/// summary (empty: the zero-rules variant). [renewal]: the member changed
/// between adult and child and the stored rules wait for a new decision.
Future<ConsentOutcome> showMemberConsentSheet(
  BuildContext context, {
  required String profileId,
  required List<RuleDraft> rules,
  bool renewal = false,
}) async {
  final outcome = await showModalBottomSheet<ConsentOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    enableDrag: false,
    builder: (_) =>
        ConsentSheet(profileId: profileId, rules: rules, renewal: renewal),
  );
  return outcome ?? ConsentOutcome.notRecorded;
}

class ConsentSheet extends ConsumerStatefulWidget {
  const ConsentSheet({
    super.key,
    required this.profileId,
    required this.rules,
    this.renewal = false,
  });

  final String profileId;
  final List<RuleDraft> rules;
  final bool renewal;

  @override
  ConsumerState<ConsentSheet> createState() => _ConsentSheetState();
}

/// A decision being sent, kept to resend it with the same key after no
/// answer (and only then).
typedef _Pending = ({
  api.ConsentDecision decision,
  ConsentSnapshot seen,
  String key,
});

class _ConsentSheetState extends ConsumerState<ConsentSheet> {
  api.ConsentText? _text;
  bool _loadingText = true;
  bool _textFailed = false;
  api.ConsentAudience? _audience;
  bool _busy = false;
  String? _notice;
  bool _noticeIsError = false;
  _Pending? _pending;

  @override
  void initState() {
    super.initState();
    // The text's language is the app's, read from the context once built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadText();
    });
  }

  FamilyMember? get _member =>
      memberIn(ref.read(familyProfilesProvider), widget.profileId);

  Future<void> _loadText() async {
    final member = _member;
    if (member == null) {
      setState(() {
        _loadingText = false;
        _textFailed = true;
      });
      return;
    }
    final language = apiLanguageOf(context);
    setState(() {
      _loadingText = true;
      _textFailed = false;
    });
    final audience = member.healthDataConsentAudience;
    final result = await ref
        .read(consentRepositoryProvider)
        .getConsentText(
          api.ConsentPurpose.healthData,
          language,
          audience: audience,
        );
    if (!mounted) return;
    setState(() {
      _loadingText = false;
      switch (result) {
        case Ok(:final value):
          _text = value;
          _audience = audience;
        case Err():
          _text = null;
          _textFailed = true;
      }
    });
  }

  void _say(String text, {bool error = false}) => setState(() {
    _notice = text;
    _noticeIsError = error;
  });

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context);
    final name = _member?.name ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.consentDeclinedConfirmTitle),
        content: Text(l10n.consentMemberDeclinedBody(name)),
        actions: [
          TextButton(
            key: const Key('consent.decline.back'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.consentDeclinedConfirmBack),
          ),
          FilledButton(
            key: const Key('consent.decline.confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.consentDeclinedConfirmContinue),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _record(api.ConsentDecision.declined);
    }
  }

  Future<void> _record(api.ConsentDecision decision) async {
    final l10n = AppLocalizations.of(context);
    final text = _text;
    final member = _member;
    final seen = member?.rules.consentSnapshot;
    if (text == null || member == null || seen == null) {
      // Cached profile: the state the manager saw is unknown.
      _say(l10n.consentNeedsInternet, error: true);
      return;
    }
    final pending = _pending;
    final key =
        pending != null && pending.decision == decision && pending.seen == seen
        ? pending.key
        : randomUuidV4();
    _pending = (decision: decision, seen: seen, key: key);
    setState(() => _busy = true);
    final result = await ref
        .read(consentRepositoryProvider)
        .recordHealthDataConsent(
          member.id,
          decision: decision,
          textVersion: text.version,
          language: text.language,
          seen: seen,
          idempotencyKey: key,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        _pending = null;
        await ref.read(familyProfilesProvider.notifier).refresh();
        if (!mounted) return;
        Navigator.of(context).pop(
          decision == api.ConsentDecision.given
              ? ConsentOutcome.given
              : ConsentOutcome.declined,
        );
        return;
      case Err(failure: ConsentChangedFailure()):
        // Nothing was recorded. Read the member again and ask again.
        _pending = null;
        await ref.read(familyProfilesProvider.notifier).refresh();
        if (!mounted) return;
        final fresh = _member;
        if (fresh == null) {
          Navigator.of(context).pop(ConsentOutcome.notRecorded);
          return;
        }
        if (fresh.healthDataConsentAudience != _audience) await _loadText();
        if (!mounted) return;
        _say(l10n.consentChanged(fresh.name));
      case Err(:final failure)
          when failure.problemCode == ApiErrorCode.consentTextOutdated:
        _pending = null;
        await _loadText();
        if (!mounted) return;
        _say(l10n.consentTextUpdated);
      case Err(:final failure)
          when failure.problemCode == ApiErrorCode.guardianConfirmationRequired:
        _pending = null;
        _say(l10n.familyGuardianRequired, error: true);
      case Err(failure: NetworkFailure()):
        // No answer: the same decision may be resent with the same key.
        _say(l10n.consentNeedsInternet, error: true);
      case Err():
        _pending = null;
        _say(l10n.errorGenericBody, error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final member = memberIn(
      ref.watch(familyProfilesProvider),
      widget.profileId,
    );
    final name = member?.name ?? '';
    final text = _text;
    final dates = ref.watch(householdDateFormatterProvider);

    final body = <Widget>[
      if (text != null && text.isDraft) ...[
        _DraftRibbon(l10n.consentDraftRibbon),
        const SizedBox(height: SpacingTokens.m),
      ],
      if (member != null && member.isChild) ...[
        Text(l10n.consentMemberChildNote(name)),
        const SizedBox(height: SpacingTokens.m),
      ],
      if (widget.renewal) ...[
        InlineMessage(
          kind: InlineMessageKind.info,
          text: l10n.consentRenewalNote(name),
        ),
        const SizedBox(height: SpacingTokens.m),
      ],
      if (_notice != null) ...[
        InlineMessage(
          key: const Key('consent.notice'),
          kind: _noticeIsError
              ? InlineMessageKind.error
              : InlineMessageKind.info,
          text: _notice!,
        ),
        const SizedBox(height: SpacingTokens.m),
      ],
      if (_loadingText)
        Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: SpacingTokens.m),
            Expanded(child: Text(l10n.consentLoading)),
          ],
        )
      else if (text == null) ...[
        InlineMessage(text: l10n.consentLoadError),
      ] else ...[
        Semantics(
          header: true,
          child: Text(text.title, style: theme.textTheme.titleMedium),
        ),
        for (final section in text.sections) ...[
          const SizedBox(height: SpacingTokens.m),
          Text(section.heading, style: theme.textTheme.titleSmall),
          const SizedBox(height: SpacingTokens.xs),
          Text(section.body),
        ],
        const SizedBox(height: SpacingTokens.l),
        if (widget.rules.isEmpty && !widget.renewal) ...[
          Text(l10n.consentMemberNoRulesSummary(name)),
          const SizedBox(height: SpacingTokens.xs),
          Text(l10n.consentRulesNoRulesNote),
        ] else if (widget.rules.isNotEmpty)
          Wrap(
            spacing: SpacingTokens.s,
            runSpacing: SpacingTokens.s,
            children: [
              for (final rule in widget.rules)
                Chip(label: Text(rule.label(l10n, locale))),
            ],
          ),
        const SizedBox(height: SpacingTokens.m),
        Text(
          l10n.consentRulesVersion(
            text.version,
            dates.date(text.effectiveDate, locale.languageCode),
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    ];

    final List<Widget> buttons = text == null
        ? [
            if (_textFailed)
              OnboardingButton(
                key: const Key('consent.retry'),
                label: l10n.commonRetry,
                onPressed: _loadText,
              ),
            OnboardingButton(
              key: const Key('consent.continueWithout'),
              kind: OnboardingButtonKind.text,
              label: l10n.consentDeclinedConfirmContinue,
              onPressed: () =>
                  Navigator.of(context).pop(ConsentOutcome.notRecorded),
            ),
          ]
        : [
            OnboardingButton(
              key: const Key('consent.accept'),
              label: l10n.consentRulesAccept,
              loadingLabel: _busy ? l10n.consentSaving : null,
              onPressed: () => _record(api.ConsentDecision.given),
            ),
            OnboardingButton(
              key: const Key('consent.decline'),
              kind: OnboardingButtonKind.outlined,
              label: l10n.consentRulesDecline,
              onPressed: _busy ? null : _decline,
            ),
          ];

    return PopScope(
      canPop: !_busy,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.l,
                SpacingTokens.l,
                SpacingTokens.xs,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.consentMemberTitle(name),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('consent.close'),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.commonClose,
                    onPressed: _busy
                        ? null
                        : () =>
                              Navigator.of(context)
                                  .pop(ConsentOutcome.notRecorded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: body,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.l,
                0,
                SpacingTokens.l,
                SpacingTokens.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, button) in buttons.indexed) ...[
                    if (i > 0) const SizedBox(height: SpacingTokens.s),
                    button,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftRibbon extends StatelessWidget {
  const _DraftRibbon(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final app = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: app.infoContainer,
        borderRadius: BorderRadius.circular(RadiusTokens.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.s),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: app.onInfoContainer),
        ),
      ),
    );
  }
}
