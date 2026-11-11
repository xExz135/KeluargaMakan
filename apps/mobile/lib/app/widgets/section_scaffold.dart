// Scaffold for tab roots and full-screen pages: a plain left-aligned top app
// bar (navigation.md 2) whose title follows system text scaling up to 200%
// (accessibility.md 3). Material's AppBar clamps titles to 1.34x and has a
// fixed toolbar height; this opts out of the clamp and sizes the toolbar to
// the lines the title really needs, so a long title wraps instead of being
// cut off.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../router.dart';
import '../shell/app_shell.dart';

class SectionScaffold extends StatelessWidget {
  const SectionScaffold({
    super.key,
    required this.title,
    required this.body,
    this.isTabRoot = true,
    this.titleStyle,
  });

  final String title;
  final Widget body;

  /// Tab roots show the Settings button on compact windows. On wider windows
  /// it sits at the bottom of the navigation rail instead.
  final bool isTabRoot;

  /// Defaults to the app bar theme (headlineSmall, "screen titles").
  final TextStyle? titleStyle;

  // AppBar layout constants: leading slot and icon button widths, and the
  // NavigationToolbar title spacing on each side.
  static const double _leadingWidth = kToolbarHeight;
  static const double _actionWidth = 48;
  static const double _titleSpacing = NavigationToolbar.kMiddleSpacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final style =
        titleStyle ??
        theme.appBarTheme.titleTextStyle ??
        theme.textTheme.headlineSmall!;
    final showSettings = isTabRoot && isCompactWindow(context);
    final hasLeading = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(
          0.0,
          constraints.maxWidth -
              2 * _titleSpacing -
              (hasLeading ? _leadingWidth : 0) -
              (showSettings ? _actionWidth + SpacingTokens.s : 0),
        );
        final painter = TextPainter(
          text: TextSpan(text: title, style: style),
          textDirection: Directionality.of(context),
          textScaler: mediaQuery.textScaler,
        )..layout(maxWidth: available);
        final toolbarHeight = math.max(
          kToolbarHeight,
          painter.height + 2 * SpacingTokens.m,
        );
        painter.dispose();

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: toolbarHeight,
            titleTextStyle: style,
            title: MediaQuery(
              data: mediaQuery,
              child: Semantics(header: true, child: Text(title)),
            ),
            actions: [
              if (showSettings)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: l10n.navSettings,
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              if (showSettings) const SizedBox(width: SpacingTokens.s),
            ],
          ),
          body: SafeArea(top: false, bottom: false, child: body),
        );
      },
    );
  }
}

/// Side gutter and max readable width (tokens.md 3 and 7).
class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: spacing.maxReadableWidth),
        // Fill the available width; Align alone would shrink to the child.
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.gutterFor(MediaQuery.sizeOf(context).width),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
