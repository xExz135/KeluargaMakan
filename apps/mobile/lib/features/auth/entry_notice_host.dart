// Shows one-time sign-in and sign-out messages over the screen that follows
// (EntryNotice): welcome back, session ended (dialog, then O2;
// contract-alignment.md 5) and local data not removed at sign-out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_entry.dart';

class EntryNoticeHost extends ConsumerWidget {
  const EntryNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<EntryNotice?>(entryNoticeProvider, (_, notice) {
      if (notice == null) return;
      // After the frame in which the router moved to the next screen, so
      // the message sits on that screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(entryNoticeProvider.notifier).clear();
        final navigator = ref
            .read(routerProvider)
            .routerDelegate
            .navigatorKey
            .currentContext;
        if (navigator == null || !navigator.mounted) return;
        _show(navigator, notice);
      });
    });
    return child;
  }

  static void _show(BuildContext context, EntryNotice notice) {
    final l10n = AppLocalizations.of(context);
    void snack(String text) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
    switch (notice) {
      case EntryNotice.welcomeBack:
        snack(l10n.onboardingWelcomeBack);
      case EntryNotice.localDataNotCleared:
        snack(l10n.settingsSignOutDataNotCleared);
      case EntryNotice.sessionExpired:
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text(l10n.errorApiSignedOut),
            content: Text(l10n.errorApiSignedOutBody),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonContinue),
              ),
            ],
          ),
        );
    }
  }
}
