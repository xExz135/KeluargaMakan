// Design tokens for KeluargaMakan (INT-05, NFR-15), v1.0 (T-004).
//
// Transcribed from docs/design/system/tokens.json, the source of truth. When
// the ux-designer changes tokens.json, update this file (the color and type
// blocks are generated mechanically from the JSON) and nothing else:
// app_theme.dart maps these onto Material 3.
//
// Not here on purpose:
// - Safety colors: private to the Cek Aman widgets' library
//   (lib/features/cek_aman/safety_style.dart, safety-badges.md 9).
// - Touch-target sizes and timings: remote config
//   (lib/core/config/config_keys.dart, tokens.md 6).

import 'package:flutter/widgets.dart';

/// One color role with its light and dark value.
final class TokenColor {
  const TokenColor(this.light, this.dark);

  final Color light;
  final Color dark;

  Color resolve(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// A type style in sp (before text scaling). Flutter height = line / size.
final class TokenTypeStyle {
  const TokenTypeStyle(
    this.size,
    this.lineHeight,
    this.weight, {
    this.notSafeWeight,
    this.tabularFigures = false,
  });

  final double size;
  final double lineHeight;
  final FontWeight weight;

  /// Heavier weight for Tidak aman text in badges.
  final FontWeight? notSafeWeight;
  final bool tabularFigures;

  TextStyle toStyle() => TextStyle(
    fontFamily: TypographyTokens.fontFamily,
    fontFamilyFallback: TypographyTokens.fontFamilyFallback,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: 0,
    fontFeatures: tabularFigures ? const [FontFeature.tabularFigures()] : null,
  );
}

/// tokens.json `color`: every Material 3 ColorScheme role.
abstract final class SchemeColorTokens {
  static const primary = TokenColor(Color(0xFF047857), Color(0xFF34D399));
  static const onPrimary = TokenColor(Color(0xFFFFFFFF), Color(0xFF022C22));
  static const primaryContainer = TokenColor(
    Color(0xFFD1FAE5),
    Color(0xFF064E3B),
  );
  static const onPrimaryContainer = TokenColor(
    Color(0xFF064E3B),
    Color(0xFFA7F3D0),
  );
  static const inversePrimary = TokenColor(
    Color(0xFF6EE7B7),
    Color(0xFF065F46),
  );
  static const secondary = TokenColor(Color(0xFF57534E), Color(0xFFD6D3D1));
  static const onSecondary = TokenColor(Color(0xFFFFFFFF), Color(0xFF292524));
  static const secondaryContainer = TokenColor(
    Color(0xFFE7E5E4),
    Color(0xFF44403C),
  );
  static const onSecondaryContainer = TokenColor(
    Color(0xFF1C1917),
    Color(0xFFF5F5F4),
  );
  static const tertiary = TokenColor(Color(0xFF0E7490), Color(0xFF67E8F9));
  static const onTertiary = TokenColor(Color(0xFFFFFFFF), Color(0xFF083344));
  static const tertiaryContainer = TokenColor(
    Color(0xFFCFFAFE),
    Color(0xFF164E63),
  );
  static const onTertiaryContainer = TokenColor(
    Color(0xFF164E63),
    Color(0xFFCFFAFE),
  );
  static const error = TokenColor(Color(0xFFB91C1C), Color(0xFFFCA5A5));
  static const onError = TokenColor(Color(0xFFFFFFFF), Color(0xFF450A0A));
  static const errorContainer = TokenColor(
    Color(0xFFFEE2E2),
    Color(0xFF7F1D1D),
  );
  static const onErrorContainer = TokenColor(
    Color(0xFF7F1D1D),
    Color(0xFFFEE2E2),
  );
  static const surface = TokenColor(Color(0xFFFAFAF9), Color(0xFF0C0A09));
  static const surfaceDim = TokenColor(Color(0xFFE7E5E4), Color(0xFF0C0A09));
  static const surfaceBright = TokenColor(Color(0xFFFFFFFF), Color(0xFF3A3532));
  static const surfaceContainerLowest = TokenColor(
    Color(0xFFFFFFFF),
    Color(0xFF080706),
  );
  static const surfaceContainerLow = TokenColor(
    Color(0xFFF7F6F5),
    Color(0xFF141210),
  );
  static const surfaceContainer = TokenColor(
    Color(0xFFF5F5F4),
    Color(0xFF1C1917),
  );
  static const surfaceContainerHigh = TokenColor(
    Color(0xFFF0EFEE),
    Color(0xFF292524),
  );
  static const surfaceContainerHighest = TokenColor(
    Color(0xFFE7E5E4),
    Color(0xFF3A3532),
  );
  static const onSurface = TokenColor(Color(0xFF1C1917), Color(0xFFF5F5F4));
  static const onSurfaceVariant = TokenColor(
    Color(0xFF57534E),
    Color(0xFFA8A29E),
  );
  static const outline = TokenColor(Color(0xFF78716C), Color(0xFFA8A29E));
  static const outlineVariant = TokenColor(
    Color(0xFFE7E5E4),
    Color(0xFF44403C),
  );
  static const inverseSurface = TokenColor(
    Color(0xFF292524),
    Color(0xFFE7E5E4),
  );
  static const onInverseSurface = TokenColor(
    Color(0xFFF5F5F4),
    Color(0xFF1C1917),
  );
  static const scrim = TokenColor(Color(0xFF000000), Color(0xFF000000));
  static const shadow = TokenColor(Color(0xFF000000), Color(0xFF000000));
}

/// tokens.json `appColors`: roles ColorScheme does not have (AppColors).
abstract final class AppColorTokens {
  static const card = TokenColor(Color(0xFFFFFFFF), Color(0xFF1C1917));
  static const cardBorder = TokenColor(Color(0xFFE7E5E4), Color(0xFF44403C));
  static const focusRing = TokenColor(Color(0xFF1C1917), Color(0xFFF5F5F4));
  static const infoContainer = TokenColor(Color(0xFFEFF6FF), Color(0xFF172554));
  static const onInfoContainer = TokenColor(
    Color(0xFF1E3A8A),
    Color(0xFFBFDBFE),
  );
  static const infoIcon = TokenColor(Color(0xFF1D4ED8), Color(0xFF60A5FA));
  static const neutralContainer = TokenColor(
    Color(0xFFE7E5E4),
    Color(0xFF44403C),
  );
  static const onNeutralContainer = TokenColor(
    Color(0xFF1C1917),
    Color(0xFFF5F5F4),
  );
  static const neutralIcon = TokenColor(Color(0xFF44403C), Color(0xFFD6D3D1));
  static const kitchenAvailableContainer = TokenColor(
    Color(0xFFD1FAE5),
    Color(0xFF064E3B),
  );
  static const onKitchenAvailableContainer = TokenColor(
    Color(0xFF064E3B),
    Color(0xFFA7F3D0),
  );
  static const kitchenAvailableBorder = TokenColor(
    Color(0xFF047857),
    Color(0xFF34D399),
  );
  static const kitchenOutContainer = TokenColor(
    Color(0xFFFAFAF9),
    Color(0xFF1C1917),
  );
  static const onKitchenOutContainer = TokenColor(
    Color(0xFF57534E),
    Color(0xFFA8A29E),
  );
  static const kitchenOutBorder = TokenColor(
    Color(0xFF78716C),
    Color(0xFFA8A29E),
  );
  static const skeleton = TokenColor(Color(0xFFE7E5E4), Color(0xFF3A3532));
  static const photoScrim = TokenColor(Color(0x99000000), Color(0x99000000));
  static const disabledContainer = TokenColor(
    Color(0xFFE7E5E4),
    Color(0xFF292524),
  );
  static const onDisabled = TokenColor(Color(0xFF6B6560), Color(0xFF8F8984));
}

/// tokens.json `avatar`: initials avatars, index = stable hash of profile id mod 8.
abstract final class AvatarColorTokens {
  static const text = TokenColor(Color(0xFF1C1917), Color(0xFFF5F5F4));
  static const backgrounds = [
    TokenColor(Color(0xFFD1FAE5), Color(0xFF064E3B)),
    TokenColor(Color(0xFFCCFBF1), Color(0xFF134E4A)),
    TokenColor(Color(0xFFE0F2FE), Color(0xFF0C4A6E)),
    TokenColor(Color(0xFFE0E7FF), Color(0xFF312E81)),
    TokenColor(Color(0xFFEDE9FE), Color(0xFF4C1D95)),
    TokenColor(Color(0xFFE7E5E4), Color(0xFF44403C)),
    TokenColor(Color(0xFFE2E8F0), Color(0xFF334155)),
    TokenColor(Color(0xFFCFFAFE), Color(0xFF164E63)),
  ];
}

abstract final class TypographyTokens {
  static const fontFamily = 'PlusJakartaSans';
  static const fontFamilyFallback = ['Roboto'];
  static const displayLarge = TokenTypeStyle(48, 56, FontWeight.w800);
  static const displayMedium = TokenTypeStyle(40, 48, FontWeight.w800);
  static const displaySmall = TokenTypeStyle(36, 44, FontWeight.w800);
  static const headlineLarge = TokenTypeStyle(32, 40, FontWeight.w800);
  static const headlineMedium = TokenTypeStyle(28, 36, FontWeight.w800);
  static const headlineSmall = TokenTypeStyle(24, 32, FontWeight.w700);
  static const titleLarge = TokenTypeStyle(20, 28, FontWeight.w700);
  static const titleMedium = TokenTypeStyle(16, 24, FontWeight.w600);
  static const titleSmall = TokenTypeStyle(14, 20, FontWeight.w600);
  static const bodyLarge = TokenTypeStyle(16, 24, FontWeight.w400);
  static const bodyMedium = TokenTypeStyle(14, 20, FontWeight.w400);
  static const bodySmall = TokenTypeStyle(12, 16, FontWeight.w400);
  static const labelLarge = TokenTypeStyle(16, 20, FontWeight.w600);
  static const labelMedium = TokenTypeStyle(14, 20, FontWeight.w600);
  static const labelSmall = TokenTypeStyle(12, 16, FontWeight.w600);
  static const badgeCompact = TokenTypeStyle(
    14,
    20,
    FontWeight.w600,
    notSafeWeight: FontWeight.w700,
  );
  static const badgePanel = TokenTypeStyle(
    16,
    24,
    FontWeight.w600,
    notSafeWeight: FontWeight.w700,
  );
  static const badgeStateWord = TokenTypeStyle(14, 20, FontWeight.w800);
  static const cookStep = TokenTypeStyle(28, 38, FontWeight.w600);
  static const cookStepTablet = TokenTypeStyle(32, 44, FontWeight.w600);
  static const cookIngredient = TokenTypeStyle(20, 28, FontWeight.w500);
  static const cookTimer = TokenTypeStyle(
    40,
    48,
    FontWeight.w800,
    tabularFigures: true,
  );
  static const cookNavLabel = TokenTypeStyle(20, 24, FontWeight.w700);
}

/// tokens.json `spacing` (dp, 4 dp grid).
abstract final class SpacingTokens {
  static const double none = 0;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// tokens.json `gutter` and `breakpoints` (dp).
abstract final class LayoutTokens {
  static const double gutterCompact = 16;
  static const double gutterMedium = 24;
  static const double gutterExpanded = 24;

  /// Widths up to compactMax (599) are compact, up to mediumMax (839) medium.
  static const double compactMax = 599;
  static const double mediumMax = 839;
  static const double maxReadableWidth = 640;
}

/// tokens.json `radius` (dp).
abstract final class RadiusTokens {
  static const double none = 0;
  static const double badge = 8;
  static const double control = 12;
  static const double image = 16;
  static const double card = 24;
  static const double sheet = 24;
  static const double dialog = 28;
  static const double full = 999;
}

/// tokens.json `border` (dp).
abstract final class BorderTokens {
  static const double hairline = 1;
  static const double safe = 1;
  static const double check = 1.5;
  static const double notSafe = 2;
  static const double notSafeStripe = 4;
  static const double focus = 3;
  static const double focusOffset = 2;
  static const List<double> checkDash = [4, 3];
}

/// tokens.json `elevation` (dp, shadow only).
abstract final class ElevationTokens {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
}

/// tokens.json `motion`. Every duration is 0 when animations are disabled.
abstract final class MotionTokens {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const long = Duration(milliseconds: 300);
  static const easing = Cubic(0.2, 0, 0, 1);
}

/// tokens.json `icon` (dp).
abstract final class IconSizeTokens {
  static const double standard = 24;
  static const double badgeCompact = 20;
  static const double badgePanel = 24;
  static const double cook = 32;
}
