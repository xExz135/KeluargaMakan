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

  /// Dapur Saya: how many of a category's most used items come before the
  /// "Lainnya" divider (screens.md K1, KIT-06).
  static const kitchenFrequentCount = ConfigKey<int>(
    'kitchen.frequentCount',
    6,
    requirementIds: ['KIT-06'],
    status: ConfigStatus.decided,
    min: 1,
  );

  /// Dapur Saya search: pause in typing before the search is sent (K2).
  static const kitchenSearchDebounceMs = ConfigKey<int>(
    'kitchen.searchDebounceMs',
    300,
    requirementIds: ['KIT-04'],
    status: ConfigStatus.decided,
    min: 0,
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

  /// How long an API request may wait for an answer before it counts as a
  /// network failure.
  static const apiRequestTimeoutMs = ConfigKey<int>(
    'api.requestTimeoutMs',
    20000,
    requirementIds: ['NFR-05'],
    status: ConfigStatus.decided,
    min: 1000,
  );

  /// Shows "Lanjut dengan Google" on the sign-in screen (ACC-02). Off until
  /// Google sign-in exists on the server (T-018) and in the app; while off,
  /// phone and email are the sign-in methods (INT-13).
  static const googleSignInEnabled = ConfigKey<bool>(
    'auth.googleSignInEnabled',
    false,
    requirementIds: ['ACC-02', 'INT-13'],
    status: ConfigStatus.decided,
  );

  /// Longest wait the sign-in screens accept from a 429 (`Retry-After`).
  /// About a day: the server's daily wrong-code cap (T-017). The SRS has no
  /// figure; treated as a (target) value.
  static const maxRetryWaitSeconds = ConfigKey<int>(
    'auth.maxRetryWaitSeconds',
    86400,
    requirementIds: ['ACC-01'],
    min: 60,
  );

  /// Days until a member's hard rules are deleted after consent is
  /// withdrawn, shown before the manager withdraws (SET-04, 30 days
  /// (target)). The server sets the real date (`deletionDueBy`), which the
  /// app shows once the withdrawal is recorded.
  static const consentWithdrawalDeletionDays = ConfigKey<int>(
    'consent.withdrawalDeletionDays',
    30,
    requirementIds: ['SET-04'],
    min: 1,
  );

  static const List<ConfigKey<Object>> all = [
    minTouchTargetDp,
    cookMinTouchTargetDp,
    cookControlSizeDp,
    cookNavButtonHeightDp,
    kitchenToggleMinHeightDp,
    kitchenFrequentCount,
    kitchenSearchDebounceMs,
    maxConcurrentTimers,
    slowLoadingMs,
    snackbarActionMs,
    defaultServings,
    planTabEnabled,
    apiRequestTimeoutMs,
    googleSignInEnabled,
    maxRetryWaitSeconds,
    consentWithdrawalDeletionDays,
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
