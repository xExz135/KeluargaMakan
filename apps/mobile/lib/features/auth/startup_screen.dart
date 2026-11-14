// Shown while the household of a signed-in account is looked up: after a
// sign-in on this phone, or at startup when no household is cached (flow.md
// 5). Found → Beranda; none yet → O3; no answer → error with "Coba lagi".

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_entry.dart';
import 'widgets/onboarding_scaffold.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (!mounted) return;
    setState(() => _slow = false);
    final slowAfter = Duration(
      milliseconds: ref.read(appConfigProvider).get(ConfigKeys.slowLoadingMs),
    );
    _slowTimer?.cancel();
    _slowTimer = Timer(slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
    await ref.read(appEntryProvider.notifier).resolveHousehold();
    _slowTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entry = ref.watch(appEntryProvider);
    final failed = entry is EntryResolving && entry.failed;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xl),
            child: OnboardingFrame(
              child: failed
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InlineMessage(
                          key: const Key('startup.error'),
                          title: l10n.errorGenericTitle,
                          text: l10n.errorGenericBody,
                        ),
                        const SizedBox(height: SpacingTokens.l),
                        OnboardingButton(
                          key: const Key('startup.retry'),
                          label: l10n.commonRetry,
                          onPressed: _resolve,
                        ),
                      ],
                    )
                  : Semantics(
                      liveRegion: true,
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: SpacingTokens.l),
                          Text(
                            _slow ? l10n.stateLoadingSlow : l10n.commonLoading,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
