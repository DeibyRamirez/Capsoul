import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../autenticacion/presentacion/validadores_autenticacion.dart';
import '../aplicacion/controlador_perfil.dart';

/// Pestaña "Yo": perfil de la tabla `usuarios`, edición del nombre visible y
/// cierre de sesión. No hay aviso de verificación: para tener sesión el
/// correo ya debe estar confirmado.
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
