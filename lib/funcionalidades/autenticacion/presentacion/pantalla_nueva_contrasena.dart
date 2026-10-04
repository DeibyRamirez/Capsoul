import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../aplicacion/controladores_autenticacion.dart';
import 'componentes/campo_texto_autenticacion.dart';
import 'componentes/encabezado_autenticacion.dart';
import 'componentes/estructura_autenticacion.dart';
import 'validadores_autenticacion.dart';

const String kMensajeContrasenaActualizada = 'Tu contraseña se actualizó.';

/// Se abre al tocar el enlace de recuperación (evento `passwordRecovery`).
/// Hay una sesión temporal; al guardar, el enrutador lleva al contenedor.
class PantallaNuevaContrasena extends ConsumerStatefulWidget {
  const PantallaNuevaContrasena({super.key});

  @override
  ConsumerState<PantallaNuevaContrasena> createState() =>
      _EstadoPantallaNuevaContrasena();
}

class _EstadoPantallaNuevaContrasena
    extends ConsumerState<PantallaNuevaContrasena> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorContrasena = TextEditingController();
  final _controladorConfirmacion = TextEditingController();

  @override
  void dispose() {
    _controladorContrasena.dispose();
    _controladorConfirmacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;
    final mensajero = ScaffoldMessenger.of(context);
    final guardada = await ref
        .read(proveedorControladorNuevaContrasena.notifier)
        .guardar(_controladorContrasena.text);
    if (guardada) {
      mensajero
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(kMensajeContrasenaActualizada)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(proveedorControladorNuevaContrasena,
        (_, siguiente) {
      if (siguiente is AsyncError) mostrarAvisoError(context, siguiente.error);
    });
    final cargando = ref.watch(proveedorControladorNuevaContrasena).isLoading;

    return EstructuraAutenticacion(
      contenido: Form(
        key: _claveFormulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoAutenticacion(
              subtitulo: 'Escribe tu nueva contraseña.',
            ),
            const SizedBox(height: 32),
            CampoTextoAutenticacion(
              controlador: _controladorContrasena,
              etiqueta: 'Nueva contraseña',
              icono: Icons.lock_outline,
              esContrasena: true,
              pistasAutocompletado: const [AutofillHints.newPassword],
              validador: ValidadoresAutenticacion.contrasenaNueva,
              habilitado: !cargando,
            ),
            const SizedBox(height: 16),
            CampoTextoAutenticacion(
              controlador: _controladorConfirmacion,
              etiqueta: 'Confirmar contraseña',
              icono: Icons.lock_outline,
              esContrasena: true,
              accionTeclado: TextInputAction.done,
              validador: (valor) => ValidadoresAutenticacion.confirmarContrasena(
                valor,
                _controladorContrasena.text,
              ),
              habilitado: !cargando,
              alEnviar: (_) => _guardar(),
            ),
            const SizedBox(height: 24),
            BotonPrincipal(
              etiqueta: 'Guardar contraseña',
              cargando: cargando,
              alPresionar: _guardar,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: cargando
                  ? null
                  : () => ref
                      .read(proveedorControladorNuevaContrasena.notifier)
                      .cancelar(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
