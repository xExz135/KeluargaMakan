// Routes (navigation.md 1 to 3). Each section keeps its own navigation stack.
// Deep links (keluargamakan://suggest, keluargamakan://cook/{id}) and the
// onboarding redirect are added with their features.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../features/dapur_saya/dapur_saya_screen.dart';
import '../features/keluarga_saya/keluarga_saya_screen.dart';
import '../features/masak_apa_hari_ini/home_screen.dart';
import '../features/rencana_mingguan/plan_screen.dart';
import '../features/resep/recipes_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell/app_section.dart';
import 'shell/app_shell.dart';

abstract final class AppRoutes {
  static const settings = '/settings';
}

GoRouter buildRouter(List<AppSection> sections) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppSection.home.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell, sections: sections),
        branches: [
          for (final section in sections)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: section.path,
                  builder: (context, state) => _rootScreen(section),
                ),
              ],
            ),
        ],
      ),
      // Full screen, above the navigation.
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

Widget _rootScreen(AppSection section) => switch (section) {
  AppSection.home => const HomeScreen(),
  AppSection.kitchen => const DapurSayaScreen(),
  AppSection.recipes => const RecipesScreen(),
  AppSection.plan => const PlanScreen(),
  AppSection.family => const KeluargaSayaScreen(),
};

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(AppSection.visible(ref.watch(appConfigProvider)));
  ref.onDispose(router.dispose);
  return router;
});
