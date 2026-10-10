import 'package:capsoul/funcionalidades/autenticacion/datos/repositorio_autenticacion_supabase.dart';
import 'package:capsoul/nucleo/infraestructura/proveedores/supabase/cliente_autenticacion_supabase.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/usuario_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _GoTrueSimulado extends Mock implements GoTrueClient {}

class _UsuarioSimulado extends Mock implements User {}

class _SesionSimulada extends Mock implements Session {}

class _RespuestaUsuarioSimulada extends Mock implements UserResponse {}

void main() {
  late _GoTrueSimulado auth;
  late _UsuarioSimulado usuario;
  late _SesionSimulada sesion;
  late RepositorioAutenticacionSupabase repositorio;

  const usuarioEsperado = UsuarioApp(
    uid: 'uid-1',
    correo: 'ana@capsoul.app',
    nombreVisible: 'Ana',
  );

  setUpAll(() {
    registerFallbackValue(UserAttributes());
    registerFallbackValue(OtpType.signup);
  });

  setUp(() {
    auth = _GoTrueSimulado();
    usuario = _UsuarioSimulado();
    sesion = _SesionSimulada();
    repositorio = RepositorioAutenticacionSupabase(
      ClienteAutenticacionSupabase(auth: auth),
    );

    when(() => usuario.id).thenReturn('uid-1');
    when(() => usuario.email).thenReturn('ana@capsoul.app');
    when(() => usuario.userMetadata).thenReturn({'nombre_visible': 'Ana'});
    when(() => usuario.emailConfirmedAt).thenReturn(null);
    when(() => sesion.user).thenReturn(usuario);
  });

  Matcher lanzaFalloAutenticacion(String codigo) => throwsA(
        isA<FalloAutenticacion>()
            .having((fallo) => fallo.codigo, 'codigo', codigo),
      );

  void simularInicioSesionQueLanza(Object error) {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(error);
  }

  group('iniciarSesion', () {
    test('devuelve el UsuarioApp autenticado', () async {
      when(
        () => auth.signInWithPassword(
          email: 'ana@capsoul.app',
          password: 'secreta123',
        ),
      ).thenAnswer((_) async => AuthResponse(session: sesion, user: usuario));

      final resultado = await repositorio.iniciarSesion(
        correo: 'ana@capsoul.app',
        contrasena: 'secreta123',
      );

      expect(resultado, usuarioEsperado);
    });

    test('marca el correo verificado según emailConfirmedAt', () async {
      when(() => usuario.emailConfirmedAt)
          .thenReturn('2026-10-02T12:00:00Z');
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse(session: sesion, user: usuario));

      final resultado = await repositorio.iniciarSesion(
        correo: 'ana@capsoul.app',
        contrasena: 'secreta123',
      );

      expect(resultado.correoVerificado, isTrue);
    });

    for (final codigo in [
      'invalid_credentials',
      'email_not_confirmed',
      'user_banned',
      'over_request_rate_limit',
      'email_address_invalid',
    ]) {
      test('traduce AuthApiException $codigo a FalloAutenticacion', () {
        simularInicioSesionQueLanza(
          AuthApiException('mensaje', statusCode: '400', code: codigo),
        );

        expect(
          () => repositorio.iniciarSesion(correo: 'a@b.co', contrasena: 'x'),
          lanzaFalloAutenticacion(codigo),
        );
      });
    }

    test('un 429 sin código se traduce a demasiados intentos', () {
      simularInicioSesionQueLanza(
        const AuthException('Too many requests', statusCode: '429'),
      );

      expect(
        () => repositorio.iniciarSesion(correo: 'a@b.co', contrasena: 'x'),
        lanzaFalloAutenticacion(FalloAutenticacion.codigoDemasiadosIntentos),
      );
    });

    test('un fallo de red se traduce a sin_red', () {
      simularInicioSesionQueLanza(AuthRetryableFetchException());

      expect(
        () => repositorio.iniciarSesion(correo: 'a@b.co', contrasena: 'x'),
        lanzaFalloAutenticacion(FalloAutenticacion.codigoSinRed),
      );
    });

    test('los errores no esperados se traducen a desconocido', () {
      simularInicioSesionQueLanza(StateError('fallo'));

      expect(
        () => repositorio.iniciarSesion(correo: 'a@b.co', contrasena: 'x'),
        lanzaFalloAutenticacion(FalloAutenticacion.codigoDesconocido),
      );
    });
  });

  group('registrarUsuario', () {
    void simularRegistro(AuthResponse respuesta) {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async => respuesta);
    }

    test(
        'envía nombre_visible para el trigger y el deep link de '
        'confirmación', () async {
      simularRegistro(AuthResponse(session: sesion, user: usuario));

      final resultado = await repositorio.registrarUsuario(
        nombre: 'Ana María',
        correo: 'ana@capsoul.app',
        contrasena: 'secreta123',
      );

      verify(
        () => auth.signUp(
          email: 'ana@capsoul.app',
          password: 'secreta123',
          data: {'nombre_visible': 'Ana María'},
          emailRedirectTo: 'capsoul://auth/confirmar',
        ),
      ).called(1);
      expect(resultado.usuario.uid, 'uid-1');
      expect(resultado.usuario.nombreVisible, 'Ana María');
      expect(resultado.sesionIniciada, isTrue);
    });

    test('sin sesión indica que falta confirmar el correo', () async {
      simularRegistro(AuthResponse(user: usuario));

      final resultado = await repositorio.registrarUsuario(
        nombre: 'Ana',
        correo: 'ana@capsoul.app',
        contrasena: 'secreta123',
      );

      expect(resultado.sesionIniciada, isFalse);
      expect(resultado.requiereConfirmarCorreo, isTrue);
    });

    test('user_already_exists se traduce a FalloAutenticacion', () {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenThrow(
        AuthApiException(
          'User already registered',
          statusCode: '422',
          code: 'user_already_exists',
        ),
      );

      expect(
        () => repositorio.registrarUsuario(
          nombre: 'Ana',
          correo: 'ana@capsoul.app',
          contrasena: 'secreta123',
        ),
        lanzaFalloAutenticacion('user_already_exists'),
      );
    });
  });

  test('enviarCorreoRecuperacion usa el deep link capsoul://auth/recuperar',
      () async {
    when(
      () => auth.resetPasswordForEmail(
        any(),
        redirectTo: any(named: 'redirectTo'),
      ),
    ).thenAnswer((_) async {});

    await repositorio.enviarCorreoRecuperacion('ana@capsoul.app');

    verify(
      () => auth.resetPasswordForEmail(
        'ana@capsoul.app',
        redirectTo: 'capsoul://auth/recuperar',
      ),
    ).called(1);
  });

  group('reenviarCorreoConfirmacion', () {
    void simularReenvio() {
      when(
        () => auth.resend(
          type: any(named: 'type'),
          email: any(named: 'email'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async => ResendResponse());
    }

    test('reenvía la confirmación de registro sin sesión con el deep link',
        () async {
      when(() => auth.currentUser).thenReturn(null);
      simularReenvio();

      await repositorio.reenviarCorreoConfirmacion('ana@capsoul.app');

      verify(
        () => auth.resend(
          type: OtpType.signup,
          email: 'ana@capsoul.app',
          emailRedirectTo: 'capsoul://auth/confirmar',
        ),
      ).called(1);
    });

    test('respeta una URL de confirmación inyectada', () async {
      simularReenvio();
      final cliente = ClienteAutenticacionSupabase(auth: auth);

      await cliente.reenviarCorreoConfirmacion(
        'ana@capsoul.app',
        urlConfirmacion: 'capsoul://auth/otra',
      );

      verify(
        () => auth.resend(
          type: OtpType.signup,
          email: 'ana@capsoul.app',
          emailRedirectTo: 'capsoul://auth/otra',
        ),
      ).called(1);
    });

    test('el límite de envíos se traduce a FalloAutenticacion', () {
      when(
        () => auth.resend(
          type: any(named: 'type'),
          email: any(named: 'email'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenThrow(
        AuthApiException(
          'Email rate limit exceeded',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
      );

      expect(
        () => repositorio.reenviarCorreoConfirmacion('ana@capsoul.app'),
        lanzaFalloAutenticacion('over_email_send_rate_limit'),
      );
    });
  });

  test('actualizarContrasena envía la contraseña nueva', () async {
    when(() => auth.updateUser(any()))
        .thenAnswer((_) async => _RespuestaUsuarioSimulada());

    await repositorio.actualizarContrasena('nueva-secreta1');

    final atributos =
        verify(() => auth.updateUser(captureAny())).captured.single
            as UserAttributes;
    expect(atributos.password, 'nueva-secreta1');
  });

  test('enlacesRecuperacion solo emite con el evento passwordRecovery',
      () async {
    when(() => auth.onAuthStateChange).thenAnswer(
      (_) => Stream.fromIterable([
        AuthState(AuthChangeEvent.signedIn, sesion),
        AuthState(AuthChangeEvent.passwordRecovery, sesion),
        AuthState(AuthChangeEvent.signedOut, null),
      ]),
    );

    expect(await repositorio.enlacesRecuperacion().length, 1);
  });

  test('actualizarNombreVisible guarda nombre_visible en los metadatos',
      () async {
    when(() => auth.updateUser(any()))
        .thenAnswer((_) async => _RespuestaUsuarioSimulada());

    await repositorio.actualizarNombreVisible('Ana María');

    final atributos =
        verify(() => auth.updateUser(captureAny())).captured.single
            as UserAttributes;
    expect(atributos.data, {'nombre_visible': 'Ana María'});
  });

  test('cambiosEstadoAutenticacion traduce la sesión a UsuarioApp o null', () {
    when(() => auth.onAuthStateChange).thenAnswer(
      (_) => Stream.fromIterable([
        AuthState(AuthChangeEvent.signedIn, sesion),
        AuthState(AuthChangeEvent.signedOut, null),
      ]),
    );

    expect(
      repositorio.cambiosEstadoAutenticacion(),
      emitsInOrder([usuarioEsperado, null]),
    );
  });

  test('cerrarSesion delega en signOut', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repositorio.cerrarSesion();

    verify(() => auth.signOut()).called(1);
  });
}
