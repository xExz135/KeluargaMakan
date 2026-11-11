import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/core/config/app_config.dart';
import 'package:keluargamakan/core/config/config_keys.dart';

void main() {
  group('SRS 1.3 (target) values are configuration', () {
    test('INT-04 local defaults match tokens.md 6', () {
      const config = AppConfig();
      expect(config.get(ConfigKeys.minTouchTargetDp), 48);
      expect(config.get(ConfigKeys.cookMinTouchTargetDp), 48);
      expect(config.get(ConfigKeys.cookControlSizeDp), 72);
      expect(config.get(ConfigKeys.cookNavButtonHeightDp), 88);
      expect(config.get(ConfigKeys.kitchenToggleMinHeightDp), 56);
      expect(config.get(ConfigKeys.maxConcurrentTimers), 5);
      expect(config.get(ConfigKeys.slowLoadingMs), 5000);
      expect(config.get(ConfigKeys.snackbarActionMs), 10000);
      expect(config.get(ConfigKeys.defaultServings), 4);
      expect(config.get(ConfigKeys.planTabEnabled), isFalse);
    });

    test('INT-04 the Mode Masak 48dp touch target is a (target) config '
        'value', () {
      expect(ConfigKeys.cookMinTouchTargetDp.name, 'cook.minTouchTargetDp');
      expect(ConfigKeys.cookMinTouchTargetDp.status, ConfigStatus.target);
      expect(
        ConfigKeys.cookMinTouchTargetDp.requirementIds,
        contains('INT-04'),
      );
    });

    test('INT-04 key names follow the T-004 renames', () {
      expect(ConfigKeys.all.map((k) => k.name), [
        'ui.minTouchTargetDp',
        'cook.minTouchTargetDp',
        'cook.controlSizeDp',
        'cook.navButtonHeightDp',
        'kitchen.toggleMinHeightDp',
        'cook.maxConcurrentTimers',
        'ui.slowLoadingMs',
        'ui.snackbarActionMs',
        'settings.defaultServings',
        'nav.planTabEnabled',
      ]);
    });

    test('INT-04 a source value overrides the default without a code '
        'change', () {
      const config = AppConfig([
        MapConfigSource({
          'cook.controlSizeDp': 80,
          'settings.defaultServings': '6',
          'nav.planTabEnabled': 'true',
          'ui.slowLoadingMs': 3000.0,
        }),
        LocalDefaultsConfigSource(),
      ]);
      expect(config.get(ConfigKeys.cookControlSizeDp), 80);
      expect(config.get(ConfigKeys.defaultServings), 6);
      expect(config.get(ConfigKeys.planTabEnabled), isTrue);
      expect(config.get(ConfigKeys.slowLoadingMs), 3000);
    });

    test('INT-04 values below their floor use the floor', () {
      const config = AppConfig([
        MapConfigSource({
          'ui.minTouchTargetDp': 30,
          'cook.minTouchTargetDp': 40,
          'cook.controlSizeDp': 20,
          'ui.snackbarActionMs': 4000,
          'cook.maxConcurrentTimers': 0,
        }),
      ]);
      expect(config.get(ConfigKeys.minTouchTargetDp), 48);
      expect(config.get(ConfigKeys.cookMinTouchTargetDp), 48);
      expect(config.get(ConfigKeys.cookControlSizeDp), 48);
      expect(config.get(ConfigKeys.snackbarActionMs), 10000);
      expect(config.get(ConfigKeys.maxConcurrentTimers), 1);
    });

    test('INT-04 missing or unreadable values use the default', () {
      const config = AppConfig([
        MapConfigSource({
          'cook.controlSizeDp': 'big',
          'cook.maxConcurrentTimers': 2.5,
          'nav.planTabEnabled': 1,
        }),
      ]);
      expect(config.get(ConfigKeys.cookControlSizeDp), 72);
      expect(config.get(ConfigKeys.maxConcurrentTimers), 5);
      expect(config.get(ConfigKeys.planTabEnabled), isFalse);
      expect(config.get(ConfigKeys.cookNavButtonHeightDp), 88);
    });

    test('INT-04 Mode Masak sizes never drop below the INT-04 target', () {
      const defaults = AppConfig();
      expect(defaults.cookControlSize, 72);
      expect(defaults.cookNavButtonHeight, 88);

      // Raising the target raises every cooking control.
      const raised = AppConfig([
        MapConfigSource({'cook.minTouchTargetDp': 96}),
      ]);
      expect(raised.cookControlSize, 96);
      expect(raised.cookNavButtonHeight, 96);

      // Lowering the design size cannot go below the target.
      const lowered = AppConfig([
        MapConfigSource({
          'cook.minTouchTargetDp': 60,
          'cook.controlSizeDp': 50,
          'cook.navButtonHeightDp': 50,
        }),
      ]);
      expect(lowered.cookControlSize, 60);
      expect(lowered.cookNavButtonHeight, 60);
    });

    test('SRS 1.3 the first source with a valid value wins', () {
      const config = AppConfig([
        MapConfigSource({'cook.controlSizeDp': 96}),
        MapConfigSource({'cook.controlSizeDp': 80}),
      ]);
      expect(config.get(ConfigKeys.cookControlSizeDp), 96);
    });

    test('SRS 1.3 every key is unique, traced and its default is valid', () {
      final names = ConfigKeys.all.map((k) => k.name).toList();
      expect(names.toSet(), hasLength(names.length));
      for (final key in ConfigKeys.all) {
        expect(key.requirementIds, isNotEmpty, reason: key.name);
        expect(
          key.coerce(key.defaultValue),
          key.defaultValue,
          reason: key.name,
        );
      }
    });
  });
}
