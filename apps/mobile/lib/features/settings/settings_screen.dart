// S1 Pengaturan (flows/08 section 2). The Umum group's Bahasa (ACC-09,
// NFR-16) and Tema (INT-05) rows, and the Akun group's "Masuk sebagai" and
// "Keluar" (ACC-13). The other groups come with their own tasks.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/widgets/section_scaffold.dart';
import '../../core/api/api_client.dart' show currentAccountIdProvider;
import '../../core/l10n/app_locale.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../core/theme/tokens.dart';
import '../../data/local_cache.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/app_entry.dart';
import 'signed_in_account.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;

  /// ACC-13: confirm, then sign out on this phone. The household stays in
  /// the account; the router moves to O1 once the session has ended.
  /// Kitchen changes not sent yet are deleted with the phone's data, and
  /// the dialog says how many (security review T-034 L7; whether to offer
  /// sending first is QUESTIONS #75).
  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final account = ref.read(currentAccountIdProvider);
    final unsent = account == null
        ? 0
        : await ref.read(localCacheProvider).outboxCount(account);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.settingsSignOutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsSignOutBody),
            if (unsent > 0) ...[
              const SizedBox(height: SpacingTokens.m),
              Text(
                l10n.settingsSignOutPendingKitchen(unsent),
                key: const Key('settings.signOut.pendingKitchen'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('settings.signOut.cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('settings.signOut.confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsSignOutConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _signingOut = true);
    await ref.read(appEntryProvider.notifier).signOut();
    if (mounted) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);
    final themeMode = ref.watch(themeModeControllerProvider);
    final account = ref.watch(signedInAccountProvider).value;

    return SectionScaffold(
      title: l10n.settingsTitle,
      isTabRoot: false,
      body: ListView(
        children: [
          _GroupHeader(l10n.settingsGroupGeneral),
          ListTile(
            key: const Key('settings.language'),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_languageName(l10n, currentLocale)),
            onTap: () => _chooseLanguage(context, ref, currentLocale),
          ),
          ListTile(
            key: const Key('settings.theme'),
            title: Text(l10n.settingsTheme),
            subtitle: Text(_themeName(l10n, themeMode)),
            onTap: () => _chooseTheme(context, ref, themeMode),
          ),
          _GroupHeader(l10n.settingsGroupAccount),
          if (account != null)
            ListTile(
              key: const Key('settings.signedInAs'),
              title: Text(l10n.settingsSignedInAs(account)),
            ),
          ListTile(
            key: const Key('settings.signOut'),
            leading: const Icon(Icons.logout),
            title: Text(l10n.settingsSignOut),
            trailing: _signingOut
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            enabled: !_signingOut,
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  static String _languageName(AppLocalizations l10n, Locale locale) =>
      locale.languageCode == AppLocales.english.languageCode
      ? l10n.settingsLanguageEn
      : l10n.settingsLanguageId;

  static String _themeName(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.settingsThemeSystem,
        ThemeMode.light => l10n.settingsThemeLight,
        ThemeMode.dark => l10n.settingsThemeDark,
      };

  Future<void> _chooseLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showRadioSheet<Locale>(
      context: context,
      title: l10n.settingsLanguage,
      current: AppLocales.fromCode(current.languageCode),
      options: {
        AppLocales.indonesian: l10n.settingsLanguageId,
        AppLocales.english: l10n.settingsLanguageEn,
      },
    );
    if (chosen != null) {
      await ref.read(localeControllerProvider.notifier).select(chosen);
    }
  }

  Future<void> _chooseTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showRadioSheet<ThemeMode>(
      context: context,
      title: l10n.settingsTheme,
      current: current,
      options: {
        for (final mode in [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
          mode: _themeName(l10n, mode),
      },
    );
    if (chosen != null) {
      await ref.read(themeModeControllerProvider.notifier).select(chosen);
    }
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.l,
        SpacingTokens.xl,
        SpacingTokens.l,
        SpacingTokens.s,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// A modal radio sheet with a visible close button (design-system.md 8.10).
/// Selecting an option applies it and closes the sheet.
Future<T?> showRadioSheet<T>({
  required BuildContext context,
  required String title,
  required T? current,
  required Map<T, String> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final theme = Theme.of(sheetContext);
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.l),
          child: RadioGroup<T>(
            groupValue: current,
            onChanged: (value) => Navigator.of(sheetContext).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: SpacingTokens.l,
                    right: SpacingTokens.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l10n.commonClose,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                for (final entry in options.entries)
                  RadioListTile<T>(value: entry.key, title: Text(entry.value)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
