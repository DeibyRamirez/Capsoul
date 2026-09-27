import 'package:capsoul/funcionalidades/autenticacion/datos/repositorio_autenticacion_firebase.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/fallo_autenticacion.dart';
import 'package:capsoul/funcionalidades/autenticacion/dominio/usuario_app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FirebaseAuthSimulado extends Mock implements FirebaseAuth {}

class _CredencialSimulada extends Mock implements UserCredential {}

class _UsuarioSimulado extends Mock implements User {}

void main() {
  late _FirebaseAuthSimulado firebaseAuth;
  late _CredencialSimulada credencial;
  late _UsuarioSimulado usuario;
  late RepositorioAutenticacionFirebase repositorio;

  const usuarioEsperado = UsuarioApp(
    uid: 'uid-1',
    correo: 'ana@capsoul.app',
    nombreVisible: 'Ana',
  );

  setUp(() {
    firebaseAuth = _FirebaseAuthSimulado();
    credencial = _CredencialSimulada();
    usuario = _UsuarioSimulado();
    repositorio = RepositorioAutenticacionFirebase(auth: firebaseAuth);

    when(() => usuario.uid).thenReturn('uid-1');
    when(() => usuario.email).thenReturn('ana@capsoul.app');
    when(() => usuario.displayName).thenReturn('Ana');
    when(() => usuario.emailVerified).thenReturn(false);
    when(() => credencial.user).thenReturn(usuario);
  });

  Matcher lanzaFalloAutenticacion(String codigo) => throwsA(
        isA<FalloAutenticacion>()
            .having((fallo) => fallo.codigo, 'codigo', codigo),
      );

  group('iniciarSesion', () {
    test('devuelve el UsuarioApp autenticado', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'ana@capsoul.app',
          password: 'secreta123',
        ),
      ).thenAnswer((_) async => credencial);

      final resultado = await repositorio.iniciarSesion(
        correo: 'ana@capsoul.app',
        contrasena: 'secreta123',
      );

      expect(resultado, usuarioEsperado);
    });

    for (final codigo in [
      'invalid-email',
      'invalid-credential',
      'user-disabled',
      'too-many-requests',
      'network-request-failed',
    ]) {
      test('traduce FirebaseAuthException $codigo a FalloAutenticacion', () {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: codigo));

        expect(
          () => repositorio.iniciarSesion(correo: 'a@b.co', contrasena: 'x'),
          lanzaFalloAutenticacion(codigo),
        );
      });
    }

    test('los errores no esperados se traducen a desconocido', () {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(StateError('fallo'));

      expect(
        () => repositorio.iniciarSesion(correo: 'a@b.co', contrasena: 'x'),
        lanzaFalloAutenticacion(FalloAutenticacion.codigoDesconocido),
      );
    });
  });

  group('registrarUsuario', () {
    test('crea la cuenta y asigna el nombre visible', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: 'ana@capsoul.app',
          password: 'secreta123',
        ),
      ).thenAnswer((_) async => credencial);
      when(() => usuario.updateDisplayName('Ana María'))
          .thenAnswer((_) async {});

      final resultado = await repositorio.registrarUsuario(
        nombre: 'Ana María',
        correo: 'ana@capsoul.app',
        contrasena: 'secreta123',
      );

      verify(() => usuario.updateDisplayName('Ana María')).called(1);
      expect(resultado.nombreVisible, 'Ana María');
      expect(resultado.uid, 'uid-1');
    });

    test('email-already-in-use se traduce a FalloAutenticacion', () {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        () => repositorio.registrarUsuario(
          nombre: 'Ana',
          correo: 'ana@capsoul.app',
          contrasena: 'secreta123',
        ),
        lanzaFalloAutenticacion('email-already-in-use'),
      );
    });
  });

  test('enviarCorreoRecuperacion delega en FirebaseAuth', () async {
    when(
      () => firebaseAuth.sendPasswordResetEmail(email: 'ana@capsoul.app'),
    ).thenAnswer((_) async {});

    await repositorio.enviarCorreoRecuperacion('ana@capsoul.app');

    verify(
      () => firebaseAuth.sendPasswordResetEmail(email: 'ana@capsoul.app'),
    ).called(1);
  });

  test('enviarCorreoVerificacion usa el usuario actual', () async {
    when(() => firebaseAuth.currentUser).thenReturn(usuario);
    when(() => usuario.sendEmailVerification()).thenAnswer((_) async {});

    await repositorio.enviarCorreoVerificacion();

    verify(() => usuario.sendEmailVerification()).called(1);
  });

  test('enviarCorreoVerificacion sin sesión lanza desconocido', () {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    expect(
      () => repositorio.enviarCorreoVerificacion(),
      lanzaFalloAutenticacion(FalloAutenticacion.codigoDesconocido),
    );
  });

  test('cambiosEstadoAutenticacion traduce User a UsuarioApp y null a null',
      () {
    when(() => firebaseAuth.authStateChanges())
        .thenAnswer((_) => Stream.fromIterable([usuario, null]));

    expect(
      repositorio.cambiosEstadoAutenticacion(),
      emitsInOrder([usuarioEsperado, null]),
    );
  });

  test('cerrarSesion delega en FirebaseAuth', () async {
    when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

    await repositorio.cerrarSesion();

    verify(() => firebaseAuth.signOut()).called(1);
  });
}
