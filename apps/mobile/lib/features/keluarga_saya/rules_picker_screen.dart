// F2r Rules step for a member and F4 Add hard rule (PRF-03, PRF-04, PRF-08;
// screens.md F2r and F4). Full screen, so the groups and the pinned buttons
// fit at 200% text.
//
// - Aturan makan: halal, vegetarian, vegan.
// - Alergi: the standard list from the API in its order, never hard-coded
//   (listStandardAllergens). If it cannot load, the group shows an error
//   and a retry; nothing is offered in its place.
// - Lainnya: free text, with the doctor's-restriction switch. There is no
//   ingredient search yet (QUESTIONS #49), so written rules are saved
//   unmapped and the screen says what that means: every recipe for the
//   member gets "Cek label" until our team matches it (SAF-09).
//
// Rules can only be added here; removing is on F3. Rules already saved for
// the member are shown ticked and cannot be picked twice.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_result.dart';
import '../../core/theme/tokens.dart';
import '../../data/family_profiles_state.dart';
import '../../data/models/family.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart';
import 'consent_sheet.dart';
import 'family_flows.dart';
import 'labels.dart';
import 'rule_draft.dart';
import 'widgets/family_widgets.dart';

enum RulesPickerMode {
  /// F2r: the first rules for a member whose consent is not given, with
  /// "Tidak ada aturan" and "Nanti saja".
  firstRules,

  /// F4: more rules for a member whose consent is given.
  addRule,
}

/// Opens the picker over everything (root navigator). Returns true when the
/// member's rules or consent changed.
Future<bool> openRulesPicker(
  BuildContext context, {
  required String profileId,
  required RulesPickerMode mode,
}) async {
  final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => RulesPickerScreen(profileId: profileId, mode: mode),
    ),
  );
  return changed ?? false;
}

class RulesPickerScreen extends ConsumerStatefulWidget {
  const RulesPickerScreen({
    super.key,
    required this.profileId,
    required this.mode,
  });

  final String profileId;
  final RulesPickerMode mode;

  @override
  ConsumerState<RulesPickerScreen> createState() => _RulesPickerScreenState();
}

class _RulesPickerScreenState extends ConsumerState<RulesPickerScreen> {
  final _picked = <RuleDraft>[];
  final _keys = <RuleDraft, String>{};
  final _otherText = TextEditingController();
  bool _otherOpen = false;
  bool _medical = false;
  String? _otherError;
  bool _saving = false;

  /// The consent sheet is open over this screen: no spinner under it.
  bool _consentOpen = false;
  String? _message;

  static const _maxText = 200;

  @override
  void dispose() {
    _otherText.dispose();
    super.dispose();
  }

  List<api.HardRule> _saved(FamilyMember member) => switch (member.rules) {
    RulesSaved(:final items) => items,
    _ => const [],
  };

  bool _isSaved(FamilyMember member, RuleDraft draft) =>
      _saved(member).any(draft.sameAs);

  void _toggle(RuleDraft draft) => setState(() {
    _message = null;
    if (!_picked.remove(draft)) _picked.add(draft);
  });

