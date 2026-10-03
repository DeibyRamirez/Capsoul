import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_elementos.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/limites_medios.dart';
import '../dominio/validador_medios.dart';
import 'componentes/componentes_captura.dart';
import 'componentes/gestor_camara.dart';

/// Graba un video de hasta 60 s en 720p (frontal o trasera) con contador.
/// Se detiene solo al llegar al máximo. Devuelve un [ElementoBorrador].
class PantallaCapturarVideo extends ConsumerStatefulWidget {
  const PantallaCapturarVideo({super.key});

  @override
  ConsumerState<PantallaCapturarVideo> createState() =>
      _EstadoPantallaCapturarVideo();
}

class _EstadoPantallaCapturarVideo
    extends ConsumerState<PantallaCapturarVideo> with WidgetsBindingObserver {
  static const Duration _intervalo = Duration(milliseconds: 250);

  final GestorCamara _camara = GestorCamara(paraVideo: true);
  ElementoBorrador? _grabado;
  bool _grabando = false;
  bool _procesando = false;
  Duration _transcurrido = Duration.zero;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camara.iniciar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.inactive) {
      if (_grabando) _detener();
      _camara.pausar();
    }
    if (estado == AppLifecycleState.resumed) _camara.reanudar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reloj?.cancel();
    _camara.dispose();
    super.dispose();
  }

  Future<void> _alternarGrabacion() =>
      _grabando ? _detener() : _empezar();

  Future<void> _empezar() async {
    final controlador = _camara.controlador;
    if (controlador == null || !_camara.lista || _procesando) return;
    try {
      await controlador.startVideoRecording();
    } on CameraException catch (error) {
      if (mounted) {
        mostrarAvisoError(context, GestorCamara.traducirErrorCamara(error.code));
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _grabando = true;
      _transcurrido = Duration.zero;
    });
    _reloj = Timer.periodic(_intervalo, (_) {
      if (!mounted) return;
      setState(() => _transcurrido += _intervalo);
      if (_transcurrido >= LimitesMedios.duracionMaxVideo) _detener();
    });
  }

  Future<void> _detener() async {
    final controlador = _camara.controlador;
    if (!_grabando || controlador == null) return;
    _reloj?.cancel();
    final duracion = _transcurrido > LimitesMedios.duracionMaxVideo
        ? LimitesMedios.duracionMaxVideo
        : _transcurrido;
    setState(() {
      _grabando = false;
      _procesando = true;
    });
    try {
      final archivo = await controlador.stopVideoRecording();
      final elemento = await ref
          .read(proveedorCompresorMedios)
          .prepararVideo(archivo.path, duracion);
      if (mounted) setState(() => _grabado = elemento);
    } on CameraException catch (error) {
      if (mounted) {
        mostrarAvisoError(context, GestorCamara.traducirErrorCamara(error.code));
      }
    } on FalloApp catch (fallo) {
      if (mounted) mostrarAvisoError(context, fallo);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grabado = _grabado;
    if (grabado != null) {
      return EstructuraCaptura(
        titulo: 'Video',
        cuerpo: _ResumenVideo(elemento: grabado),
        controles: BarraConfirmarCaptura(
          etiquetaUsar: 'Usar video',
          alRepetir: () => setState(() => _grabado = null),
          alUsar: () => Navigator.of(context).pop(grabado),
        ),
      );
    }
    return ListenableBuilder(
      listenable: _camara,
      builder: (context, _) {
        final error = _camara.error;
        final controlador = _camara.controlador;
        return EstructuraCaptura(
          titulo: 'Video',
          indicadorSuperior: error == null
              ? ContadorGrabacion(
                  transcurrido: _transcurrido,
                  maximo: LimitesMedios.duracionMaxVideo,
                  grabando: _grabando,
                )
              : null,
          cuerpo: error != null
              ? AvisoCaptura(
                  mensaje: error.mensaje,
                  alReintentar: _camara.iniciar,
                  icono: Icons.videocam_off_outlined,
                )
              : (controlador != null && _camara.lista
                  ? VistaCamara(controlador: controlador)
                  : const Center(child: CircularProgressIndicator())),
          controles: error != null
              ? null
              : ControlesCamara(
                  obturador: _procesando
                      ? const SizedBox.square(
                          dimension: 78,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : BotonObturador(
                          modoVideo: true,
                          grabando: _grabando,
                          alPresionar: _camara.lista ? _alternarGrabacion : null,
                        ),
                  alCambiarCamara:
                      _camara.puedeCambiar && !_grabando && !_procesando
                          ? _camara.cambiarCamara
                          : null,
                ),
        );
      },
    );
  }
}

class _ResumenVideo extends StatelessWidget {
  const _ResumenVideo({required this.elemento});

  final ElementoBorrador elemento;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_outline,
              size: 96, color: ColoresApp.sobrePrimario),
          const SizedBox(height: 16),
          Text(
            'Video listo',
            style: estilos.titleLarge?.copyWith(color: ColoresApp.sobrePrimario),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatearDuracion(elemento.duracion ?? Duration.zero)} · '
            '${formatearBytes(elemento.bytes)}',
            style: estilos.bodyMedium?.copyWith(
              color: ColoresApp.sobrePrimario.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
