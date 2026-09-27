import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';

/// Selector de modalidad que abre el botón `+` (Video, Audio, Escribir, Foto).
class PantallaSelectorCrear extends StatelessWidget {
  const PantallaSelectorCrear({super.key});

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
            icono: Icons.videocam_outlined,
            titulo: 'Video',
            subtitulo: 'Graba un recuerdo en video',
            alTocar: () => context.push(RutasApp.crearVideo),
          ),
          _OpcionCrear(
            icono: Icons.mic_none_outlined,
            titulo: 'Audio',
            subtitulo: 'Deja un mensaje de voz',
            alTocar: () => context.push(RutasApp.crearAudio),
          ),
          _OpcionCrear(
            icono: Icons.edit_outlined,
            titulo: 'Escribir',
            subtitulo: 'Escribe una nota o carta',
            alTocar: () => context.push(RutasApp.crearEscribir),
          ),
          _OpcionCrear(
            icono: Icons.photo_outlined,
            titulo: 'Foto',
            subtitulo: 'Guarda una imagen especial',
            alTocar: () => context.push(RutasApp.crearFoto),
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
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        ),
        leading: CircleAvatar(
          backgroundColor: ColoresApp.acento.withValues(alpha: 0.15),
          foregroundColor: ColoresApp.primario,
          child: Icon(icono),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: ColoresApp.sobreSuperficie,
          ),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right, color: ColoresApp.atenuado),
        onTap: alTocar,
      ),
    );
  }
}

/// Marcador de una modalidad de creación (Video / Audio / Escribir / Foto).
class PantallaMarcadorCrear extends StatelessWidget {
  const PantallaMarcadorCrear({super.key, required this.modalidad});

  final String modalidad;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(modalidad)),
      body: Center(
        child: Text(
          'Próximamente: $modalidad',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColoresApp.atenuado,
              ),
        ),
      ),
    );
  }
}
