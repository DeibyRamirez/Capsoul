import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../dominio/validador_medios.dart';

/// Vista de la cámara que llena el espacio disponible sin deformarse.
class VistaCamara extends StatelessWidget {
  const VistaCamara({super.key, required this.controlador});

  final CameraController controlador;

  @override
  Widget build(BuildContext context) {
    final tamano = controlador.value.previewSize;
    if (tamano == null) return const SizedBox.expand();
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            // previewSize viene en horizontal; la app está en vertical.
            width: tamano.height,
            height: tamano.width,
            child: CameraPreview(controlador),
          ),
        ),
      ),
    );
  }
}

/// Botón circular para capturar (foto) o iniciar/detener (video).
class BotonObturador extends StatelessWidget {
  const BotonObturador({
    super.key,
    required this.alPresionar,
    this.grabando = false,
    this.modoVideo = false,
  });

  final VoidCallback? alPresionar;
  final bool grabando;
  final bool modoVideo;

  @override
  Widget build(BuildContext context) {
    final etiqueta = !modoVideo
        ? 'Tomar foto'
        : (grabando ? 'Detener grabación' : 'Empezar a grabar');
    final colorInterior = modoVideo
        ? Theme.of(context).colorScheme.error
        : ColoresApp.sobrePrimario;
    return Semantics(
      button: true,
      label: etiqueta,
      child: Tooltip(
        message: etiqueta,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: alPresionar,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ColoresApp.sobrePrimario, width: 4),
            ),
            padding: const EdgeInsets.all(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.all(grabando ? 14 : 0),
              decoration: BoxDecoration(
                color: alPresionar == null
                    ? colorInterior.withValues(alpha: 0.4)
                    : colorInterior,
                borderRadius:
                    BorderRadius.circular(grabando ? TemaApp.radioPequeno / 2 : 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón para cambiar entre la cámara frontal y la trasera.
class BotonCambiarCamara extends StatelessWidget {
  const BotonCambiarCamara({super.key, required this.alPresionar});

  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      iconSize: 28,
      tooltip: 'Cambiar cámara',
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        backgroundColor: ColoresApp.sobrePrimario.withValues(alpha: 0.2),
        foregroundColor: ColoresApp.sobrePrimario,
      ),
      onPressed: alPresionar,
      icon: const Icon(Icons.cameraswitch_outlined),
    );
  }
}

/// Indicador "● 00:12 / 01:00" mientras se graba.
class ContadorGrabacion extends StatelessWidget {
  const ContadorGrabacion({
    super.key,
    required this.transcurrido,
    required this.maximo,
    this.grabando = true,
  });

  final Duration transcurrido;
  final Duration maximo;
  final bool grabando;

  @override
  Widget build(BuildContext context) {
    final colorError = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ColoresApp.primario.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: grabando ? colorError : ColoresApp.atenuado),
          const SizedBox(width: 8),
          Text(
            '${formatearDuracion(transcurrido)} / ${formatearDuracion(maximo)}',
            style: const TextStyle(
              color: ColoresApp.sobrePrimario,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje a pantalla completa cuando la captura no puede seguir (permiso,
/// sin cámara...).
class AvisoCaptura extends StatelessWidget {
  const AvisoCaptura({
    super.key,
    required this.mensaje,
    this.alReintentar,
    this.icono = Icons.no_photography_outlined,
  });

  final String mensaje;
  final VoidCallback? alReintentar;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: ColoresApp.sobrePrimario),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.sobrePrimario, fontSize: 16),
            ),
            if (alReintentar != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColoresApp.sobrePrimario,
                  side: const BorderSide(color: ColoresApp.sobrePrimario),
                ),
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Barra inferior "Repetir | Usar" tras capturar.
class BarraConfirmarCaptura extends StatelessWidget {
  const BarraConfirmarCaptura({
    super.key,
    required this.etiquetaUsar,
    required this.alUsar,
    required this.alRepetir,
  });

  final String etiquetaUsar;
  final VoidCallback alUsar;
  final VoidCallback alRepetir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ColoresApp.sobrePrimario,
                side: const BorderSide(color: ColoresApp.sobrePrimario),
              ),
              onPressed: alRepetir,
              icon: const Icon(Icons.replay),
              label: const Text('Repetir'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ColoresApp.acento,
              ),
              onPressed: alUsar,
              icon: const Icon(Icons.check),
              label: Text(etiquetaUsar),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estructura común de las pantallas de captura: fondo azul marino, botón
/// de cerrar, cuerpo y controles inferiores.
class EstructuraCaptura extends StatelessWidget {
  const EstructuraCaptura({
    super.key,
    required this.titulo,
    required this.cuerpo,
    this.controles,
    this.indicadorSuperior,
  });

  final String titulo;
  final Widget cuerpo;
  final Widget? controles;
  final Widget? indicadorSuperior;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.primario,
      appBar: AppBar(
        title: Text(titulo),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cerrar',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  cuerpo,
                  if (indicadorSuperior != null)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(child: indicadorSuperior),
                    ),
                ],
              ),
            ),
            ?controles,
          ],
        ),
      ),
    );
  }
}

/// Fila de controles de cámara: espacio | obturador | cambiar cámara.
class ControlesCamara extends StatelessWidget {
  const ControlesCamara({
    super.key,
    required this.obturador,
    required this.alCambiarCamara,
  });

  final Widget obturador;
  final VoidCallback? alCambiarCamara;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 56),
          obturador,
          SizedBox(
            width: 56,
            child: alCambiarCamara == null
                ? null
                : BotonCambiarCamara(alPresionar: alCambiarCamara),
          ),
        ],
      ),
    );
  }
}
