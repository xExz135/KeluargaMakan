import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/app/app.dart';
import 'package:keluargamakan/app/shell/bottom_navigation.dart';
import 'package:keluargamakan/core/config/app_config.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';

/// Window sizes used across tests (design-system.md 6).
abstract final class TestWindows {
  /// Small phone, compact.
  static const phone = Size(360, 640);

  /// Tablet landscape, expanded.
  static const tablet = Size(1280, 800);
}

bool _fontsLoaded = false;

/// Loads the bundled Plus Jakarta Sans so text measures like on a device
/// (the test font draws every glyph as a full square).
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final loader = FontLoader('PlusJakartaSans');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
  }
  await loader.load();
  _fontsLoaded = true;
}

/// Pumps the whole app with a simulated device.
Future<InMemoryKeyValueStore> pumpApp(
  WidgetTester tester, {
  Locale deviceLocale = const Locale('id', 'ID'),
  double textScale = 1.0,
  Size size = TestWindows.phone,
  Brightness platformBrightness = Brightness.light,
  Map<String, Object?> config = const {},
  InMemoryKeyValueStore? store,
  double devicePixelRatio = 1.0,
}) async {
  final dispatcher = tester.platformDispatcher;
  dispatcher.localesTestValue = [deviceLocale];
  dispatcher.localeTestValue = deviceLocale;
  dispatcher.textScaleFactorTestValue = textScale;
  dispatcher.platformBrightnessTestValue = platformBrightness;
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = size * devicePixelRatio;
  addTearDown(dispatcher.clearAllTestValues);
  addTearDown(tester.view.reset);

  final usedStore = store ?? InMemoryKeyValueStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(usedStore),
        appConfigProvider.overrideWithValue(
          AppConfig([
            MapConfigSource(config),
            const LocalDefaultsConfigSource(),
          ]),
        ),
      ],
      child: const KeluargaMakanApp(),
    ),
  );
  await tester.pumpAndSettle();
  return usedStore;
}

/// Taps the navigation destination with [label] (bottom bar or rail).
Future<void> tapNav(WidgetTester tester, String label) async {
  final inBar = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is AppBottomNavigation || w is NavigationRail,
    ),
    matching: find.text(label),
  );
  await tester.tap(inBar);
  await tester.pumpAndSettle();
}
