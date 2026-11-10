import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../elementos/aplicacion/proveedores_elementos.dart';
import '../../elementos/dominio/elemento_borrador.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../elementos/presentacion/componentes/componentes_captura.dart';
import '../../elementos/presentacion/componentes/gestor_camara.dart';
import '../../musica/dominio/referencia_musica.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../aplicacion/proveedores_crear.dart';
import '../dominio/configuracion_crear.dart';
import '../dominio/modo_captura.dart';
import 'componentes/boton_captura.dart';
import 'componentes/chips_accion_hub.dart';
import 'componentes/rail_herramientas_camara.dart';
import 'componentes/scrim_camara.dart';
import 'componentes/selector_duracion_video.dart';
import 'componentes/selector_modo_captura.dart';
import 'flujo_publicar_desde_hub.dart';
import 'tema/tokens_crear.dart';

/// Hub de creación a pantalla completa (entrada desde el botón +).
class PantallaHubCrear extends ConsumerStatefulWidget {
  const PantallaHubCrear({super.key});

  @override
  ConsumerState<PantallaHubCrear> createState() => _EstadoPantallaHubCrear();
}

class _EstadoPantallaHubCrear extends ConsumerState<PantallaHubCrear>
    with WidgetsBindingObserver {
  GestorCamara? _camara;
  Timer? _relojVideo;
  bool _inicializandoCamara = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sincronizarCamara());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    final camara = _camara;
    if (camara == null) return;
    if (estado == AppLifecycleState.inactive) {
      final sesion = ref.read(proveedorControladorSesionCaptura);
      if (sesion.grabando) _detenerVideo();
      camara.pausar();
    }
    if (estado == AppLifecycleState.resumed) camara.reanudar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _relojVideo?.cancel();
    _camara?.dispose();
    super.dispose();
  }

  ModoCaptura get _modo => ref.read(proveedorControladorSesionCaptura).modo;

  bool get _paraVideo => _modo == ModoCaptura.video;

  Future<void> _sincronizarCamara() async {
    final modo = ref.read(proveedorControladorSesionCaptura).modo;
    if (modo == ModoCaptura.texto) return;
    final necesitaVideo = modo == ModoCaptura.video;
    final actual = _camara;
    if (actual != null && actual.paraVideo == necesitaVideo && actual.lista) {
      return;
    }
    setState(() => _inicializandoCamara = true);
    actual?.dispose();
    final nueva = GestorCamara(paraVideo: necesitaVideo);
    _camara = nueva;
    await nueva.iniciar();
    if (mounted) setState(() => _inicializandoCamara = false);
  }

  Future<void> _alCambiarModo(ModoCaptura modo) async {
    ref.read(proveedorControladorSesionCaptura.notifier).elegirModo(modo);
    if (modo == ModoCaptura.texto) {
      _camara?.dispose();
      _camara = null;
      if (!mounted) return;
      setState(() {});
      final borrador = await context.push<ElementoBorrador>(RutasApp.crearEscribir);
      if (borrador == null || !mounted) {
        ref.read(proveedorControladorSesionCaptura.notifier).elegirModo(ModoCaptura.video);
        await _sincronizarCamara();
        return;
      }
      await _finalizarConBorrador(borrador);
      return;
    }
    await _sincronizarCamara();
  }

  Future<void> _tomarFoto() async {
    final camara = _camara;
    final controlador = camara?.controlador;
    final sesion = ref.read(proveedorControladorSesionCaptura.notifier);
    if (controlador == null || camara == null || !camara.lista) return;
    sesion.marcarProcesando(true);
    try {
      final archivo = await controlador.takePicture();
      final bytes = await File(archivo.path).length();
      var elemento = ElementoBorrador(
        idLocal: ElementoBorrador.nuevoIdLocal(),
        tipo: TipoElemento.foto,
        rutaArchivo: archivo.path,
        bytes: bytes,
        esCamaraFrontal: camara.esFrontal,
      );
      elemento = await ref.read(proveedorCompresorMedios).prepararFoto(
            archivo.path,
            esCamaraFrontal: camara.esFrontal,
          );
      sesion.establecerCapturaLista(elemento);
    } on CameraException catch (error) {
      if (mounted) {
        mostrarAvisoError(context, GestorCamara.traducirErrorCamara(error.code));
      }
    } on FalloApp catch (fallo) {
      if (mounted) mostrarAvisoError(context, fallo);
    } finally {
      sesion.marcarProcesando(false);
    }
  }

  Future<void> _alternarVideo() async {
    final grabando = ref.read(proveedorControladorSesionCaptura).grabando;
    if (grabando) {
      await _detenerVideo();
    } else {
      await _empezarVideo();
    }
  }

  Future<void> _empezarVideo() async {
    final camara = _camara;
    final controlador = camara?.controlador;
    final sesion = ref.read(proveedorControladorSesionCaptura.notifier);
    if (controlador == null || camara == null || !camara.lista) return;
    try {
      await controlador.startVideoRecording();
    } on CameraException catch (error) {
      if (mounted) {
        mostrarAvisoError(context, GestorCamara.traducirErrorCamara(error.code));
      }
      return;
    }
    HapticFeedback.mediumImpact();
    sesion.iniciarGrabacion();
    _relojVideo?.cancel();
    final maximo = ref.read(proveedorControladorSesionCaptura).duracionMaxima;
    _relojVideo = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final actual = ref.read(proveedorControladorSesionCaptura).transcurrido;
      final siguiente = actual + const Duration(milliseconds: 250);
      ref.read(proveedorControladorSesionCaptura.notifier).tickGrabacion(siguiente);
      if (siguiente >= maximo) _detenerVideo();
    });
  }

  Future<void> _detenerVideo() async {
    final camara = _camara;
    final controlador = camara?.controlador;
    final sesion = ref.read(proveedorControladorSesionCaptura.notifier);
    if (controlador == null || !ref.read(proveedorControladorSesionCaptura).grabando) {
      return;
    }
    _relojVideo?.cancel();
    final transcurrido = ref.read(proveedorControladorSesionCaptura).transcurrido;
    sesion.detenerGrabacion();
    sesion.marcarProcesando(true);
    try {
      final archivo = await controlador.stopVideoRecording();
      final duracion = transcurrido > ref.read(proveedorControladorSesionCaptura).duracionMaxima
          ? ref.read(proveedorControladorSesionCaptura).duracionMaxima
          : transcurrido;
      final elemento = await ref
          .read(proveedorCompresorMedios)
          .prepararVideo(archivo.path, duracion);
      sesion.establecerCapturaLista(elemento);
    } on CameraException catch (error) {
      if (mounted) {
        mostrarAvisoError(context, GestorCamara.traducirErrorCamara(error.code));
      }
    } on FalloApp catch (fallo) {
      if (mounted) mostrarAvisoError(context, fallo);
    } finally {
      sesion.marcarProcesando(false);
    }
  }

  Future<void> _importarGaleria() async {
    final modo = _modo;
    if (modo == ModoCaptura.texto) return;
    final tipo = modo == ModoCaptura.video ? TipoElemento.video : TipoElemento.foto;
    try {
      final borrador = await ref.read(proveedorImportadorMedios).importar(tipo);
      if (!mounted) return;
      await _finalizarConBorrador(borrador);
    } on FalloApp catch (fallo) {
      if (mounted) mostrarAvisoError(context, fallo);
    }
  }

  Future<void> _finalizarConBorrador(ElementoBorrador borrador) async {
    final recuerdo = await continuarPublicacionDesdeHub(context, borrador);
    if (!mounted) return;
    if (recuerdo != null) {
      context.pop(recuerdo);
    }
  }

  Future<void> _usarCaptura() async {
    final borrador = ref.read(proveedorControladorSesionCaptura).capturaLista;
    if (borrador == null) return;
    await _finalizarConBorrador(borrador);
  }

  void _cerrar() {
    final sesion = ref.read(proveedorControladorSesionCaptura);
    if (sesion.grabando) {
      _detenerVideo();
    }
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final config = ConfiguracionCrear.porDefecto;
    final estado = ref.watch(proveedorControladorSesionCaptura);
    final controladorSesion = ref.read(proveedorControladorSesionCaptura.notifier);
    final camara = _camara;
    final capturaLista = estado.capturaLista;

    if (capturaLista != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _cerrar,
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Cerrar',
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: capturaLista.tipo == TipoElemento.foto
                      ? _VistaPreviaFotoHub(elemento: capturaLista)
                      : _VistaPreviaVideoHub(elemento: capturaLista),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            controladorSesion.repetirCaptura(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('Repetir'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: estado.procesando ? null : _usarCaptura,
                        style: FilledButton.styleFrom(
                          backgroundColor: ColoresApp.acento,
                        ),
                        child: const Text('Siguiente'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ocultarControles = estado.grabando;
    final errorCamara = camara?.error;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (estado.modo != ModoCaptura.texto)
              ListenableBuilder(
                listenable: camara ?? ChangeNotifier(),
                builder: (context, _) {
                  if (_inicializandoCamara || camara == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (errorCamara != null) {
                    return AvisoCaptura(
                      mensaje: errorCamara.mensaje,
                      alReintentar: () async {
                        await camara.iniciar();
                        setState(() {});
                      },
                    );
                  }
                  final controlador = camara.controlador;
                  if (controlador == null || !camara.lista) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return VistaCamara(controlador: controlador);
                },
              )
            else
              const ColoredBox(color: Colors.black),
            const ScrimCamara(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _cerrar,
                          icon: Icon(Icons.close, color: tokensCrearDe(context).superficieCamara),
                          tooltip: 'Cerrar',
                        ),
                        const Spacer(),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChipAccionHub(
                                etiqueta: 'Cápsula',
                                icono: Icons.hourglass_bottom,
                                alPresionar: () {
                                  context.pop();
                                  context.push(RutasApp.crearCapsula);
                                },
                              ),
                              const SizedBox(width: 6),
                              ChipAccionHub(
                                etiqueta: 'Momento',
                                icono: Icons.auto_awesome_mosaic_outlined,
                                alPresionar: () {
                                  context.pop();
                                  context.push(RutasApp.nuevoMomento);
                                },
                              ),
                              const SizedBox(width: 6),
                              ChipAccionHub(
                                etiqueta: 'Audio',
                                icono: Icons.mic_none_outlined,
                                alPresionar: () async {
                                  final b = await context.push<ElementoBorrador>(
                                    RutasApp.crearAudio,
                                  );
                                  if (b != null && mounted) await _finalizarConBorrador(b);
                                },
                              ),
                              const SizedBox(width: 6),
                              ChipAccionHub(
                                etiqueta: 'Música',
                                icono: Icons.music_note_outlined,
                                alPresionar: () async {
                                  final refMusica =
                                      await context.push<ReferenciaMusica>(
                                    RutasApp.crearMusica,
                                  );
                                  if (refMusica == null || !mounted) return;
                                  final borrador = ElementoBorrador(
                                    idLocal: ElementoBorrador.nuevoIdLocal(),
                                    tipo: TipoElemento.musica,
                                    referenciaMusica: refMusica,
                                  );
                                  await _finalizarConBorrador(borrador);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (estado.grabando && estado.modo == ModoCaptura.video)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ContadorGrabacion(
                        transcurrido: estado.transcurrido,
                        maximo: estado.duracionMaxima,
                        grabando: true,
                      ),
                    ),
                  const Spacer(),
                  if (estado.modo == ModoCaptura.video)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectorDuracionVideo(
                        opciones: config.duracionesVideo,
                        seleccionada: estado.duracionMaxima,
                        alCambiar: (d) => controladorSesion.elegirDuracion(d),
                        oculto: ocultarControles,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Abrir galería',
                          child: IconButton(
                            onPressed: ocultarControles ? null : _importarGaleria,
                            icon: const Icon(Icons.photo_library_outlined),
                            color: tokensCrearDe(context).superficieCamara,
                            iconSize: 32,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: estado.procesando
                                ? const SizedBox.square(
                                    dimension: 80,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : BotonCaptura(
                                    modo: estado.modo,
                                    grabando: estado.grabando,
                                    progreso: controladorSesion.progresoGrabacion,
                                    habilitado: camara?.lista ?? false,
                                    alTap: switch (estado.modo) {
                                      ModoCaptura.foto => _tomarFoto,
                                      ModoCaptura.video => _alternarVideo,
                                      ModoCaptura.texto => null,
                                    },
                                    alInicioLongPress: estado.modo == ModoCaptura.video
                                        ? _empezarVideo
                                        : null,
                                    alFinLongPress: estado.modo == ModoCaptura.video
                                        ? _detenerVideo
                                        : null,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  SelectorModoCaptura(
                    modos: config.modos,
                    seleccionado: estado.modo,
                    alCambiar: _alCambiarModo,
                    bloqueado: estado.bloquearModos || estado.grabando,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: MediaQuery.paddingOf(context).top + 72,
              child: RailHerramientasCamara(
                oculto: ocultarControles || camara == null,
                items: [
                  ItemRailCamara(
                    icono: Icons.cameraswitch_outlined,
                    etiqueta: 'Voltear',
                    alPresionar: camara != null &&
                            camara.puedeCambiar &&
                            !estado.grabando
                        ? () async {
                            await camara.cambiarCamara();
                            setState(() {});
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VistaPreviaFotoHub extends StatelessWidget {
  const _VistaPreviaFotoHub({required this.elemento});

  final ElementoBorrador elemento;

  @override
  Widget build(BuildContext context) {
    final ruta = elemento.rutaArchivo;
    if (ruta == null) return const SizedBox.shrink();
    return Transform.flip(
      flipX: elemento.esCamaraFrontal,
      child: Image.file(File(ruta), fit: BoxFit.contain),
    );
  }
}

class _VistaPreviaVideoHub extends StatelessWidget {
  const _VistaPreviaVideoHub({required this.elemento});

  final ElementoBorrador elemento;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_circle_outline, size: 96, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          formatearDuracion(elemento.duracion ?? Duration.zero),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
