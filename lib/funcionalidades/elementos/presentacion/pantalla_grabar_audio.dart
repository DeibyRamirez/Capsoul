import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/onda_audio.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/controlador_grabacion_audio.dart';
import '../dominio/limites_medios.dart';
import '../dominio/validador_medios.dart';
import 'componentes/componentes_captura.dart';

/// Grabadora de notas de voz (hasta 5 min) con onda en vivo. Devuelve un
/// [ElementoBorrador] con `Navigator.pop`.
class PantallaGrabarAudio extends ConsumerWidget {
  const PantallaGrabarAudio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      proveedorControladorGrabacionAudio.select((estado) => estado.error),
      (_, error) {
        if (error != null) mostrarAvisoError(context, error);
      },
    );
    final estado = ref.watch(proveedorControladorGrabacionAudio);
    final controlador = ref.read(proveedorControladorGrabacionAudio.notifier);
    final resultado = estado.resultado;

    return EstructuraCaptura(
      titulo: 'Nota de voz',
      indicadorSuperior: ContadorGrabacion(
        transcurrido: resultado?.duracion ?? estado.transcurrido,
        maximo: LimitesMedios.duracionMaxAudio,
        grabando: estado.fase == FaseGrabacion.grabando,
      ),
      cuerpo: _CuerpoGrabadora(estado: estado),
      controles: resultado != null
          ? BarraConfirmarCaptura(
              etiquetaUsar: 'Usar nota de voz',
              alRepetir: controlador.descartar,
              alUsar: () => Navigator.of(context).pop(resultado),
            )
          : _BotonMicrofono(
              fase: estado.fase,
              alPresionar: switch (estado.fase) {
                FaseGrabacion.lista => controlador.iniciar,
                FaseGrabacion.grabando => controlador.detener,
                _ => null,
              },
            ),
    );
  }
}

class _CuerpoGrabadora extends StatelessWidget {
  const _CuerpoGrabadora({required this.estado});

  final EstadoGrabacionAudio estado;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final resultado = estado.resultado;
    final texto = switch (estado.fase) {
      FaseGrabacion.lista => 'Toca el micrófono y cuenta lo que sientes.',
      FaseGrabacion.grabando => 'Grabando… toca para terminar.',
      FaseGrabacion.procesando => 'Preparando tu nota de voz…',
      FaseGrabacion.terminada =>
        'Nota de voz lista · ${formatearBytes(resultado?.bytes ?? 0)}',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OndaAudio(
            color: ColoresApp.sobrePrimario.withValues(alpha: 0.85),
            muestras: resultado?.muestrasOnda ?? estado.muestras,
            barras: 40,
            altura: 120,
            semilla: 3,
          ),
          const SizedBox(height: 32),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: estilos.titleMedium?.copyWith(color: ColoresApp.sobrePrimario),
          ),
        ],
      ),
    );
  }
}

class _BotonMicrofono extends StatelessWidget {
  const _BotonMicrofono({required this.fase, required this.alPresionar});

  final FaseGrabacion fase;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final grabando = fase == FaseGrabacion.grabando;
    final etiqueta = grabando ? 'Detener grabación' : 'Empezar a grabar';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: fase == FaseGrabacion.procesando
          ? const SizedBox.square(
              dimension: 84,
              child: Center(child: CircularProgressIndicator()),
            )
          : Tooltip(
              message: etiqueta,
              child: SizedBox.square(
                dimension: 84,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(84),
                    backgroundColor: grabando
                        ? Theme.of(context).colorScheme.error
                        : ColoresApp.acento,
                  ),
                  onPressed: alPresionar,
                  child: Icon(
                    grabando ? Icons.stop_rounded : Icons.mic_none_rounded,
                    size: 40,
                    semanticLabel: etiqueta,
                  ),
                ),
              ),
            ),
    );
  }
}
