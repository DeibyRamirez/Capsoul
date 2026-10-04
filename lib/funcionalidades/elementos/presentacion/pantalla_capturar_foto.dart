import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../aplicacion/proveedores_elementos.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/validador_medios.dart';
import 'componentes/componentes_captura.dart';
import 'componentes/gestor_camara.dart';

/// Cámara para tomar una foto (frontal o trasera). Devuelve un
/// [ElementoBorrador] ya comprimido con `Navigator.pop`.
class PantallaCapturarFoto extends ConsumerStatefulWidget {
  const PantallaCapturarFoto({super.key});

  @override
  ConsumerState<PantallaCapturarFoto> createState() =>
      _EstadoPantallaCapturarFoto();
}

class _EstadoPantallaCapturarFoto extends ConsumerState<PantallaCapturarFoto>
    with WidgetsBindingObserver {
  final GestorCamara _camara = GestorCamara(paraVideo: false);
  ElementoBorrador? _capturada;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camara.iniciar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.inactive) _camara.pausar();
    if (estado == AppLifecycleState.resumed) _camara.reanudar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camara.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    final controlador = _camara.controlador;
    if (controlador == null || !_camara.lista || _procesando) return;
    setState(() => _procesando = true);
    try {
      final archivo = await controlador.takePicture();
      final elemento =
          await ref.read(proveedorCompresorMedios).prepararFoto(archivo.path);
      if (mounted) setState(() => _capturada = elemento);
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
    final capturada = _capturada;
    if (capturada != null) {
      return EstructuraCaptura(
        titulo: 'Foto',
        cuerpo: _VistaPreviaFoto(elemento: capturada),
        controles: BarraConfirmarCaptura(
          etiquetaUsar: 'Usar foto',
          alRepetir: () => setState(() => _capturada = null),
          alUsar: () => Navigator.of(context).pop(capturada),
        ),
      );
    }
    return ListenableBuilder(
      listenable: _camara,
      builder: (context, _) {
        final error = _camara.error;
        final controlador = _camara.controlador;
        return EstructuraCaptura(
          titulo: 'Foto',
          cuerpo: error != null
              ? AvisoCaptura(mensaje: error.mensaje, alReintentar: _camara.iniciar)
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
                          alPresionar: _camara.lista ? _tomarFoto : null,
                        ),
                  alCambiarCamara: _camara.puedeCambiar && !_procesando
                      ? _camara.cambiarCamara
                      : null,
                ),
        );
      },
    );
  }
}

class _VistaPreviaFoto extends StatelessWidget {
  const _VistaPreviaFoto({required this.elemento});

  final ElementoBorrador elemento;

  @override
  Widget build(BuildContext context) {
    final ruta = elemento.rutaArchivo;
    return Column(
      children: [
        Expanded(
          child: ruta == null
              ? const SizedBox.shrink()
              : Image.file(File(ruta), fit: BoxFit.contain),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${elemento.ancho} × ${elemento.alto} px · '
            '${formatearBytes(elemento.bytes)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
