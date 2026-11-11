// App shell (navigation.md 2): bottom navigation on compact windows, a
// navigation rail with labels on medium and expanded windows.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../router.dart';
import 'app_section.dart';
import 'bottom_navigation.dart';

/// True when the window is compact (up to 599dp wide, tokens.md 7).
bool isCompactWindow(BuildContext context) =>
    MediaQuery.sizeOf(context).width <= LayoutTokens.compactMax;

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.sections,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppSection> sections;

  void _select(int index) => navigationShell.goBranch(
    index,
    // Tapping the current tab returns to its root.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = navigationShell.currentIndex;
    final destinations = [
      for (final section in sections)
        ShellDestination(
          label: section.label(l10n),
          icon: section.icon,
          selectedIcon: section.selectedIcon,
        ),
    ];

    final Widget scaffold;
    if (isCompactWindow(context)) {
      scaffold = Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppBottomNavigation(
          destinations: destinations,
          selectedIndex: index,
          onSelected: _select,
        ),
      );
    } else {
      scaffold = Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: index,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                scrollable: true,
                trailingAtBottom: true,
                trailing: Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.l),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: l10n.navSettings,
                    onPressed: () => context.push(AppRoutes.settings),
                  ),
                ),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label, textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // Back from a non-Home tab root goes to Beranda; back from Beranda exits
    // (navigation.md 2). Pages pushed inside a tab pop first.
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: scaffold,
    );
  }
}
