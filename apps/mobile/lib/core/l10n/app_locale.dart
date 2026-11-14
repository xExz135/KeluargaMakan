// Language selection (NFR-16, ACC-09).
//
// Owner decision (DECISIONS 2026-11-11, QUESTIONS #57), which overrides the
// ACC-09 "device language" default: the app always starts in Bahasa
// Indonesia, on every new install and every new phone sign-in. It switches
// to English only when the user picks English in onboarding (O1) or
// Settings, and that choice is kept on this phone. Neither the phone's
// system language nor `Household.language` overrides it.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../storage/key_value_store.dart';

abstract final class AppLocales {
  static const indonesian = Locale('id');
  static const english = Locale('en');

  /// Bahasa Indonesia first.
  static const supported = [indonesian, english];

  /// The language before the user has chosen one: always Bahasa Indonesia,
  /// whatever the device language (QUESTIONS #57).
  static const fallback = indonesian;

  static Locale? fromCode(String? code) => switch (code) {
    'id' => indonesian,
    'en' => english,
    _ => null,
  };

  /// The contract `Language` for [locale] (code messages, household).
  static api.Language toApi(Locale locale) =>
      locale.languageCode == english.languageCode
      ? api.Language.en
      : api.Language.id;
}

/// The app language: the user's choice on this phone, else Bahasa Indonesia.
final class LocaleController extends Notifier<Locale> {
  @override
  Locale build() =>
      AppLocales.fromCode(
        ref.read(keyValueStoreProvider).getString(PreferenceKeys.locale),
      ) ??
      AppLocales.fallback;

  Future<void> select(Locale locale) async {
    final chosen = AppLocales.fromCode(locale.languageCode);
    if (chosen == null) return;
    state = chosen;
    await ref
        .read(keyValueStoreProvider)
        .setString(PreferenceKeys.locale, chosen.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
