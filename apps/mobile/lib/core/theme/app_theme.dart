// Material 3 light and dark themes from the v1.0 tokens (INT-05, NFR-15),
// wired as in docs/design/system/components.md "Theme wiring".
//
// The ColorScheme is built with its constructor from tokens.json: no
// fromSeed, no dynamic color (Material You), surfaceTint transparent, so brand
// and safety colors look the same on every phone (tokens.md 1.2).

import 'package:flutter/material.dart';

import '../cek_aman/safety_style.dart';
import 'theme_extensions.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme colorScheme(Brightness b) {
    Color r(TokenColor token) => token.resolve(b);
    return ColorScheme(
      brightness: b,
      primary: r(SchemeColorTokens.primary),
      onPrimary: r(SchemeColorTokens.onPrimary),
      primaryContainer: r(SchemeColorTokens.primaryContainer),
      onPrimaryContainer: r(SchemeColorTokens.onPrimaryContainer),
      inversePrimary: r(SchemeColorTokens.inversePrimary),
      secondary: r(SchemeColorTokens.secondary),
      onSecondary: r(SchemeColorTokens.onSecondary),
      secondaryContainer: r(SchemeColorTokens.secondaryContainer),
      onSecondaryContainer: r(SchemeColorTokens.onSecondaryContainer),
      tertiary: r(SchemeColorTokens.tertiary),
      onTertiary: r(SchemeColorTokens.onTertiary),
      tertiaryContainer: r(SchemeColorTokens.tertiaryContainer),
      onTertiaryContainer: r(SchemeColorTokens.onTertiaryContainer),
      error: r(SchemeColorTokens.error),
      onError: r(SchemeColorTokens.onError),
      errorContainer: r(SchemeColorTokens.errorContainer),
      onErrorContainer: r(SchemeColorTokens.onErrorContainer),
      surface: r(SchemeColorTokens.surface),
      surfaceDim: r(SchemeColorTokens.surfaceDim),
      surfaceBright: r(SchemeColorTokens.surfaceBright),
      surfaceContainerLowest: r(SchemeColorTokens.surfaceContainerLowest),
      surfaceContainerLow: r(SchemeColorTokens.surfaceContainerLow),
      surfaceContainer: r(SchemeColorTokens.surfaceContainer),
      surfaceContainerHigh: r(SchemeColorTokens.surfaceContainerHigh),
      surfaceContainerHighest: r(SchemeColorTokens.surfaceContainerHighest),
      onSurface: r(SchemeColorTokens.onSurface),
      onSurfaceVariant: r(SchemeColorTokens.onSurfaceVariant),
      outline: r(SchemeColorTokens.outline),
      outlineVariant: r(SchemeColorTokens.outlineVariant),
      inverseSurface: r(SchemeColorTokens.inverseSurface),
      onInverseSurface: r(SchemeColorTokens.onInverseSurface),
      scrim: r(SchemeColorTokens.scrim),
      shadow: r(SchemeColorTokens.shadow),
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _build(Brightness b) {
    final scheme = colorScheme(b);
    final app = AppColors.resolve(b);
    final text = _textTheme(scheme);
    const stadium = StadiumBorder();
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: SpacingTokens.xl,
      vertical: SpacingTokens.m,
    );
    const buttonMinSize = Size(64, 48);
    final selectedNavLabel = text.labelSmall!.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w700,
    );
    final navLabel = text.labelSmall!.copyWith(color: scheme.onSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      textTheme: text,
      fontFamily: TypographyTokens.fontFamily,
      fontFamilyFallback: TypographyTokens.fontFamilyFallback,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      disabledColor: app.onDisabled,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      extensions: [
        app,
        safetyColorsExtension(b),
        AppText.fromTokens(),
        const AppSpacing(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: ElevationTokens.level0,
        scrolledUnderElevation: ElevationTokens.level0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: app.card,
        surfaceTintColor: Colors.transparent,
        elevation: ElevationTokens.level0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.card),
          side: BorderSide(color: app.cardBorder, width: BorderTokens.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: stadium,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          textStyle: text.labelLarge,
          disabledBackgroundColor: app.disabledContainer,
          disabledForegroundColor: app.onDisabled,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: stadium,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          textStyle: text.labelLarge,
          disabledForegroundColor: app.onDisabled,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: stadium,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          textStyle: text.labelLarge,
          disabledForegroundColor: app.onDisabled,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(disabledForegroundColor: app.onDisabled),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.control),
        ),
        labelStyle: text.labelMedium,
        showCheckmark: true,
        side: BorderSide(color: scheme.outline, width: BorderTokens.hairline),
        disabledColor: app.disabledContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: _inputBorder(scheme.outline, BorderTokens.hairline),
        enabledBorder: _inputBorder(scheme.outline, BorderTokens.hairline),
        focusedBorder: _inputBorder(scheme.primary, 2),
        errorBorder: _inputBorder(scheme.error, 2),
        focusedErrorBorder: _inputBorder(scheme.error, 2),
        disabledBorder: _inputBorder(app.onDisabled, BorderTokens.hairline),
      ),
      // The compact shell draws its own bar (AppBottomNavigation) because
      // Material's NavigationBar clamps labels at 1.3x and has a fixed
      // height; these values are kept for any NavigationBar used later.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: ElevationTokens.level2,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? selectedNavLabel
              : navLabel,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        elevation: ElevationTokens.level0,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: selectedNavLabel,
        unselectedLabelTextStyle: navLabel,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        elevation: ElevationTokens.level1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: ElevationTokens.level3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.dialog),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: BorderTokens.hairline,
        space: BorderTokens.hairline,
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? app.onDisabled
              : (states.contains(WidgetState.selected)
                    ? scheme.primary
                    : scheme.onSurfaceVariant),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.control),
        borderSide: BorderSide(color: color, width: width),
      );

  /// All 15 Material 3 roles from tokens.md 2, letter spacing 0.
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle s(TokenTypeStyle token) =>
        token.toStyle().copyWith(color: scheme.onSurface);
    return TextTheme(
      displayLarge: s(TypographyTokens.displayLarge),
      displayMedium: s(TypographyTokens.displayMedium),
      displaySmall: s(TypographyTokens.displaySmall),
      headlineLarge: s(TypographyTokens.headlineLarge),
      headlineMedium: s(TypographyTokens.headlineMedium),
      headlineSmall: s(TypographyTokens.headlineSmall),
      titleLarge: s(TypographyTokens.titleLarge),
      titleMedium: s(TypographyTokens.titleMedium),
      titleSmall: s(TypographyTokens.titleSmall),
      bodyLarge: s(TypographyTokens.bodyLarge),
      bodyMedium: s(TypographyTokens.bodyMedium),
      bodySmall: s(TypographyTokens.bodySmall),
      labelLarge: s(TypographyTokens.labelLarge),
      labelMedium: s(TypographyTokens.labelMedium),
      labelSmall: s(TypographyTokens.labelSmall),
    );
  }
}
