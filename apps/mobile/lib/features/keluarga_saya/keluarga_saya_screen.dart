// F1 Keluarga Saya list (PRF-01, PRF-02, PRF-18, ACC-08; screens.md F1).
//
// One card per profile, the manager's first, each with one rules line from
// the member's consent state (contract-alignment.md 1). The neutral lines
// never use the safety colors or icons, and no line says a member is
// "aman". Fail closed (QUESTIONS #39): when the rules cannot be read the
// list shows the error instead of any rules line, never "Belum ada aturan
// wajib". A list from the phone's cache has names only.
//
// The family state belongs to the signed-in account (familyProfilesProvider
// watches currentAccountIdProvider), so another account never sees it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/app_section.dart';
import '../../app/shell/app_shell.dart' show isCompactWindow;
import '../../app/widgets/section_scaffold.dart';
import '../../core/api/api_error_text.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/tokens.dart';
import '../../data/family_profiles_state.dart';
import '../../data/models/family.dart';
import '../../data/models/sourced.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart';
import 'labels.dart';
import 'profile_form_screen.dart';
import 'rules_picker_screen.dart';
import 'widgets/family_widgets.dart';

/// The detail route of a member (F3), under the Keluarga section.
String memberPath(String profileId) =>
    '${AppSection.family.path}/member/$profileId';

class KeluargaSayaScreen extends ConsumerWidget {
  const KeluargaSayaScreen({super.key});

  Future<void> _add(BuildContext context, FamilyProfiles profiles) async {
    final result = await openProfileForm(
      context,
      memberCount: profiles.members.length,
    );
    if (result == null || !context.mounted) return;
    final id = result.member.id;
    // F3 opens for the new member, and F2r asks at once for the rules, so
    // no member is left without the question (screens.md F2r).
    unawaited(context.push(memberPath(id)));
    await openRulesPicker(
      context,
      profileId: id,
      mode: RulesPickerMode.firstRules,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(familyProfilesProvider);
    final family = ref.read(familyProfilesProvider.notifier);

    final Widget body = switch (state) {
      FamilyLoading() => const _Skeleton(),
      FamilyRulesUnavailable() => _Scroll(
        children: [
          ErrorPanel(
            key: const Key('family.rulesUnavailable'),
            title: l10n.errorRulesUnavailableTitle,
            body: l10n.errorRulesUnavailableBody,
            retryKey: const Key('family.retry'),
            onRetry: family.reload,
          ),
        ],
      ),
      FamilyLoadFailed(:final failure) => _Scroll(
        children: [
          ErrorPanel(
            key: const Key('family.error'),
            title: ApiErrorText.of(l10n, failure).title,
            body: ApiErrorText.of(l10n, failure).body,
            retryKey: const Key('family.retry'),
            onRetry: family.reload,
          ),
        ],
      ),
      FamilyLoaded(:final profiles) => RefreshIndicator(
        onRefresh: family.refresh,
        child: _list(context, profiles),
      ),
    };

    final profiles = state is FamilyLoaded ? state.profiles : null;
    final showFab =
        profiles != null && !isCompactWindow(context) && _canAdd(profiles);
    return SectionScaffold(
      title: l10n.familyTitle,
      body: body,
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              key: const Key('family.add.fab'),
              onPressed: () => _add(context, profiles),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.familyAddAction),
            )
          : null,
    );
  }

  static bool _atLimit(FamilyProfiles p) =>
      p.maxProfiles != null && p.members.length >= p.maxProfiles!;

  /// Adding needs the API (no offline outbox yet) and room under the limit.
  static bool _canAdd(FamilyProfiles p) =>
      p.source is FromNetwork && !_atLimit(p);

  Widget _list(BuildContext context, FamilyProfiles profiles) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cached = profiles.source is FromCache;
    final onlyManager = profiles.members.length <= 1;
    return _Scroll(
      children: [
        if (cached) ...[
          InlineMessage(
            key: const Key('family.offline'),
            kind: InlineMessageKind.info,
            text: l10n.familyListOffline,
          ),
          const SizedBox(height: SpacingTokens.m),
        ],
        Text(
          l10n.familyListCount(profiles.members.length),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: SpacingTokens.m),
        for (final member in profiles.members) ...[
          _MemberCard(member: member),
          const SizedBox(height: SpacingTokens.m),
        ],
        if (onlyManager && !cached) ...[
          _EmptyCard(onAdd: () => _add(context, profiles)),
          const SizedBox(height: SpacingTokens.m),
        ] else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonal(
              key: const Key('family.add'),
              onPressed: _canAdd(profiles)
                  ? () => _add(context, profiles)
                  : null,
              child: Text(l10n.familyAddAction),
            ),
          ),
        if (_atLimit(profiles)) ...[
          const SizedBox(height: SpacingTokens.s),
          Text(l10n.familyListLimitReached(profiles.maxProfiles!)),
        ],
        // Room above the FAB on wider windows.
        if (!isCompactWindow(context)) const SizedBox(height: 88),
      ],
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
    children: [
      ContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ],
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const _Scroll(
    children: [
      SkeletonBlock(),
      SizedBox(height: SpacingTokens.m),
      SkeletonBlock(),
      SizedBox(height: SpacingTokens.m),
      SkeletonBlock(),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      title: l10n.familyEmptyTitle,
      children: [
        Text(l10n.familyEmptyBody),
        const SizedBox(height: SpacingTokens.m),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonal(
            key: const Key('family.add'),
            onPressed: onAdd,
            child: Text(l10n.familyAddAction),
          ),
        ),
      ],
    );
  }
}

