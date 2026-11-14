// Routes (navigation.md 1 to 3). Each section keeps its own navigation stack.
// Deep links (keluargamakan://suggest, keluargamakan://cook/{id}) are added
// with their features.
//
// The onboarding redirect (flow.md 1 and 5, home-navigation.md 3): without a
// session every route leads to O1 (or O2 after the session ended); a signed-in
// account without a household goes to O3; the shell opens only when the
// household is known.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../core/config/app_config.dart';
import '../features/auth/app_entry.dart';
import '../features/auth/auth_routes.dart';
import '../features/auth/code_entry_screen.dart';
import '../features/auth/contact_entry_screen.dart';
import '../features/auth/name_screen.dart';
import '../features/auth/sign_in_draft.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/startup_screen.dart';
import '../features/auth/welcome_screen.dart';
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

/// Where [entry] allows the user to be, or null to stay at [location].
String? entryRedirect(AppEntry entry, String location) {
  final signedOutRoute = AuthRoutes.isSignedOutRoute(location);
  return switch (entry) {
    EntrySignedOut(:final atSignIn) =>
      signedOutRoute
          ? null
          : (atSignIn ? AuthRoutes.signIn : AuthRoutes.welcome),
    EntryResolving() =>
      location == AuthRoutes.starting ? null : AuthRoutes.starting,
    EntryNeedsHousehold() =>
      location == AuthRoutes.name ? null : AuthRoutes.name,
    EntryReady() =>
      signedOutRoute ||
              location == AuthRoutes.name ||
              location == AuthRoutes.starting
          ? AppSection.home.path
          : null,
  };
}

GoRouter buildRouter(
  List<AppSection> sections, {
  required AppEntry Function() entry,
  required bool Function() hasSignInDraft,
  Listenable? refresh,
}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  GoRoute contactRoute(api.SignInChannel channel, String path) => GoRoute(
    path: path,
    builder: (context, state) => ContactEntryScreen(channel: channel),
    routes: [
      GoRoute(
        path: 'code',
        // The code screen needs the challenge held in memory; after a
        // process restart it is gone, so start again from O2a.
        redirect: (context, state) =>
            hasSignInDraft() ? null : AuthRoutes.contact(channel),
        builder: (context, state) => CodeEntryScreen(channel: channel),
      ),
    ],
  );

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppSection.home.path,
    refreshListenable: refresh,
    redirect: (context, state) => entryRedirect(entry(), state.matchedLocation),
    routes: [
      GoRoute(
        path: AuthRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'sign-in',
            builder: (context, state) => const SignInScreen(),
            routes: [
              contactRoute(api.SignInChannel.phone, 'phone'),
              contactRoute(api.SignInChannel.email, 'email'),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AuthRoutes.name,
        builder: (context, state) => const NameScreen(),
      ),
      GoRoute(
        path: AuthRoutes.starting,
        builder: (context, state) => const StartupScreen(),
      ),
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
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(appEntryProvider, (_, _) => refresh.value++)
    ..listen(signInDraftProvider, (previous, next) {
      // Only losing the draft changes where the code route may lead.
      if (next == null && previous != null) refresh.value++;
    });
  final router = buildRouter(
    AppSection.visible(ref.watch(appConfigProvider)),
    entry: () => ref.read(appEntryProvider),
    hasSignInDraft: () => ref.read(signInDraftProvider) != null,
    refresh: refresh,
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
