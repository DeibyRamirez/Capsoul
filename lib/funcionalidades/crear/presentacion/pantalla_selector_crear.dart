import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../recuerdos/presentacion/componentes/hoja_nuevo_recuerdo.dart';

/// Selector que abre el botón `+`: una cápsula nueva o un recuerdo nuevo
/// (Video, Audio, Escribir, Foto) que se guarda en el banco de recuerdos.
class PantallaSelectorCrear extends StatelessWidget {
  const PantallaSelectorCrear({super.key});

  /// Captura y guarda el recuerdo; si se guardó, reemplaza el selector por
  /// el banco de recuerdos.
  static Future<void> _nuevoRecuerdo(
    BuildContext context,
    TipoElemento tipo,
  ) async {
    final recuerdo = await capturarRecuerdo(context, tipo);
    if (recuerdo == null || !context.mounted) return;
    context.pushReplacement(RutasApp.recuerdos);
  }

  @override
  Widget build(BuildContext context) {
    return PantallaCapsoul(
      appBar: AppBar(
        title: const Text('Crear'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cerrar',
          onPressed: () => context.pop(),
        ),
      ),
      cuerpo: ListView(
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
            icono: Icons.auto_awesome_mosaic_outlined,
            titulo: 'Momento',
            subtitulo: 'Junta varios recuerdos bajo un nombre',
            alTocar: () => context.pushReplacement(RutasApp.nuevoMomento),
          ),
          const _TituloSeccion('Nuevo recuerdo'),
          _OpcionCrear(
            icono: Icons.videocam_outlined,
            titulo: 'Video',
            subtitulo: 'Graba un recuerdo en video (hasta 60 s)',
            alTocar: () => _nuevoRecuerdo(context, TipoElemento.video),
          ),
          _OpcionCrear(
            icono: Icons.mic_none_outlined,
            titulo: 'Audio',
            subtitulo: 'Deja un mensaje de voz (hasta 5 min)',
            alTocar: () => _nuevoRecuerdo(context, TipoElemento.audio),
          ),
          _OpcionCrear(
            icono: Icons.edit_outlined,
            titulo: 'Escribir',
            subtitulo: 'Escribe una nota o carta',
            alTocar: () => _nuevoRecuerdo(context, TipoElemento.texto),
          ),
          _OpcionCrear(
            icono: Icons.photo_outlined,
            titulo: 'Foto',
            subtitulo: 'Guarda una imagen especial',
            alTocar: () => _nuevoRecuerdo(context, TipoElemento.foto),
          ),
        ],
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(
          texto,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: ColoresApp.primario,
          ),
        ),
      );
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