  void _addOther(FamilyMember member) {
    final l10n = AppLocalizations.of(context);
    final text = _otherText.text.trim();
    if (text.isEmpty) {
      setState(
        () => _otherError = _medical
            ? l10n.rulesMedicalNeedText
            : l10n.errorFieldRequired,
      );
      return;
    }
    final draft = RuleDraft.written(text, medical: _medical);
    if (_picked.contains(draft) || _isSaved(member, draft)) {
      setState(() => _otherError = l10n.errorFieldDuplicate);
      return;
    }
    setState(() {
      _picked.add(draft);
      _otherText.clear();
      _medical = false;
      _otherError = null;
      _otherOpen = false;
      _message = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final member = memberIn(ref.read(familyProfilesProvider), widget.profileId);
    if (member == null) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    final drafts = [..._picked];
    final result = await saveRulesWithConsent(
      context,
      ref,
      profileId: widget.profileId,
      drafts: drafts,
      keys: _keys,
      onConsentSheet: (open) {
        if (mounted) setState(() => _consentOpen = open);
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result.consent) {
      case ConsentOutcome.notRecorded:
        // Closed without deciding: keep the picks, stay here.
        if (result.offline) setState(() => _message = l10n.familyRulesOffline);
        return;
      case ConsentOutcome.declined:
        Navigator.of(context).pop(true);
        return;
      case ConsentOutcome.given:
        break;
    }
    if (result.complete) {
      if (result.saved > 0) showFamilySnack(context, l10n.familyRulesSaved);
      if (result.duplicates > 0 && widget.mode == RulesPickerMode.addRule) {
        showFamilySnack(context, l10n.familyRulesDuplicate(member.name));
      }
      Navigator.of(context).pop(true);
      return;
    }
    // Some rules were not saved: keep only those, say which.
    setState(() {
      _picked
        ..clear()
        ..addAll(result.failed);
      _message = result.offline
          ? l10n.familyRulesOffline
          : l10n.onboardingRulesSaveFailed(
              result.failed.length,
              result.failed.map((d) => d.label(l10n, locale)).join(', '),
            );
    });
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
    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(SpacingTokens.l),
          child: Text(l10n.errorApiNotFound),
        ),
      );
    }
    final offline = member.rules is RulesNotLoaded;
    final first = widget.mode == RulesPickerMode.firstRules;
    final enabled = !offline && !_saving;
    final allergens = ref.watch(standardAllergensProvider);

    Widget chip(RuleDraft draft, String label) {
      final saved = _isSaved(member, draft);
      return FilterChip(
        key: Key(
          'rules.pick.${draft.type.toJson()}.${draft.allergen?.toJson()}',
        ),
        label: Text(label),
        selected: saved || _picked.contains(draft),
        onSelected: enabled && !saved ? (_) => _toggle(draft) : null,
      );
    }

    Widget group(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: SpacingTokens.s),
          ...children,
        ],
      ),
    );

    final written = _picked.where((d) => d.isWritten).toList();

    final children = <Widget>[
      if (offline) ...[
        InlineMessage(
          kind: InlineMessageKind.info,
          text: l10n.familyRulesOffline,
        ),
        const SizedBox(height: SpacingTokens.l),
      ],
      group(l10n.onboardingRulesGroupDiet, [
        Wrap(
          spacing: SpacingTokens.s,
          runSpacing: SpacingTokens.s,
          children: [
            for (final type in dietRuleTypes)
              chip(RuleDraft.diet(type), dietLabel(l10n, type)),
          ],
        ),
      ]),
      group(l10n.onboardingRulesGroupAllergy, [
        Text(l10n.onboardingRulesAllergyHelp),
        const SizedBox(height: SpacingTokens.s),
        switch (allergens) {
          AsyncData(value: Ok(:final value)) => Wrap(
            spacing: SpacingTokens.s,
            runSpacing: SpacingTokens.s,
            children: [
              for (final code in value.items)
                chip(RuleDraft.allergy(code), allergenLabel(l10n, code)),
            ],
          ),
          AsyncData(value: Err()) || AsyncError() => ErrorPanel(
            title: null,
            body: l10n.familyRulesAllergensLoadError,
            retryKey: const Key('rules.allergens.retry'),
            onRetry: () => ref.invalidate(standardAllergensProvider),
          ),
          _ => const SkeletonBlock(height: 96),
        },
      ]),
      group(l10n.onboardingRulesGroupOther, [
        for (final draft in written) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InputChip(
              label: Text(draft.label(l10n, locale)),
              onDeleted: enabled ? () => _toggle(draft) : null,
              deleteButtonTooltipMessage: l10n.familyLikesRemoveTooltip(
                draft.label(l10n, locale),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          InlineMessage(
            kind: InlineMessageKind.info,
            text: l10n.rulesFreeTextUnmappedAll(draft.freeText!, member.name),
          ),
          const SizedBox(height: SpacingTokens.m),
        ],
        if (!_otherOpen)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('rules.other.open'),
              onPressed: enabled
                  ? () => setState(() => _otherOpen = true)
                  : null,
              child: Text(l10n.onboardingRulesAddOther),
            ),
          )
        else ...[
          TextField(
            key: const Key('rules.other.field'),
            controller: _otherText,
            enabled: enabled,
            maxLength: _maxText,
            textCapitalization: TextCapitalization.sentences,
            // Health data: the keyboard must not learn, suggest or change
            // it (security review T-028 M1).
            enableIMEPersonalizedLearning: false,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.familyRulesOtherLabel,
              hintText: l10n.onboardingRulesOtherHint,
              errorText: _otherError,
            ),
            onSubmitted: (_) => _addOther(member),
          ),
          SwitchListTile(
            key: const Key('rules.other.medical'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.onboardingRulesMedicalToggle),
            value: _medical,
            onChanged: enabled ? (v) => setState(() => _medical = v) : null,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonal(
              key: const Key('rules.other.add'),
              onPressed: enabled ? () => _addOther(member) : null,
              child: Text(l10n.commonAdd),
            ),
          ),
        ],
      ]),
      if (first && !offline) ...[
        Text(
          l10n.familyRulesStepLaterNote(member.name),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: SpacingTokens.l),
      ],
      if (_message != null) InlineMessage(text: _message!),
    ];

    final bottom = <Widget>[
      OnboardingButton(
        key: const Key('rules.save'),
        label: first ? l10n.commonContinue : l10n.familyRulesSaveAction,
        loadingLabel: _saving && !_consentOpen ? l10n.consentSaving : null,
        onPressed: enabled && _picked.isNotEmpty ? _save : null,
      ),
      if (first && !offline)
        OnboardingButton(
          key: const Key('rules.none'),
          kind: OnboardingButtonKind.outlined,
          label: l10n.onboardingRulesNone,
          onPressed: enabled && _picked.isEmpty ? _save : null,
        ),
      if (first)
        OnboardingButton(
          key: const Key('rules.later'),
          kind: OnboardingButtonKind.text,
          label: l10n.commonLater,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
    ];

    return PopScope(
      canPop: !_saving,
      child: OnboardingScaffold(
        title: first
            ? l10n.familyRulesStepTitle(member.name)
            : l10n.familyRulesAddTitle(member.name),
        bottom: bottom,
        children: children,
      ),
    );
  }
}
