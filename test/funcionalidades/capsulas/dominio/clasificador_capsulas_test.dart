import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/capsula_recibida.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/clasificador_capsulas.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_visible_capsula.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ahora = DateTime(2026, 10, 1, 12);

  Capsula capsula({
    required String id,
    List<String> destinatarios = const [],
    bool correo = false,
    EstadoCapsula estado = EstadoCapsula.programada,
  }) =>
      Capsula(
        id: id,
        autorId: 'yo',
        titulo: id,
        estado: estado,
        creadoEn: ahora,
        destinatariosUsuarioIds: destinatarios,
        tieneCorreoExterno: correo,
      );

  CapsulaRecibida recibida(String autor) => CapsulaRecibida(
        id: 'r-$autor',
        autorId: autor,
        autorNombre: autor,
        fechaApertura: ahora,
        estado: EstadoCapsula.programada,
      );

  test('parte el listado del autor sin duplicar', () {
    final lista = [
      capsula(id: 'enviada', destinatarios: const ['amigo']),
      capsula(id: 'mia', destinatarios: const ['yo']),
      capsula(id: 'mixta', destinatarios: const ['yo', 'amigo']),
      capsula(id: 'externa', destinatarios: const ['yo'], correo: true),
      capsula(id: 'vacia'),
      capsula(
        id: 'cancelada-mia',
        destinatarios: const ['yo'],
        estado: EstadoCapsula.cancelada,
      ),
    ];

    expect(capsulasEnviadas(lista).map((c) => c.id), [
      'enviada',
      'mixta',
      'externa',
      'vacia',
    ]);
    expect(capsulasParaMiMismo(lista).map((c) => c.id), [
      'mia',
      'cancelada-mia',
    ]);
  });

  test('para mí no repite las que yo mismo envié', () {
    final lista = [recibida('otro'), recibida('yo')];
    expect(
      recibidasDeOtrasPersonas(lista, 'yo').map((c) => c.autorId),
      ['otro'],
    );
  });

  test('el estado visible no usa la fecha como si ya estuviera lista', () {
    expect(
      presentarEstadoCapsula(
        estado: EstadoCapsula.programada,
        abierta: false,
        fechaApertura: ahora.subtract(const Duration(hours: 1)),
        ahora: ahora,
      ).visible,
      EstadoVisibleCapsula.programada,
    );
    final pasada = presentarEstadoCapsula(
      estado: EstadoCapsula.programada,
      abierta: false,
      fechaApertura: ahora.subtract(const Duration(hours: 1)),
      ahora: ahora,
    );
    expect(pasada.aviso, 'Aún no liberada');
    expect(pasada.conCandado, isTrue);

    expect(
      estadoVisibleCapsula(estado: EstadoCapsula.liberada, abierta: false),
      EstadoVisibleCapsula.listaParaAbrir,
    );
    expect(
      estadoVisibleCapsula(estado: EstadoCapsula.liberada, abierta: true),
      EstadoVisibleCapsula.abierta,
    );
    expect(
      presentarEstadoCapsula(
        estado: EstadoCapsula.programada,
        abierta: false,
        fechaApertura: DateTime(2046, 9, 14, 8, 5),
        ahora: ahora,
      ).detalle,
      '14 sep 2046 · 08:05',
    );
  });
}
