// Layout shared by the onboarding screens (screens.md, "All screens"):
// single column with 16dp gutters on phones, content centered and at most
// 560dp wide on wider windows, the screen title as the first heading, and the
// primary buttons pinned at the bottom (above the keyboard when it is open).
// At 200% text the content scrolls and the bottom buttons stay pinned.

import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/tokens.dart';

/// screens.md: "Medium and expanded: content centered, max 560 dp wide".
const double onboardingMaxWidth = 560;

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.children,
    this.bottom = const [],
    this.progress,
  });

  final String title;
  final List<Widget> children;

  /// Pinned buttons, top to bottom. Each fills the width.
  final List<Widget> bottom;

  /// The thin bar from O3 on (flow.md 3), 0 to 1. No step text.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return Scaffold(
      appBar: canPop ? AppBar(leading: const BackButton()) : null,
      body: SafeArea(
        top: !canPop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (progress != null)
              ExcludeSemantics(child: LinearProgressIndicator(value: progress)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xl),
                child: OnboardingFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.l),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
            if (bottom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  top: SpacingTokens.s,
                  bottom: SpacingTokens.l,
                ),
                child: OnboardingFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, button) in bottom.indexed) ...[
                        if (i > 0) const SizedBox(height: SpacingTokens.s),
                        button,
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gutters and the 560dp column.
class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: onboardingMaxWidth),
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

/// A full-width button of at least 56dp (screen-level CTA, components.md
/// 8.6) that shows a spinner and "Memuat…" while [loadingLabel] is set.
class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = OnboardingButtonKind.filled,
    this.loadingLabel,
    this.icon,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final OnboardingButtonKind kind;

  /// When not null, the button is busy: disabled, spinner plus this text.
  final String? loadingLabel;
  final IconData? icon;
  final FocusNode? focusNode;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final busy = loadingLabel != null;
    final Widget child = busy
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: SpacingTokens.s),
              Flexible(child: Text(loadingLabel!, textAlign: TextAlign.center)),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: SpacingTokens.s),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    final pressed = busy ? null : onPressed;
    const minimum = Size(double.infinity, height);
    return switch (kind) {
      OnboardingButtonKind.filled => FilledButton(
        style: FilledButton.styleFrom(minimumSize: minimum),
        focusNode: focusNode,
        onPressed: pressed,
        child: child,
      ),
      OnboardingButtonKind.outlined => OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: minimum),
        focusNode: focusNode,
        onPressed: pressed,
        child: child,
      ),
      OnboardingButtonKind.text => TextButton(
        style: TextButton.styleFrom(minimumSize: minimum),
        focusNode: focusNode,
        onPressed: pressed,
        child: child,
      ),
    };
  }
}

enum OnboardingButtonKind { filled, outlined, text }

/// Inline message: info (blue container) or error (error container), with
/// an icon so the meaning is not carried by color alone. Read out by
/// TalkBack when it appears.
class InlineMessage extends StatelessWidget {
  const InlineMessage({
    super.key,
    required this.text,
    this.title,
    this.kind = InlineMessageKind.error,
  });

  final String? title;
  final String text;
  final InlineMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = AppColors.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground, iconColor, icon) = switch (kind) {
      InlineMessageKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
      InlineMessageKind.info => (
        app.infoContainer,
        app.onInfoContainer,
        app.infoIcon,
        Icons.info_outline,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(RadiusTokens.control),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: SpacingTokens.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                    Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum InlineMessageKind { error, info }
