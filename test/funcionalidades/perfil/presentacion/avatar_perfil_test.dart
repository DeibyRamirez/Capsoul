import 'dart:async';

import 'package:capsoul/funcionalidades/perfil/aplicacion/proveedor_avatar_perfil.dart';
import 'package:capsoul/funcionalidades/perfil/presentacion/componentes/avatar_perfil.dart';
import 'package:capsoul/nucleo/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sin foto muestra la inicial', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const Scaffold(
            body: AvatarPerfil(inicial: 'A'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('con foto muestra indicador de carga al firmar', (tester) async {
    const publicId = 'capsoul/usuarios/u1/avatar';
    final completer = Completer<UrlsAvatar?>();
    addTearDown(() => completer.complete(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorUrlsAvatarPerfil(publicId).overrideWith(
            (ref) => completer.future,
          ),
        ],
        child: MaterialApp(
          theme: TemaApp.claro,
          home: const Scaffold(
            body: AvatarPerfil(
              inicial: 'A',
              fotoPublicId: publicId,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
