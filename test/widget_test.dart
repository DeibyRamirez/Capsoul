import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:capsoul/app.dart';
import 'package:capsoul/features/create/presentation/create_selector_screen.dart';
import 'package:capsoul/features/home/presentation/home_screen.dart';
import 'package:capsoul/features/legacy/presentation/legacy_screen.dart';
import 'package:capsoul/features/moments/presentation/moments_screen.dart';
import 'package:capsoul/features/profile/presentation/profile_screen.dart';
import 'package:capsoul/features/shell/presentation/main_shell.dart';

void main() {
  testWidgets('CapsoulApp muestra shell de Inicio', (WidgetTester tester) async {
    final router = GoRouter(
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
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/moments',
                  builder: (context, state) => const MomentsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/legacy',
                  builder: (context, state) => const LegacyScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateSelectorScreen(),
        ),
      ],
    );

    await tester.pumpWidget(CapsoulApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Hola'), findsOneWidget);
    expect(find.text('Bienvenido a Capsoul'), findsOneWidget);
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Momentos'), findsWidgets);
    expect(find.text('Mi legado'), findsWidgets);
    expect(find.text('Yo'), findsWidgets);
  });
}