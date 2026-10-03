import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../elementos/dominio/elemento_borrador.dart';

/// Selector que abre el botón `+`: una cápsula nueva o un recuerdo suelto
/// (Video, Audio, Escribir, Foto) que se agrega a una cápsula nueva.
class PantallaSelectorCrear extends StatelessWidget {
  const PantallaSelectorCrear({super.key});

  /// Captura el recuerdo y, si el usuario lo usa, abre la cápsula nueva con
  /// ese recuerdo ya agregado (reemplaza al selector).
  static Future<void> _capturarYCrear(BuildContext context, String ruta) async {
    final elemento = await context.push<ElementoBorrador>(ruta);
    if (elemento == null || !context.mounted) return;
    context.pushReplacement(RutasApp.crearCapsula, extra: elemento);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cerrar',
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OpcionCrear(
            icono: Icons.hourglass_bottom,
            titulo: 'Cápsula del tiempo',
            subtitulo: 'Guarda hoy, abre en el futuro',
            destacada: true,
            alTocar: () => context.pushReplacement(RutasApp.crearCapsula),
          ),
          _OpcionCrear(
            icono: Icons.videocam_outlined,
            titulo: 'Video',
            subtitulo: 'Graba un recuerdo en video (hasta 60 s)',
            alTocar: () => _capturarYCrear(context, RutasApp.crearVideo),
          ),
          _OpcionCrear(
            icono: Icons.mic_none_outlined,
            titulo: 'Audio',
            subtitulo: 'Deja un mensaje de voz (hasta 5 min)',
            alTocar: () => _capturarYCrear(context, RutasApp.crearAudio),
          ),
          _OpcionCrear(
            icono: Icons.edit_outlined,
            titulo: 'Escribir',
            subtitulo: 'Escribe una nota o carta',
            alTocar: () => _capturarYCrear(context, RutasApp.crearEscribir),
          ),
          _OpcionCrear(
            icono: Icons.photo_outlined,
            titulo: 'Foto',
            subtitulo: 'Guarda una imagen especial',
            alTocar: () => _capturarYCrear(context, RutasApp.crearFoto),
          ),
        ],
      ),
    );
  }
}

class _OpcionCrear extends StatelessWidget {
  const _OpcionCrear({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.alTocar,
    this.destacada = false,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback alTocar;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final colorTexto =
        destacada ? ColoresApp.sobrePrimario : ColoresApp.sobreSuperficie;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: destacada ? ColoresApp.primario : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        ),
        leading: CircleAvatar(
          backgroundColor: destacada
              ? ColoresApp.sobrePrimario.withValues(alpha: 0.15)
              : ColoresApp.acento.withValues(alpha: 0.15),
          foregroundColor:
              destacada ? ColoresApp.sobrePrimario : ColoresApp.primario,
          child: Icon(icono),
        ),
        title: Text(
          titulo,
          style: TextStyle(fontWeight: FontWeight.w600, color: colorTexto),
        ),
        subtitle: Text(
          subtitulo,
          style: destacada
              ? TextStyle(color: colorTexto.withValues(alpha: 0.8))
              : null,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: destacada ? ColoresApp.sobrePrimario : ColoresApp.atenuado,
        ),
        onTap: alTocar,
      ),
    );
  }
}
