import 'dart:async';

import 'package:capsoul/nucleo/enlaces/enlace_capsoul.dart';
import 'package:capsoul/nucleo/firebase/aviso_push.dart';
import 'package:capsoul/nucleo/firebase/canal_avisos.dart';
import 'package:capsoul/nucleo/firebase/coordinador_avisos_push.dart';
import 'package:capsoul/nucleo/firebase/destino_aviso.dart';
import 'package:capsoul/nucleo/enrutador/rutas_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la ruta del aviso abre la cápsula', () {
    const id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
    final destino = destinoInternoDeAviso(EnlaceCapsoul.capsula(id));
    expect(destino, RutasApp.detalleCapsulaDe(id));
    expect(destinoInternoDeAviso(EnlaceCapsoul.amigos()), RutasApp.amigos);
    expect(
      destinoInternoDeAviso(EnlaceCapsoul.herencia(id)),
      RutasApp.detalleHerenciaDe(id),
    );
    expect(destinoInternoDeAviso(EnlaceCapsoul.reto(id)), RutasApp.retos);
    expect(destinoInternoDeAviso('https://capsoul.app/otra'), isNull);
  });

  test('Android 13 pide POST_NOTIFICATIONS', () {
    expect(CanalAvisos.debePedirPermiso(32), isFalse);
    expect(CanalAvisos.debePedirPermiso(33), isTrue);
    expect(CanalAvisos.id, 'capsoul_avisos');
  });

  test('primer plano, toque y app cerrada', () async {
    final fuente = _FuenteFalsa();
    final presentador = _PresentadorFalso();
    final tokens = <String>[];
    final rutas = <String>[];
    final sesion = SesionAvisosPush(
      fuente: fuente,
      presentador: presentador,
      alRegistrarToken: (token) async => tokens.add(token),
      alAbrirRuta: rutas.add,
      esAndroid: true,
      esIos: false,
      sdkAndroid: 33,
    );
    fuente
      ..token = 'token-1'
      ..inicial = mensajeDesdeMapa(
        titulo: 'Tienes una cápsula nueva',
        cuerpo: '«Viaje al río» ya se puede abrir.',
        datos: {
          'ruta': 'capsoul://capsula/cap-1',
          'capsula_id': 'cap-1',
        },
      );
    presentador.ruta = null;

    await sesion.iniciar();
    expect(presentador.canal, CanalAvisos.id);
    expect(presentador.permisoPedido, isTrue);
    expect(fuente.segundoPlanoRegistrado, isTrue);
    expect(tokens, ['token-1']);
    expect(rutas, ['capsoul://capsula/cap-1']);

    fuente.primerPlano.add(
      const MensajePush(
        titulo: 'Tienes una cápsula nueva',
        cuerpo: '«Otra» ya se puede abrir.',
        ruta: 'capsoul://capsula/cap-2',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(presentador.mostrados.single.ruta, 'capsoul://capsula/cap-2');

    fuente.abiertos.add(
      const MensajePush(ruta: 'capsoul://capsula/cap-3'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(rutas.last, 'capsoul://capsula/cap-3');

    fuente.renovaciones.add('token-2');
    await Future<void>.delayed(Duration.zero);
    expect(tokens, ['token-1', 'token-2']);

    sesion.cerrar();
    await fuente.cerrar();
  });

  test('Android 12 no pide el permiso de runtime y iOS no crea el canal', () async {
    final android = _FuenteFalsa();
    final bandeja = _PresentadorFalso();
    final sesionAndroid = SesionAvisosPush(
      fuente: android,
      presentador: bandeja,
      alRegistrarToken: (_) async {},
      alAbrirRuta: (_) {},
      esAndroid: true,
      esIos: false,
      sdkAndroid: 32,
    );
    await sesionAndroid.iniciar();
    expect(bandeja.canal, CanalAvisos.id);
    expect(bandeja.permisoPedido, isFalse);
    sesionAndroid.cerrar();

    final ios = _FuenteFalsa();
    final presentadorIos = _PresentadorFalso();
    final sesionIos = SesionAvisosPush(
      fuente: ios,
      presentador: presentadorIos,
      alRegistrarToken: (_) async {},
      alAbrirRuta: (_) {},
      esAndroid: false,
      esIos: true,
      sdkAndroid: 0,
    );
    await sesionIos.iniciar();
    expect(ios.permisoIos, isTrue);
    expect(ios.presentacionIos, isTrue);
    expect(presentadorIos.canal, isNull);
    sesionIos.cerrar();
    await android.cerrar();
    await ios.cerrar();
  });
}

class _FuenteFalsa implements FuenteMensajesPush {
  final primerPlano = StreamController<MensajePush>();
  final abiertos = StreamController<MensajePush>();
  final renovaciones = StreamController<String>();
  String? token;
  MensajePush? inicial;
  var segundoPlanoRegistrado = false;
  var permisoIos = false;
  var presentacionIos = false;

  @override
  Future<void> pedirPermisoIos() async {
    permisoIos = true;
  }

  @override
  Future<void> presentarEnPrimerPlanoIos() async {
    presentacionIos = true;
  }

  @override
  Future<String?> tokenActual() async => token;

  @override
  Stream<String> get renovacionesToken => renovaciones.stream;

  @override
  Stream<MensajePush> get enPrimerPlano => primerPlano.stream;

  @override
  Stream<MensajePush> get alAbrirDesdeAviso => abiertos.stream;

  @override
  Future<MensajePush?> mensajeQueAbrioLaApp() async => inicial;

  @override
  void registrarManejadorSegundoPlano() {
    segundoPlanoRegistrado = true;
  }

  Future<void> cerrar() async {
    await primerPlano.close();
    await abiertos.close();
    await renovaciones.close();
  }
}

class _PresentadorFalso implements PresentadorAvisos {
  String? canal;
  var permisoPedido = false;
  final mostrados = <MensajePush>[];
  String? ruta;

  @override
  Future<void> prepararCanal(String idCanal) async {
    canal = idCanal;
  }

  @override
  Future<void> pedirPermiso() async {
    permisoPedido = true;
  }

  @override
  Future<void> mostrar(MensajePush mensaje) async {
    mostrados.add(mensaje);
  }

  @override
  Future<String?> rutaPendiente() async => ruta;
}
