import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/providers.dart';
import '../features/authentication/presentation/auth_screens.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/affection/presentation/affection_screens.dart';
import '../features/inbox/presentation/inbox_screens.dart';
import '../features/memories/presentation/memories_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/pairing/presentation/pairing_screen.dart';
import '../features/animation/presentation/player_screen.dart';
import '../features/affection/domain/models.dart';
import '../features/together/presentation/together_screen.dart';
import '../core/widgets/app_shell.dart';
import '../features/touch_echo/presentation/touch_mode_screen.dart';
import '../features/touch_echo/data/touch_echo_repository.dart';
import 'configuration/bootstrap.dart';
import 'theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.listen(pairProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path.startsWith('/studio')) return null;
      final ready = ref.read(bootstrapProvider).ready;
      const public = ['/welcome', '/login', '/register', '/forgot-password'];
      if (!ready) return public.contains(path) ? null : '/welcome';
      final auth = ref.read(authProvider);
      if (auth.isLoading) return path == '/splash' ? null : '/splash';
      if (auth.value == null) return public.contains(path) ? null : '/welcome';
      final pair = ref.read(pairProvider);
      if (pair.isLoading) return path == '/splash' ? null : '/splash';
      if (pair.value?.active != true) {
        return path == '/pairing' || path == '/settings' || path == '/profile'
            ? null
            : '/pairing';
      }
      if (path == '/pairing') return '/pairing/success';
      if (public.contains(path) || path == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const AuthScreen(mode: AuthMode.login),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const AuthScreen(mode: AuthMode.register),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const AuthScreen(mode: AuthMode.reset),
      ),
      GoRoute(path: '/pairing', builder: (_, _) => const PairingScreen()),
      GoRoute(
        path: '/pairing/success',
        builder: (_, _) => const PairingSuccessScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/affection',
            builder: (_, _) => const AffectionLibrary(),
          ),
          GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
          GoRoute(path: '/memories', builder: (_, _) => const MemoriesScreen()),
        ],
      ),
      GoRoute(
        path: '/affection/preview',
        builder: (_, state) =>
            ComposeScreen(typeName: state.uri.queryParameters['type']),
      ),
      GoRoute(
        path: '/inbox/:id',
        builder: (_, state) => SurpriseScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/moment/:id/play',
        builder: (_, state) => PlayerScreen(
          id: state.pathParameters['id']!,
          payload: state.extra is ProtectedMomentPayload
              ? state.extra as ProtectedMomentPayload
              : null,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const SettingsScreen(profileOnly: true),
      ),
      GoRoute(
        path: '/customize',
        builder: (_, _) => const SettingsScreen(customizeOnly: true),
      ),
      GoRoute(path: '/together', builder: (_, _) => const TogetherScreen()),
      GoRoute(
        path: '/touch',
        builder: (_, state) =>
            TouchModeScreen(replyTo: state.uri.queryParameters['replyTo']),
      ),
      GoRoute(
        path: '/studio/touch',
        builder: (_, _) => const TouchModeScreen(studio: true),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, studio: true, child: child),
        routes: [
          GoRoute(
            path: '/studio',
            builder: (_, _) => const HomeScreen(studio: true),
          ),
          GoRoute(
            path: '/studio/affection',
            builder: (_, _) => const AffectionLibrary(studio: true),
          ),
          GoRoute(
            path: '/studio/inbox',
            builder: (_, _) => const InboxScreen(studio: true),
          ),
          GoRoute(
            path: '/studio/memories',
            builder: (_, _) => const MemoriesScreen(studio: true),
          ),
        ],
      ),
      GoRoute(
        path: '/studio/preview',
        builder: (_, state) => ComposeScreen(
          studio: true,
          typeName: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/studio/play',
        builder: (_, state) => PlayerScreen(
          studio: true,
          typeName: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/studio/settings',
        builder: (_, _) => const SettingsScreen(studio: true),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/welcome'),
          child: const Text('Let’s go back to our little world'),
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class BearWithMeApp extends ConsumerWidget {
  const BearWithMeApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Restore only the currently authenticated pair's explicitly queued touch.
    ref.watch(touchEchoRepositoryProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Bear With Me',
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