/// The rules line of a card (screens.md F1, "Rules line per consent state").
/// [neutral] lines use the neutral note; [action] opens F2r.
typedef _RulesLine = ({String text, bool neutral, String? action});

_RulesLine _rulesLine(
  AppLocalizations l10n,
  Locale locale,
  MemberRules rules,
) => switch (rules) {
  RulesSaved(:final items) when items.isEmpty => (
    text: l10n.familyCardNoRules,
    neutral: false,
    action: null,
  ),
  RulesSaved(:final items) => (
    text: items.map((r) => hardRuleLabel(l10n, locale, r)).join(' · '),
    neutral: false,
    action: null,
  ),
  RulesNotSaved(status: ConsentStatus.none) => (
    text: l10n.familyCardRulesNotSet,
    neutral: true,
    action: l10n.familyCardFillRules,
  ),
  RulesNotSaved() => (
    text: l10n.familyCardRulesNotSaved,
    neutral: true,
    action: l10n.consentGiveAction,
  ),
  RulesNotLoaded() => (
    text: l10n.familyCardRulesOffline,
    neutral: true,
    action: null,
  ),
};

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final app = AppColors.of(context);
    final rules = member.rules;
    final line = _rulesLine(l10n, locale, rules);
    final pending = rules is RulesSaved && rules.items.any(isAwaitingMapping);
    final renewal = rules is RulesSaved && rules.renewalRequired;
    final age = ageGroupLabel(l10n, member.ageGroup);

    // TalkBack: "{name}, {age group}, {Anak?}, {rules line}" (screens.md F1).
    final semantics = [
      member.name,
      if (member.isManager) l10n.familyCardYou,
      age,
      if (member.isChild) l10n.familyCardChildTag,
      line.text,
      if (pending) l10n.familyCardRulePending,
      if (renewal) l10n.familyCardRenewal,
    ].join(', ');

    return Card(
      key: Key('family.card.${member.id}'),
      margin: EdgeInsets.zero,
      color: app.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        side: BorderSide(color: app.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: semantics,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => context.push(memberPath(member.id)),
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.l),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MemberAvatar(
                      profileId: member.id,
                      name: member.name,
                      avatar: member.avatar,
                    ),
                    const SizedBox(width: SpacingTokens.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Names never truncate (screens.md F1).
                          Text(member.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: SpacingTokens.xs),
                          Wrap(
                            spacing: SpacingTokens.s,
                            runSpacing: SpacingTokens.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(age, style: theme.textTheme.bodyMedium),
                              if (member.isManager) TextTag(l10n.familyCardYou),
                              if (member.isChild)
                                TextTag(l10n.familyCardChildTag),
                            ],
                          ),
                          const SizedBox(height: SpacingTokens.s),
                          if (line.neutral)
                            NeutralNote(text: line.text)
                          else
                            Text(line.text, style: theme.textTheme.bodyMedium),
                          if (pending) ...[
                            const SizedBox(height: SpacingTokens.xs),
                            _IconLine(
                              icon: Icons.schedule,
                              text: l10n.familyCardRulePending,
                            ),
                          ],
                          if (renewal) ...[
                            const SizedBox(height: SpacingTokens.xs),
                            _IconLine(
                              icon: Icons.info_outlined,
                              text: l10n.familyCardRenewal,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (line.action case final action?)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                SpacingTokens.l,
                0,
                SpacingTokens.l,
                SpacingTokens.m,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  key: Key('family.card.action.${member.id}'),
                  onPressed: () => openRulesPicker(
                    context,
                    profileId: member.id,
                    mode: RulesPickerMode.firstRules,
                  ),
                  child: Text(action),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, size: IconSizeTokens.badgeCompact)),
        const SizedBox(width: SpacingTokens.xs),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
