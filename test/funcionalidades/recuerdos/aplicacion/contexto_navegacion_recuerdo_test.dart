import 'package:capsoul/funcionalidades/recuerdos/presentacion/componentes/hoja_nuevo_recuerdo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('contextoNavegacionPrincipal devuelve el host del GoRouter', (
    tester,
  ) async {
    late BuildContext hostCapturado;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            hostCapturado = context;
            return const Scaffold(body: Text('host'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final nav = contextoNavegacionPrincipal(hostCapturado);
    expect(nav, isNotNull);
    expect(nav!.mounted, isTrue);
    expect(find.text('host'), findsOneWidget);
  });
}
