// Client-side configuration keys (tokens.md 6, tokens.json `config`).
// Defaults and floors come from the design system; values marked
// ConfigStatus.target are SRS (target) figures. Add new client-affecting
// (target) values here, never as constants in feature code.

import 'app_config.dart';

abstract final class ConfigKeys {
  /// Every tappable element app-wide. Android baseline.
  static const minTouchTargetDp = ConfigKey<int>(
    'ui.minTouchTargetDp',
    48,
    requirementIds: ['NFR-15'],
    status: ConfigStatus.decided,
    min: 48,
  );

  /// Minimum for every control in Mode Masak and Taste & Tweak. The SRS
  /// INT-04 (target).
  static const cookMinTouchTargetDp = ConfigKey<int>(
    'cook.minTouchTargetDp',
    48,
    requirementIds: ['INT-04'],
    min: 48,
  );

  /// Design size of Mode Masak controls (timer, voice, fixes, close).
  static const cookControlSizeDp = ConfigKey<int>(
    'cook.controlSizeDp',
    72,
    requirementIds: ['INT-04', 'CKM-02'],
    status: ConfigStatus.decided,
    min: 48,
  );

  /// Height of "Berikutnya" and "Sebelumnya" in Mode Masak.
  static const cookNavButtonHeightDp = ConfigKey<int>(
    'cook.navButtonHeightDp',
    88,
    requirementIds: ['INT-04', 'CKM-02'],
    status: ConfigStatus.decided,
    min: 48,
  );

  /// Dapur Saya item toggles.
  static const kitchenToggleMinHeightDp = ConfigKey<int>(
    'kitchen.toggleMinHeightDp',
    56,
    requirementIds: ['KIT-02'],
    status: ConfigStatus.decided,
    min: 48,
  );

  /// Timers that can run at once.
  static const maxConcurrentTimers = ConfigKey<int>(
    'cook.maxConcurrentTimers',
    5,
    requirementIds: ['CKM-03'],
    status: ConfigStatus.decided,
    min: 1,
  );

  /// When "Masih memuat…" appears.
  static const slowLoadingMs = ConfigKey<int>(
    'ui.slowLoadingMs',
    5000,
    requirementIds: ['NFR-15'],
    status: ConfigStatus.decided,
    min: 1000,
  );

  /// Minimum on-screen time of a snackbar with Undo.
  static const snackbarActionMs = ConfigKey<int>(
    'ui.snackbarActionMs',
    10000,
    requirementIds: ['NFR-15'],
    status: ConfigStatus.decided,
    min: 10000,
  );

  /// Used when servings cannot be derived from the eaters (flows/08 S1,
  /// stepper 1 to 12).
  static const defaultServings = ConfigKey<int>(
    'settings.defaultServings',
    4,
    requirementIds: ['SET-01'],
    status: ConfigStatus.decided,
    min: 1,
  );

  /// V2 attach point (navigation.md 1). Off in V1: the Plan tab is not shown.
  static const planTabEnabled = ConfigKey<bool>(
    'nav.planTabEnabled',
    false,
    requirementIds: ['INT-02'],
    status: ConfigStatus.decided,
  );

  static const List<ConfigKey<Object>> all = [
    minTouchTargetDp,
    cookMinTouchTargetDp,
    cookControlSizeDp,
    cookNavButtonHeightDp,
    kitchenToggleMinHeightDp,
    maxConcurrentTimers,
    slowLoadingMs,
    snackbarActionMs,
    defaultServings,
    planTabEnabled,
  ];
}

/// Effective touch-target sizes (tokens.md 6, "Effective size rules").
extension TouchTargets on AppConfig {
  /// Mode Masak control size: max(cook.controlSizeDp, cook.minTouchTargetDp),
  /// so raising the INT-04 target raises every cooking control.
  double get cookControlSize => _max(
    get(ConfigKeys.cookControlSizeDp),
    get(ConfigKeys.cookMinTouchTargetDp),
  );

  /// Mode Masak prev and next height:
  /// max(cook.navButtonHeightDp, cook.minTouchTargetDp).
  double get cookNavButtonHeight => _max(
    get(ConfigKeys.cookNavButtonHeightDp),
    get(ConfigKeys.cookMinTouchTargetDp),
  );

  double get minTouchTarget => get(ConfigKeys.minTouchTargetDp).toDouble();

  static double _max(int a, int b) => (a > b ? a : b).toDouble();
}
