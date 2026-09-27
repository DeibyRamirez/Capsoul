import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../autenticacion/presentacion/validadores_autenticacion.dart';
import '../aplicacion/controlador_perfil.dart';

/// Pestaña "Yo": perfil de `usuarios/{uid}`, edición del nombre visible,
/// aviso de correo sin verificar y cierre de sesión.
class PantallaPerfil extends ConsumerWidget {
  const PantallaPerfil({super.key});

  Future<void> _editarNombre(
    BuildContext context,
    WidgetRef ref,
    String nombreActual,
  ) async {
    final nombreNuevo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditarNombre(nombreInicial: nombreActual),
    );
    if (nombreNuevo == null || nombreNuevo.trim() == nombreActual) return;
    final guardado = await ref
        .read(proveedorControladorPerfil.notifier)
        .actualizarNombreVisible(nombreNuevo);
    if (guardado && context.mounted) {
      mostrarAvisoInformativo(context, 'Nombre actualizado');
    }
  }

  Future<void> _reenviarCorreo(BuildContext context, WidgetRef ref) async {
    final enviado = await ref
        .read(proveedorControladorPerfil.notifier)
        .reenviarCorreoVerificacion();
    if (enviado && context.mounted) {
      mostrarAvisoInformativo(
        context,
        'Te enviamos un nuevo correo de verificación',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(proveedorControladorPerfil, (_, siguiente) {
      if (siguiente is AsyncError) mostrarAvisoError(context, siguiente.error);
    });

    final usuarioSesion = ref.watch(proveedorEstadoAutenticacion).value;
    final perfilAsincrono = ref.watch(proveedorPerfilUsuarioActual);
    final perfil = perfilAsincrono.value;
    final ocupado = ref.watch(proveedorControladorPerfil).isLoading;

    final nombre =
        perfil?.nombreVisible ?? usuarioSesion?.nombreVisible ?? 'Sin nombre';
    final correo = perfil?.correo ?? usuarioSesion?.correo ?? '';
    final correoVerificado = usuarioSesion?.correoVerificado ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Yo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (perfilAsincrono.isLoading && perfil == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            _EncabezadoPerfil(nombre: nombre, correo: correo),
            if (perfilAsincrono.hasError)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'No pudimos cargar tu perfil. Mostramos los datos de tu cuenta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ColoresApp.atenuado),
                ),
              ),
            const SizedBox(height: 24),
            if (!correoVerificado) ...[
              _AvisoVerificacionCorreo(
                ocupado: ocupado,
                alReenviar: () => _reenviarCorreo(context, ref),
                alActualizar: () => ref
                    .read(proveedorControladorPerfil.notifier)
                    .actualizarVerificacionCorreo(),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              color: ColoresApp.sobrePrimario,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TemaApp.radioMediano),
                ),
                leading:
                    const Icon(Icons.edit_outlined, color: ColoresApp.acento),
                title: const Text('Editar nombre'),
                trailing:
                    const Icon(Icons.chevron_right, color: ColoresApp.atenuado),
                onTap: ocupado ? null : () => _editarNombre(context, ref, nombre),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: ocupado
                  ? null
                  : () => ref
                      .read(proveedorControladorPerfil.notifier)
                      .cerrarSesion(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoPerfil extends StatelessWidget {
  const _EncabezadoPerfil({required this.nombre, required this.correo});

  final String nombre;
  final String correo;

  @override
  Widget build(BuildContext context) {
    final estilosTexto = Theme.of(context).textTheme;
    final nombreLimpio = nombre.trim();
    final inicial =
        nombreLimpio.isEmpty ? '?' : nombreLimpio[0].toUpperCase();
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: ColoresApp.primario,
          foregroundColor: ColoresApp.sobrePrimario,
          child: Text(
            inicial,
            style: estilosTexto.headlineMedium?.copyWith(
              color: ColoresApp.sobrePrimario,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          nombre,
          textAlign: TextAlign.center,
          style: estilosTexto.titleLarge?.copyWith(
            color: ColoresApp.primario,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          correo,
          textAlign: TextAlign.center,
          style: estilosTexto.bodyMedium?.copyWith(color: ColoresApp.atenuado),
        ),
      ],
    );
  }
}

class _AvisoVerificacionCorreo extends StatelessWidget {
  const _AvisoVerificacionCorreo({
    required this.ocupado,
    required this.alReenviar,
    required this.alActualizar,
  });

  final bool ocupado;
  final VoidCallback alReenviar;
  final VoidCallback alActualizar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.acento.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        border: Border.all(color: ColoresApp.acento.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mark_email_unread_outlined, color: ColoresApp.acento),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verifica tu correo electrónico',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.primario,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Te enviamos un enlace de verificación. Puedes seguir usando '
            'Capsoul mientras tanto.',
            style: TextStyle(color: ColoresApp.sobreSuperficie),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: ocupado ? null : alReenviar,
                child: const Text('Reenviar correo'),
              ),
              TextButton(
                onPressed: ocupado ? null : alActualizar,
                child: const Text('Ya lo verifiqué'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogoEditarNombre extends StatefulWidget {
  const _DialogoEditarNombre({required this.nombreInicial});

  final String nombreInicial;

  @override
  State<_DialogoEditarNombre> createState() => _EstadoDialogoEditarNombre();
}

class _EstadoDialogoEditarNombre extends State<_DialogoEditarNombre> {
  final _claveFormulario = GlobalKey<FormState>();
  late final TextEditingController _controlador =
      TextEditingController(text: widget.nombreInicial);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controlador.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.radioGrande),
      ),
      title: const Text('Editar nombre'),
      content: Form(
        key: _claveFormulario,
        child: TextFormField(
          controller: _controlador,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: ValidadoresAutenticacion.nombreVisible,
          onFieldSubmitted: (_) => _guardar(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
