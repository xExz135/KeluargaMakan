// Language selection (NFR-16, ACC-09).
//
// Bahasa Indonesia is the default for every device language except English
// (design-system.md 10). A choice made in Settings is kept on the device and
// overrides the device language.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';

abstract final class AppLocales {
  static const indonesian = Locale('id');
  static const english = Locale('en');

  /// Bahasa Indonesia first.
  static const supported = [indonesian, english];

  /// Picks the app language from the device's preferred languages.
  static Locale resolve(List<Locale>? deviceLocales) {
    final primary = (deviceLocales == null || deviceLocales.isEmpty)
        ? null
        : deviceLocales.first;
    return primary?.languageCode == english.languageCode ? english : indonesian;
  }

  static Locale? fromCode(String? code) => switch (code) {
    'id' => indonesian,
    'en' => english,
    _ => null,
  };
}

/// The user's chosen language, or null to follow the device.
final class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => AppLocales.fromCode(
    ref.read(keyValueStoreProvider).getString(PreferenceKeys.locale),
  );

  Future<void> select(Locale locale) async {
    final chosen = AppLocales.fromCode(locale.languageCode);
    if (chosen == null) return;
    state = chosen;
    await ref
        .read(keyValueStoreProvider)
        .setString(PreferenceKeys.locale, chosen.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
