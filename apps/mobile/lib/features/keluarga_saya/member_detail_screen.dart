// F3 Profile detail with F4r (remove a rule), F5 (taste, likes, portions)
// and F6 (delete) (PRF-01, PRF-03 to PRF-08, PRF-18, SET-03, SET-07;
// screens.md F3 to F6).
//
// Fail closed (QUESTIONS #39): the rules section shows saved rules only when
// they came from the API with a given consent. Rules that could not be read
// show an error, and a profile from the phone's cache shows that its rules
// appear when connected, never "no rules". Hard rules and consent are never
// cached on the phone. No line here says a person or a food is "aman": rule
// states are neutral notes, not safety badges.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../app/widgets/section_scaffold.dart';
import '../../core/api/api_error_text.dart';
import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../core/theme/tokens.dart';
import '../../core/time/household_time.dart';
import '../../data/family_profiles_state.dart';
import '../../data/models/family.dart';
import '../../data/repositories/consent_repository.dart';
import '../../data/repositories/hard_rules_repository.dart';
import '../../data/repositories/profiles_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart';
import 'consent_sheet.dart';
import 'family_flows.dart';
import 'labels.dart';
import 'profile_form_screen.dart';
import 'rules_picker_screen.dart';
import 'widgets/family_widgets.dart';
import 'widgets/preference_sheets.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailState();
}

class _MemberDetailState extends ConsumerState<MemberDetailScreen> {
  bool _busy = false;

  FamilyProfilesController get _family =>
      ref.read(familyProfilesProvider.notifier);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------ Profile

  Future<void> _edit(FamilyMember member) => _run(() async {
    final result = await openProfileForm(context, member: member);
    if (!mounted || result == null) return;
    showFamilySnack(context, AppLocalizations.of(context).familyProfileSaved);
    // Adult ↔ child with stored rules: ask again in the same flow (Q62).
    if (result.renewalRequired) await _renew(result.member);
  });

