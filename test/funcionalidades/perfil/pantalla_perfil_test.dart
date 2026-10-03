import 'package:capsoul/funcionalidades/autenticacion/dominio/usuario_app.dart';
import 'package:capsoul/funcionalidades/usuarios/dominio/perfil_usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ayudantes/app_prueba.dart';
import '../../ayudantes/falsos.dart';

void main() {
  // Sin emailConfirmedAt en el objeto local: aun así no hay aviso.
  const usuarioSinVerificar = UsuarioApp(
    uid: 'uid-123',
    correo: 'ana@capsoul.app',
    nombreVisible: 'Ana',
  );

  RepositorioUsuariosFalso usuariosConAna() => RepositorioUsuariosFalso()
    ..perfiles['uid-123'] = const PerfilUsuario(
      uid: 'uid-123',
      nombreVisible: 'Ana Supabase',
      correo: 'ana@capsoul.app',
    );

  Future<void> abrirPerfil(WidgetTester tester) async {
    await tester.tap(find.text('Yo').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'muestra el nombre de la tabla usuarios sin aviso de verificación',
      (tester) async {
    final autenticacion =
        RepositorioAutenticacionFalso(usuarioInicial: usuarioSinVerificar);
    await montarAppCapsoul(
      tester,
      autenticacion: autenticacion,
      usuarios: usuariosConAna(),
    );
    await abrirPerfil(tester);

    expect(find.text('Ana Supabase'), findsOneWidget);
    expect(find.text('ana@capsoul.app'), findsOneWidget);
    // Con "Confirm email" activo toda sesión tiene el correo confirmado.
    expect(find.text('Verifica tu correo electrónico'), findsNothing);
    expect(find.text('Reenviar correo'), findsNothing);
  });

  testWidgets('edita el nombre visible', (tester) async {
    final autenticacion =
        RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba);
    final usuarios = usuariosConAna();
    await montarAppCapsoul(
      tester,
      autenticacion: autenticacion,
      usuarios: usuarios,
    );
    await abrirPerfil(tester);

    expect(find.text('Verifica tu correo electrónico'), findsNothing);
    await tester.tap(find.text('Editar nombre'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      'Ana María',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(usuarios.perfiles['uid-123']?.nombreVisible, 'Ana María');
    expect(autenticacion.usuarioActual?.nombreVisible, 'Ana María');
    expect(find.text('Ana María'), findsOneWidget);
  });

  testWidgets('cerrar sesión vuelve a /iniciar-sesion', (tester) async {
    final autenticacion =
        RepositorioAutenticacionFalso(usuarioInicial: usuarioPrueba);
    await montarAppCapsoul(
      tester,
      autenticacion: autenticacion,
      usuarios: usuariosConAna(),
    );
    await abrirPerfil(tester);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(autenticacion.llamadasCerrarSesion, 1);
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
  });
}
