// Beranda root: Masak Apa Hari Ini (INT-01, flows/04 H1).
//
// Shell placeholder: the hero headline only. Who's eating, meal type, the
// "Lihat 3 saran" button and suggestions come with their own tasks. Nothing
// here shows food or a Cek Aman result.

import 'package:flutter/material.dart';

import '../../app/widgets/section_scaffold.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = AppSpacing.of(context);
    return SectionScaffold(
      // flows/04 H1: the app bar shows the app name in titleMedium; the hero
      // carries the headline.
      title: l10n.commonAppName,
      titleStyle: theme.textTheme.titleMedium,
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: spacing.l),
        children: [
          ContentFrame(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(RadiusTokens.card),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.xl),
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.homeHeroTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
