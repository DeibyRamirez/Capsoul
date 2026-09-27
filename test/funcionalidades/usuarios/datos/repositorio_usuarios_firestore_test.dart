import 'package:capsoul/funcionalidades/usuarios/datos/repositorio_usuarios_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late RepositorioUsuariosFirestore repositorio;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repositorio = RepositorioUsuariosFirestore(firestore: firestore);
  });

  Future<Map<String, dynamic>> leerDocumento(String uid) async {
    final instantanea =
        await firestore.collection('usuarios').doc(uid).get();
    return instantanea.data()!;
  }

  test('crearPerfil crea usuarios/{uid} con los campos en español', () async {
    await repositorio.crearPerfil(
      uid: 'uid-1',
      nombreVisible: 'Ana',
      correo: 'ana@capsoul.app',
    );

    final datos = await leerDocumento('uid-1');
    expect(
      datos.keys,
      unorderedEquals(['nombreVisible', 'correo', 'fotoUrl', 'creadoEn']),
    );
    expect(datos['nombreVisible'], 'Ana');
    expect(datos['correo'], 'ana@capsoul.app');
    expect(datos['fotoUrl'], isNull);
    expect(datos['creadoEn'], isA<Timestamp>());
  });

  test('observarPerfil emite el perfil y null si no existe', () async {
    expect(await repositorio.observarPerfil('nadie').first, isNull);

    await repositorio.crearPerfil(
      uid: 'uid-1',
      nombreVisible: 'Ana',
      correo: 'ana@capsoul.app',
    );
    final perfil = await repositorio.observarPerfil('uid-1').first;

    expect(perfil, isNotNull);
    expect(perfil!.uid, 'uid-1');
    expect(perfil.nombreVisible, 'Ana');
    expect(perfil.correo, 'ana@capsoul.app');
    expect(perfil.creadoEn, isNotNull);
  });

  test('observarPerfil trata los documentos mal formados como inexistentes',
      () async {
    await firestore.collection('usuarios').doc('uid-1').set({
      'nombreVisible': 42,
    });

    expect(await repositorio.observarPerfil('uid-1').first, isNull);
  });

  test('guardarNombreVisible actualiza solo el nombre', () async {
    await repositorio.crearPerfil(
      uid: 'uid-1',
      nombreVisible: 'Ana',
      correo: 'ana@capsoul.app',
    );

    await repositorio.guardarNombreVisible(
      uid: 'uid-1',
      nombreVisible: 'Ana María',
      correo: 'ana@capsoul.app',
    );

    final datos = await leerDocumento('uid-1');
    expect(datos['nombreVisible'], 'Ana María');
    expect(datos['correo'], 'ana@capsoul.app');
  });

  test('guardarNombreVisible crea el documento si falta', () async {
    await repositorio.guardarNombreVisible(
      uid: 'uid-2',
      nombreVisible: 'Luis',
      correo: 'luis@capsoul.app',
    );

    final datos = await leerDocumento('uid-2');
    expect(datos['nombreVisible'], 'Luis');
    expect(datos['fotoUrl'], isNull);
  });

  test('no escribe en la colección antigua users', () async {
    await repositorio.crearPerfil(
      uid: 'uid-1',
      nombreVisible: 'Ana',
      correo: 'ana@capsoul.app',
    );

    final antigua = await firestore.collection('users').doc('uid-1').get();
    expect(antigua.exists, isFalse);
  });
}
