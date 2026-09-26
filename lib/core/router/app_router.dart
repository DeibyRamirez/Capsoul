import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/create/presentation/create_selector_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/legacy/presentation/legacy_screen.dart';
import '../../features/moments/presentation/moments_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/moments',
                name: 'moments',
                builder: (context, state) => const MomentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/legacy',
                name: 'legacy',
                builder: (context, state) => const LegacyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateSelectorScreen(),
        routes: [
          GoRoute(
            path: 'video',
            name: 'create-video',
            builder: (context, state) =>
                const CreatePlaceholderScreen(modality: 'Video'),
          ),
          GoRoute(
            path: 'audio',
            name: 'create-audio',
            builder: (context, state) =>
                const CreatePlaceholderScreen(modality: 'Audio'),
          ),
          GoRoute(
            path: 'escribir',
            name: 'create-escribir',
            builder: (context, state) =>
                const CreatePlaceholderScreen(modality: 'Escribir'),
          ),
          GoRoute(
            path: 'foto',
            name: 'create-foto',
            builder: (context, state) =>
                const CreatePlaceholderScreen(modality: 'Foto'),
          ),
        ],
      ),
    ],
  );
}