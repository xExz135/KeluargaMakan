// O1 Welcome and language (ACC-09, screens.md O1).
//
// The language starts as Bahasa Indonesia, whatever the device language
// (DECISIONS 2026-11-11, QUESTIONS #57). Changing it switches all text at
// once and is kept on this phone; Settings can change it later.
//
// Not built: the kitchen illustration (no approved asset yet) and the
// pre-emptive no-internet banner (the app has no connectivity check; a
// missing connection is reported when the code is requested).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_routes.dart';
import 'widgets/onboarding_scaffold.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OnboardingScaffold(
      title: l10n.onboardingWelcomeTitle,
      bottom: [
        OnboardingButton(
          key: const Key('welcome.start'),
          label: l10n.onboardingWelcomeStart,
          onPressed: () => context.go(AuthRoutes.signIn),
        ),
        OnboardingButton(
          key: const Key('welcome.haveAccount'),
          kind: OnboardingButtonKind.text,
          label: l10n.onboardingWelcomeHaveAccount,
          onPressed: () => context.go(AuthRoutes.signIn),
        ),
      ],
      children: [
        Text(l10n.onboardingWelcomeBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: SpacingTokens.xl),
        const LanguageChoice(),
      ],
    );
  }
}

/// The O1 language control: a segmented button, or radio rows at large text
/// where two segments would not fit side by side.
class LanguageChoice extends ConsumerWidget {
  const LanguageChoice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = ref.watch(localeControllerProvider);
    final options = {
      AppLocales.indonesian: l10n.settingsLanguageId,
      AppLocales.english: l10n.settingsLanguageEn,
    };
    void select(Locale locale) =>
        ref.read(localeControllerProvider.notifier).select(locale);

    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final Widget control = large
        ? RadioGroup<Locale>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) select(value);
            },
            child: Column(
              children: [
                for (final entry in options.entries)
                  RadioListTile<Locale>(
                    key: Key('language.${entry.key.languageCode}'),
                    contentPadding: EdgeInsets.zero,
                    value: entry.key,
                    title: Text(entry.value),
                  ),
              ],
            ),
          )
        : SizedBox(
            width: double.infinity,
            child: SegmentedButton<Locale>(
              showSelectedIcon: true,
              segments: [
                for (final entry in options.entries)
                  ButtonSegment<Locale>(
                    value: entry.key,
                    label: Text(
                      entry.value,
                      key: Key('language.${entry.key.languageCode}'),
                    ),
                  ),
              ],
              selected: {current},
              onSelectionChanged: (selection) => select(selection.first),
            ),
          );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingWelcomeLanguage,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: SpacingTokens.s),
          control,
        ],
      ),
    );
  }
}
