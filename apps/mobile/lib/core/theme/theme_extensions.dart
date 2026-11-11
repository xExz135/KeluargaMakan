// Public theme extensions (components.md "Theme wiring"): AppColors, AppText
// and AppSpacing. SafetyColors is not here: it is private to the Cek Aman
// widgets' library (lib/features/cek_aman/safety_style.dart).

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Semantic colors Material 3's ColorScheme does not have (tokens.md 1.3).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.card,
    required this.cardBorder,
    required this.focusRing,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.infoIcon,
    required this.neutralContainer,
    required this.onNeutralContainer,
    required this.neutralIcon,
    required this.kitchenAvailableContainer,
    required this.onKitchenAvailableContainer,
    required this.kitchenAvailableBorder,
    required this.kitchenOutContainer,
    required this.onKitchenOutContainer,
    required this.kitchenOutBorder,
    required this.skeleton,
    required this.photoScrim,
    required this.disabledContainer,
    required this.onDisabled,
    required this.avatarText,
    required this.avatarBackgrounds,
  });

  factory AppColors.resolve(Brightness b) => AppColors(
    card: AppColorTokens.card.resolve(b),
    cardBorder: AppColorTokens.cardBorder.resolve(b),
    focusRing: AppColorTokens.focusRing.resolve(b),
    infoContainer: AppColorTokens.infoContainer.resolve(b),
    onInfoContainer: AppColorTokens.onInfoContainer.resolve(b),
    infoIcon: AppColorTokens.infoIcon.resolve(b),
    neutralContainer: AppColorTokens.neutralContainer.resolve(b),
    onNeutralContainer: AppColorTokens.onNeutralContainer.resolve(b),
    neutralIcon: AppColorTokens.neutralIcon.resolve(b),
    kitchenAvailableContainer: AppColorTokens.kitchenAvailableContainer.resolve(
      b,
    ),
    onKitchenAvailableContainer: AppColorTokens.onKitchenAvailableContainer
        .resolve(b),
    kitchenAvailableBorder: AppColorTokens.kitchenAvailableBorder.resolve(b),
    kitchenOutContainer: AppColorTokens.kitchenOutContainer.resolve(b),
    onKitchenOutContainer: AppColorTokens.onKitchenOutContainer.resolve(b),
    kitchenOutBorder: AppColorTokens.kitchenOutBorder.resolve(b),
    skeleton: AppColorTokens.skeleton.resolve(b),
    photoScrim: AppColorTokens.photoScrim.resolve(b),
    disabledContainer: AppColorTokens.disabledContainer.resolve(b),
    onDisabled: AppColorTokens.onDisabled.resolve(b),
    avatarText: AvatarColorTokens.text.resolve(b),
    avatarBackgrounds: [
      for (final color in AvatarColorTokens.backgrounds) color.resolve(b),
    ],
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  final Color card;
  final Color cardBorder;
  final Color focusRing;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color infoIcon;
  final Color neutralContainer;
  final Color onNeutralContainer;
  final Color neutralIcon;
  final Color kitchenAvailableContainer;
  final Color onKitchenAvailableContainer;
  final Color kitchenAvailableBorder;
  final Color kitchenOutContainer;
  final Color onKitchenOutContainer;
  final Color kitchenOutBorder;
  final Color skeleton;
  final Color photoScrim;
  final Color disabledContainer;
  final Color onDisabled;
  final Color avatarText;

  /// Eight initials-avatar backgrounds; index = stable hash of profile id
  /// mod 8. None is green, rose or amber.
  final List<Color> avatarBackgrounds;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      card: mix(card, other.card),
      cardBorder: mix(cardBorder, other.cardBorder),
      focusRing: mix(focusRing, other.focusRing),
      infoContainer: mix(infoContainer, other.infoContainer),
      onInfoContainer: mix(onInfoContainer, other.onInfoContainer),
      infoIcon: mix(infoIcon, other.infoIcon),
      neutralContainer: mix(neutralContainer, other.neutralContainer),
      onNeutralContainer: mix(onNeutralContainer, other.onNeutralContainer),
      neutralIcon: mix(neutralIcon, other.neutralIcon),
      kitchenAvailableContainer: mix(
        kitchenAvailableContainer,
        other.kitchenAvailableContainer,
      ),
      onKitchenAvailableContainer: mix(
        onKitchenAvailableContainer,
        other.onKitchenAvailableContainer,
      ),
      kitchenAvailableBorder: mix(
        kitchenAvailableBorder,
        other.kitchenAvailableBorder,
      ),
      kitchenOutContainer: mix(kitchenOutContainer, other.kitchenOutContainer),
      onKitchenOutContainer: mix(
        onKitchenOutContainer,
        other.onKitchenOutContainer,
      ),
      kitchenOutBorder: mix(kitchenOutBorder, other.kitchenOutBorder),
      skeleton: mix(skeleton, other.skeleton),
      photoScrim: mix(photoScrim, other.photoScrim),
      disabledContainer: mix(disabledContainer, other.disabledContainer),
      onDisabled: mix(onDisabled, other.onDisabled),
      avatarText: mix(avatarText, other.avatarText),
      avatarBackgrounds: [
        for (var i = 0; i < avatarBackgrounds.length; i++)
          mix(avatarBackgrounds[i], other.avatarBackgrounds[i]),
      ],
    );
  }
}

