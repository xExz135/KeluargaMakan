// Cek Aman safety styling (SAF-04, SAF-05, INT-03, safety-badges.md 1.4, 9).
//
// This library is the only place that may use the safety colors. The color
// extension class is private, so no other feature can read it from the theme.
// The SafetyBadge, SafetyPanel and explanation-sheet widgets are added to this
// library (as `part` files) by their own tasks. They take a full
// MemberSafetyResult from the API or the cache, never a bare status, and
// render nothing when there is no result.
//
// No widget in the app shell shows a safety state.

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The safety color extension for [brightness], for ThemeData.extensions.
/// Typed as a plain ThemeExtension so callers cannot read the colors.
ThemeExtension<dynamic> safetyColorsExtension(Brightness brightness) =>
    _SafetyColors.resolve(brightness);

/// Test-only view of the registered safety colors, keyed by token name.
@visibleForTesting
Map<String, Color> debugSafetyColors(ThemeData theme) {
  final c = theme.extension<_SafetyColors>()!;
  return {
    'safeContainer': c.safeContainer,
    'onSafeContainer': c.onSafeContainer,
    'safeIcon': c.safeIcon,
    'safeBorder': c.safeBorder,
    'notSafeContainer': c.notSafeContainer,
    'onNotSafeContainer': c.onNotSafeContainer,
    'notSafeIcon': c.notSafeIcon,
    'notSafeBorder': c.notSafeBorder,
    'notSafeStripe': c.notSafeStripe,
    'checkContainer': c.checkContainer,
    'onCheckContainer': c.onCheckContainer,
    'checkIcon': c.checkIcon,
    'checkBorder': c.checkBorder,
  };
}

/// tokens.json `safetyColors`.
abstract final class _SafetyColorTokens {
  static const safeContainer = TokenColor(Color(0xFFF0FDF4), Color(0xFF052E16));
  static const onSafeContainer = TokenColor(
    Color(0xFF14532D),
    Color(0xFF86EFAC),
  );
  static const safeIcon = TokenColor(Color(0xFF15803D), Color(0xFF4ADE80));
  static const safeBorder = TokenColor(Color(0xFF15803D), Color(0xFF22C55E));
  static const notSafeContainer = TokenColor(
    Color(0xFFFFF1F2),
    Color(0xFF4C0519),
  );
  static const onNotSafeContainer = TokenColor(
    Color(0xFF881337),
    Color(0xFFFECDD3),
  );
  static const notSafeIcon = TokenColor(Color(0xFFBE123C), Color(0xFFFB7185));
  static const notSafeBorder = TokenColor(Color(0xFFBE123C), Color(0xFFFB7185));
  static const notSafeStripe = TokenColor(Color(0xFFBE123C), Color(0xFFFB7185));
  static const checkContainer = TokenColor(
    Color(0xFFFFFBEB),
    Color(0xFF451A03),
  );
  static const onCheckContainer = TokenColor(
    Color(0xFF78350F),
    Color(0xFFFDE68A),
  );
  static const checkIcon = TokenColor(Color(0xFFB45309), Color(0xFFFBBF24));
  static const checkBorder = TokenColor(Color(0xFFB45309), Color(0xFFF59E0B));
}

@immutable
class _SafetyColors extends ThemeExtension<_SafetyColors> {
  const _SafetyColors({
    required this.safeContainer,
    required this.onSafeContainer,
    required this.safeIcon,
    required this.safeBorder,
    required this.notSafeContainer,
    required this.onNotSafeContainer,
    required this.notSafeIcon,
    required this.notSafeBorder,
    required this.notSafeStripe,
    required this.checkContainer,
    required this.onCheckContainer,
    required this.checkIcon,
    required this.checkBorder,
  });

  factory _SafetyColors.resolve(Brightness b) => _SafetyColors(
    safeContainer: _SafetyColorTokens.safeContainer.resolve(b),
    onSafeContainer: _SafetyColorTokens.onSafeContainer.resolve(b),
    safeIcon: _SafetyColorTokens.safeIcon.resolve(b),
    safeBorder: _SafetyColorTokens.safeBorder.resolve(b),
    notSafeContainer: _SafetyColorTokens.notSafeContainer.resolve(b),
    onNotSafeContainer: _SafetyColorTokens.onNotSafeContainer.resolve(b),
    notSafeIcon: _SafetyColorTokens.notSafeIcon.resolve(b),
    notSafeBorder: _SafetyColorTokens.notSafeBorder.resolve(b),
    notSafeStripe: _SafetyColorTokens.notSafeStripe.resolve(b),
    checkContainer: _SafetyColorTokens.checkContainer.resolve(b),
    onCheckContainer: _SafetyColorTokens.onCheckContainer.resolve(b),
    checkIcon: _SafetyColorTokens.checkIcon.resolve(b),
    checkBorder: _SafetyColorTokens.checkBorder.resolve(b),
  );

  final Color safeContainer;
  final Color onSafeContainer;
  final Color safeIcon;
  final Color safeBorder;
  final Color notSafeContainer;
  final Color onNotSafeContainer;
  final Color notSafeIcon;
  final Color notSafeBorder;
  final Color notSafeStripe;
  final Color checkContainer;
  final Color onCheckContainer;
  final Color checkIcon;
  final Color checkBorder;

  @override
  _SafetyColors copyWith() => this;

  /// Safety colors never animate (tokens.md 5), so a theme change snaps.
  @override
  _SafetyColors lerp(_SafetyColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}