  Future<void> _delete(FamilyMember member) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.familyDeleteTitle(member.name)),
        content: Text(l10n.familyDeleteBody(member.name)),
        actions: [
          TextButton(
            key: const Key('member.delete.cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('member.delete.confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.familyDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Read before the screen closes: the refresh runs after the pop.
    final family = _family;
    await _run(() async {
      final result = await ref
          .read(profilesRepositoryProvider)
          .deleteProfile(member.id);
      if (!mounted) return;
      switch (result) {
        case Ok():
          Navigator.of(context).pop();
          showFamilySnack(context, l10n.familyDeleteDone(member.name));
          await family.refresh();
        case Err(failure: NetworkFailure()):
          showFamilySnack(context, l10n.familyDeleteOffline);
        case Err(:final failure)
            when failure.problemCode == ApiErrorCode.managerProfileNotDeletable:
          showFamilySnack(context, l10n.familyDeleteManagerNote);
        case Err(:final failure)
            when failure.problemCode == ApiErrorCode.notFound:
          Navigator.of(context).pop();
          showFamilySnack(context, l10n.errorApiNotFound);
          await family.refresh();
        case Err(:final failure):
          showFamilySnack(context, ApiErrorText.of(l10n, failure).body);
      }
    });
  }

  // ------------------------------------------------------------ Rules

  Future<void> _pickRules(FamilyMember member, RulesPickerMode mode) =>
      _run(() async {
        await openRulesPicker(context, profileId: member.id, mode: mode);
      });

  /// The member changed between adult and child: the stored rules still
  /// apply, and the manager decides again on the matching text (QUESTIONS
  /// #62) before new rules can be saved.
  Future<void> _renew(FamilyMember member) async {
    final rules = member.rules;
    if (rules is! RulesSaved) return;
    await showMemberConsentSheet(
      context,
      profileId: member.id,
      rules: draftsOf(rules.items),
      renewal: true,
    );
  }

  Future<void> _removeRule(FamilyMember member, api.HardRule rule) async {
    final l10n = AppLocalizations.of(context);
    final label = hardRuleLabel(l10n, Localizations.localeOf(context), rule);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.familyRulesRemoveTitle(label, member.name)),
        content: Text(l10n.familyRulesRemoveBody(label, member.name)),
        actions: [
          TextButton(
            key: const Key('rule.remove.cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('rule.remove.confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.familyRulesRemoveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      final result = await ref
          .read(hardRulesRepositoryProvider)
          .deleteHardRule(member.id, rule.id);
      if (!mounted) return;
      switch (result) {
        case Ok():
          await _family.refresh();
        case Err(failure: NetworkFailure()):
          showFamilySnack(context, l10n.familyRulesOffline);
        case Err(:final failure)
            when failure.problemCode == ApiErrorCode.notFound:
          showFamilySnack(context, l10n.errorApiNotFound);
          await _family.refresh();
        case Err(:final failure):
          showFamilySnack(context, ApiErrorText.of(l10n, failure).body);
      }
    });
  }

  void _why(FamilyMember member) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.rulesFreeTextWhy,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.commonClose,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.s),
            Text(l10n.rulesFreeTextWhyBody(member.name)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ Consent

  Future<void> _withdraw(FamilyMember member) async {
    final l10n = AppLocalizations.of(context);
    final seen = member.rules.consentSnapshot;
    if (seen == null) {
      showFamilySnack(context, l10n.consentNeedsInternet);
      return;
    }
    final days = ref
        .read(appConfigProvider)
        .get(ConfigKeys.consentWithdrawalDeletionDays);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.consentWithdrawTitle(member.name)),
        content: Text(l10n.consentWithdrawBody(member.name, days)),
        actions: [
          TextButton(
            key: const Key('consent.withdraw.cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('consent.withdraw.confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.consentWithdrawConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      final result = await ref
          .read(consentRepositoryProvider)
          .withdrawHealthDataConsent(member.id, seen: seen);
      if (!mounted) return;
      final dates = ref.read(householdDateFormatterProvider);
      final language = Localizations.localeOf(context).languageCode;
      switch (result) {
        case Ok(:final value):
          final due = value.deletionDueBy;
          showFamilySnack(
            context,
            due == null
                ? l10n.familyRulesNotSavedExplainer(member.name)
                : l10n.consentWithdrawDoneDate(
                    member.name,
                    dates.date(due, language),
                  ),
          );
          await _family.refresh();
        case Err(failure: ConsentChangedFailure()):
          // Nothing changed on the server. Show the current state.
          await _family.refresh();
          if (mounted) {
            showFamilySnack(context, l10n.consentChanged(member.name));
          }
        case Err(:final failure)
            when failure.problemCode == ApiErrorCode.consentNotActive:
          await _family.refresh();
          if (mounted) showFamilySnack(context, l10n.consentNotActive);
        case Err(failure: NetworkFailure()):
          showFamilySnack(context, l10n.consentNeedsInternet);
        case Err(:final failure):
          showFamilySnack(context, ApiErrorText.of(l10n, failure).body);
      }
    });
  }

  // ------------------------------------------------------------ Build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(familyProfilesProvider);
    final member = memberIn(state, widget.profileId);

    final Widget body;
    String title = l10n.familyTitle;
    switch (state) {
      case FamilyLoading():
        body = const _Skeleton();
      case FamilyRulesUnavailable():
        body = _Padded(
          ErrorPanel(
            key: const Key('member.rulesUnavailable'),
            title: l10n.errorRulesUnavailableTitle,
            body: l10n.errorRulesUnavailableBody,
            onRetry: () => _family.reload(),
          ),
        );
      case FamilyLoadFailed(:final failure):
        final text = ApiErrorText.of(l10n, failure);
        body = _Padded(
          ErrorPanel(
            title: text.title,
            body: text.body,
            onRetry: () => _family.reload(),
          ),
        );
      case FamilyLoaded() when member == null:
        body = _Padded(Text(l10n.errorApiNotFound));
      case FamilyLoaded():
        title = member!.name;
        body = _content(context, member);
    }
    return SectionScaffold(title: title, isTabRoot: false, body: body);
  }

  Widget _content(BuildContext context, FamilyMember member) {
    final l10n = AppLocalizations.of(context);
    final cached = member.details == null;
    return RefreshIndicator(
      onRefresh: _family.refresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
        children: [
          ContentFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cached) ...[
                  InlineMessage(
                    kind: InlineMessageKind.info,
                    text: l10n.familyListOffline,
                  ),
                  const SizedBox(height: SpacingTokens.m),
                ],
                _header(context, member),
                const SizedBox(height: SpacingTokens.m),
                _rules(context, member),
                if (member.details case final details?) ...[
                  const SizedBox(height: SpacingTokens.m),
                  _preferences(context, member, details),
                  const SizedBox(height: SpacingTokens.m),
                  _likes(context, member, details),
                  const SizedBox(height: SpacingTokens.m),
                  _portions(context, member, details),
                ],
                const SizedBox(height: SpacingTokens.m),
                _consent(context, member),
                if (!member.isManager && !cached) ...[
                  const SizedBox(height: SpacingTokens.l),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      key: const Key('member.delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _busy ? null : () => _delete(member),
                      child: Text(l10n.familyDeleteAction(member.name)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, FamilyMember member) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: member.name,
      editKey: const Key('member.edit'),
      onEdit: _busy || member.details == null ? null : () => _edit(member),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MemberAvatar(
              profileId: member.id,
              name: member.name,
              avatar: member.avatar,
              size: 64,
            ),
            const SizedBox(width: SpacingTokens.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ageGroupLabel(l10n, member.ageGroup),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Wrap(
                    spacing: SpacingTokens.s,
                    runSpacing: SpacingTokens.xs,
                    children: [
                      if (member.isManager) TextTag(l10n.familyCardYou),
                      if (member.isChild) TextTag(l10n.familyCardChildTag),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (member.isChild) ...[
          const SizedBox(height: SpacingTokens.m),
          Text(l10n.consentChildNote, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }

  Widget _rules(BuildContext context, FamilyMember member) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rules = member.rules;
    final children = <Widget>[
      Text(l10n.familyRulesExplainer, style: theme.textTheme.bodyMedium),
      const SizedBox(height: SpacingTokens.m),
    ];
    switch (rules) {
      case RulesNotLoaded():
        children.addAll([
          NeutralNote(text: l10n.familyRulesNotLoaded(member.name)),
          const SizedBox(height: SpacingTokens.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('member.rules.retry'),
              onPressed: _family.refresh,
              child: Text(l10n.commonRetry),
            ),
          ),
        ]);
      case RulesNotSaved(:final status, :final deletionDueBy):
        final notSet = status == ConsentStatus.none;
        children.addAll([
          NeutralNote(
            key: const Key('member.rules.notSaved'),
            text: notSet
                ? l10n.familyRulesNotSetExplainer(member.name)
                : l10n.familyRulesNotSavedExplainer(member.name),
          ),
          if (status == ConsentStatus.withdrawn && deletionDueBy != null) ...[
            const SizedBox(height: SpacingTokens.s),
            Text(
              l10n.familyRulesDeletionDue(_date(deletionDueBy)),
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: SpacingTokens.m),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonal(
              key: const Key('member.rules.start'),
              onPressed: _busy
                  ? null
                  : () => _pickRules(member, RulesPickerMode.firstRules),
              child: Text(
                notSet ? l10n.familyCardFillRules : l10n.consentGiveAction,
              ),
            ),
          ),
        ]);
      case RulesSaved(:final items, :final renewalRequired):
        if (renewalRequired) {
          children.addAll([
            InlineMessage(
              key: const Key('member.rules.renewal'),
              kind: InlineMessageKind.info,
              text: l10n.familyRulesRenewalExplainer(member.name),
            ),
            const SizedBox(height: SpacingTokens.s),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonal(
                key: const Key('member.rules.renew'),
                onPressed: _busy ? null : () => _run(() => _renew(member)),
                child: Text(l10n.consentRenewAction),
              ),
            ),
            const SizedBox(height: SpacingTokens.m),
          ]);
        }
        if (items.isEmpty) {
          children.add(Text(l10n.familyDetailHintAddRules));
        }
        for (final group in RuleGroup.values) {
          final inGroup = items
              .where((r) => ruleGroupOf(r.type) == group)
              .toList();
          if (inGroup.isEmpty) continue;
          children.addAll([
            Text(
              ruleGroupLabel(l10n, group),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: SpacingTokens.xs),
            for (final rule in inGroup) _ruleRow(context, member, rule),
            const SizedBox(height: SpacingTokens.s),
          ]);
        }
        children.addAll([
          const SizedBox(height: SpacingTokens.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonal(
              key: const Key('member.rules.add'),
              onPressed: _busy || !rules.allowsNewHealthData
                  ? null
                  : () => _pickRules(member, RulesPickerMode.addRule),
              child: Text(l10n.familyRulesAdd),
            ),
          ),
        ]);
    }
    return SectionCard(title: l10n.familyRulesTitle, children: children);
  }

  Widget _ruleRow(
    BuildContext context,
    FamilyMember member,
    api.HardRule rule,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final label = hardRuleLabel(l10n, locale, rule);
    final mapping = rule.mapping;
    final lines = <Widget>[];
    if (rule.type == api.HardRuleType.allergy && rule.allergen == null) {
      lines.add(Text(l10n.rulesUpdateApp, style: theme.textTheme.bodySmall));
    }
    if (isAwaitingMapping(rule)) {
      final proposed = mapping?.status == api.MappingStatus.proposed;
      lines.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              proposed ? Icons.help_outline : Icons.schedule,
              size: IconSizeTokens.badgeCompact,
            ),
            const SizedBox(width: SpacingTokens.s),
            Expanded(
              child: Text(
                l10n.rulesFreeTextPendingAll(member.name),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
      lines.add(
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: Key('rule.why.${rule.id}'),
            onPressed: () => _why(member),
            child: Text(l10n.rulesFreeTextWhy),
          ),
        ),
      );
    } else if (mapping != null && mapping.ingredients.isNotEmpty) {
      final names = ingredientNames(locale, mapping.ingredients);
      lines.add(
        Text(
          mapping.confirmedBy == api.MappingConfirmer.manager
              ? l10n.rulesMappingByYou(names)
              : l10n.rulesMappingByTeam(names),
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputChip(
            key: Key('rule.${rule.id}'),
            label: Text(label),
            onDeleted: _busy ? null : () => _removeRule(member, rule),
            deleteButtonTooltipMessage: l10n.familyRulesRemoveTooltip(label),
          ),
          ...lines,
        ],
      ),
    );
  }

  Widget _preferences(
    BuildContext context,
    FamilyMember member,
    MemberDetails details,
  ) {
    final l10n = AppLocalizations.of(context);
    final prefs = details.preferences;
    final theme = Theme.of(context);
    final spice = prefs.spiceLevel;
    final chosen = [
      for (final v in lessOfValues)
        if (prefs.lessOf.contains(v)) lessOfLabel(l10n, v),
      for (final v in textureValues)
        if (prefs.textures.contains(v)) textureLabel(l10n, v),
    ];
    return SectionCard(
      title: l10n.familyPrefsTitle,
      editKey: const Key('member.prefs.edit'),
      onEdit: _busy
          ? null
          : () => _run(
              () =>
                  showPreferencesSheet(context, member: member, current: prefs),
            ),
      children: [
        Text(l10n.familyPrefsExplainer),
        const SizedBox(height: SpacingTokens.s),
        Text(l10n.onboardingTasteSpice, style: theme.textTheme.titleSmall),
        Text(
          spice == null ? l10n.familyPrefsNotChosen : spiceLabel(l10n, spice),
        ),
        const SizedBox(height: SpacingTokens.s),
        if (chosen.isNotEmpty)
          Wrap(
            spacing: SpacingTokens.s,
            runSpacing: SpacingTokens.s,
            children: [for (final c in chosen) Chip(label: Text(c))],
          ),
      ],
    );
  }

  Widget _likes(
    BuildContext context,
    FamilyMember member,
    MemberDetails details,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final likes = details.likesDislikes;
    final hasAny = likes.likes.isNotEmpty || likes.dislikes.isNotEmpty;
    Widget list(String title, List<api.FoodRef> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: SpacingTokens.xs),
        if (items.isEmpty)
          Text(l10n.familyNothingYet)
        else
          Wrap(
            spacing: SpacingTokens.s,
            runSpacing: SpacingTokens.s,
            children: [
              for (final item in items)
                Chip(label: Text(localized(locale, item.displayName))),
            ],
          ),
        const SizedBox(height: SpacingTokens.m),
      ],
    );
    return SectionCard(
      title: l10n.familyLikesTitle,
      editKey: const Key('member.likes.edit'),
      onEdit: _busy || !hasAny
          ? null
          : () => _run(
              () => showLikesSheet(context, member: member, current: likes),
            ),
      children: [
        list(l10n.familyLikesLike, likes.likes),
        list(l10n.familyLikesDislike, likes.dislikes),
        Text(l10n.familyLikesNotAllergy, style: theme.textTheme.bodyMedium),
        const SizedBox(height: SpacingTokens.s),
        NeutralNote(text: l10n.familyLikesSearchUnavailable),
      ],
    );
  }

  Widget _portions(
    BuildContext context,
    FamilyMember member,
    MemberDetails details,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = details.portions;
    Widget row(String label, api.PortionSize size, bool isDefault) => Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          Wrap(
            spacing: SpacingTokens.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(portionLabel(l10n, size), style: theme.textTheme.bodyLarge),
              if (isDefault) TextTag(l10n.familyPortionDefault),
            ],
          ),
        ],
      ),
    );
    return SectionCard(
      title: l10n.familyPortionTitle,
      editKey: const Key('member.portions.edit'),
      onEdit: _busy
          ? null
          : () => _run(
              () => showPortionsSheet(context, member: member, current: p),
            ),
      children: [
        row(l10n.familyPortionMeal, p.portionSize, p.portionSizeIsDefault),
        row(l10n.familyPortionRice, p.ricePortion, p.ricePortionIsDefault),
      ],
    );
  }

  Widget _consent(BuildContext context, FamilyMember member) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rules = member.rules;
    final guardian = member.details?.guardianConfirmation;
    final String? state = switch (rules) {
      RulesSaved(:final consent) => l10n.consentStateGiven(
        consent.decidedAt == null ? '' : _date(consent.decidedAt!),
        consent.textVersion ?? '',
      ),
      RulesNotSaved(status: ConsentStatus.none) => l10n.consentStateNone,
      RulesNotSaved(status: ConsentStatus.withdrawn, :final decidedAt) =>
        l10n.consentStateWithdrawnDue(
          decidedAt == null ? '' : _date(decidedAt),
          rules.deletionDueBy == null ? '' : _date(rules.deletionDueBy!),
        ),
      RulesNotSaved(:final decidedAt) => l10n.consentStateDeclined(
        decidedAt == null ? '' : _date(decidedAt),
      ),
      RulesNotLoaded() => null,
    };
    return SectionCard(
      title: l10n.familyConsentLink(member.name),
      children: [
        if (state != null)
          Text(
            state,
            key: const Key('member.consent.state'),
            style: theme.textTheme.bodyLarge,
          ),
        if (guardian != null) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(l10n.consentStateGuardian(_date(guardian.confirmedAt))),
        ],
        if (rules is RulesSaved) ...[
          const SizedBox(height: SpacingTokens.m),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
              key: const Key('member.consent.withdraw'),
              onPressed: _busy ? null : () => _withdraw(member),
              child: Text(l10n.consentWithdrawAction),
            ),
          ),
        ],
      ],
    );
  }

  String _date(DateTime instant) => ref
      .read(householdDateFormatterProvider)
      .date(instant, Localizations.localeOf(context).languageCode);
}

class _Padded extends StatelessWidget {
  const _Padded(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
    children: [ContentFrame(child: child)],
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
    children: const [
      ContentFrame(
        child: Column(
          children: [
            SkeletonBlock(height: 120),
            SizedBox(height: SpacingTokens.m),
            SkeletonBlock(height: 160),
            SizedBox(height: SpacingTokens.m),
            SkeletonBlock(height: 120),
          ],
        ),
      ),
    ],
  );
}