/// Custom text styles (tokens.md 2, "Custom styles").
@immutable
class AppText extends ThemeExtension<AppText> {
  const AppText({
    required this.badgeStateWord,
    required this.badgeCompact,
    required this.badgePanel,
    required this.cookStep,
    required this.cookStepTablet,
    required this.cookIngredient,
    required this.cookTimer,
    required this.cookNavLabel,
  });

  factory AppText.fromTokens() => AppText(
    badgeStateWord: TypographyTokens.badgeStateWord.toStyle(),
    badgeCompact: TypographyTokens.badgeCompact.toStyle(),
    badgePanel: TypographyTokens.badgePanel.toStyle(),
    cookStep: TypographyTokens.cookStep.toStyle(),
    cookStepTablet: TypographyTokens.cookStepTablet.toStyle(),
    cookIngredient: TypographyTokens.cookIngredient.toStyle(),
    cookTimer: TypographyTokens.cookTimer.toStyle(),
    cookNavLabel: TypographyTokens.cookNavLabel.toStyle(),
  );

  static AppText of(BuildContext context) =>
      Theme.of(context).extension<AppText>()!;

  final TextStyle badgeStateWord;

  /// Tidak aman uses [TypographyTokens.badgeCompact]'s notSafeWeight.
  final TextStyle badgeCompact;
  final TextStyle badgePanel;
  final TextStyle cookStep;
  final TextStyle cookStepTablet;
  final TextStyle cookIngredient;

  /// Tabular figures.
  final TextStyle cookTimer;
  final TextStyle cookNavLabel;

  @override
  AppText copyWith() => this;

  @override
  AppText lerp(AppText? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Spacing, radius and layout values through the theme (tokens.md 3, 4, 7).
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing();

  static AppSpacing of(BuildContext context) =>
      Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

  double get xs => SpacingTokens.xs;
  double get s => SpacingTokens.s;
  double get m => SpacingTokens.m;
  double get l => SpacingTokens.l;
  double get xl => SpacingTokens.xl;
  double get xxl => SpacingTokens.xxl;
  double get xxxl => SpacingTokens.xxxl;

  /// Minimum gap between two tappable targets.
  double get minTargetGap => SpacingTokens.s;

  double get cardPadding => SpacingTokens.l;
  double get cardGap => SpacingTokens.m;
  double get maxReadableWidth => LayoutTokens.maxReadableWidth;

  /// Screen side gutter for a window [width].
  double gutterFor(double width) => width <= LayoutTokens.compactMax
      ? LayoutTokens.gutterCompact
      : (width <= LayoutTokens.mediumMax
            ? LayoutTokens.gutterMedium
            : LayoutTokens.gutterExpanded);

  @override
  AppSpacing copyWith() => this;

  @override
  AppSpacing lerp(AppSpacing? other, double t) => this;
}
