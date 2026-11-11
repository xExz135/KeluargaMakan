import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_locale.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';

class KeluargaMakanApp extends ConsumerWidget {
  const KeluargaMakanApp({super.key});

  static final _light = AppTheme.light();
  static final _dark = AppTheme.dark();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      onGenerateTitle: (context) => AppLocalizations.of(context).commonAppName,
      debugShowCheckedModeBanner: false,
      theme: _light,
      darkTheme: _dark,
      themeMode: ref.watch(themeModeControllerProvider),
      // Null follows the device language (ACC-09).
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocales.supported,
      localeListResolutionCallback: (deviceLocales, _) =>
          AppLocales.resolve(deviceLocales),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // System text scaling is used as is, up to 200% and beyond (INT-05,
      // NFR-15). Do not add a builder that clamps MediaQuery.textScaler.
    );
  }
}
