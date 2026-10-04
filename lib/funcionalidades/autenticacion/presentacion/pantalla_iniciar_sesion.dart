import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/controladores_autenticacion.dart';
import '../dominio/fallo_autenticacion.dart';
import 'componentes/campo_texto_autenticacion.dart';
import 'componentes/encabezado_autenticacion.dart';
import 'componentes/estructura_autenticacion.dart';
import 'validadores_autenticacion.dart';

class PantallaIniciarSesion extends ConsumerStatefulWidget {
  const PantallaIniciarSesion({super.key});

  @override
  ConsumerState<PantallaIniciarSesion> createState() =>
      _EstadoPantallaIniciarSesion();
}

class _EstadoPantallaIniciarSesion
    extends ConsumerState<PantallaIniciarSesion> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();

  /// Correo de una cuenta sin confirmar tras un intento de inicio de sesión.
  String? _correoSinConfirmar;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;
    setState(() => _correoSinConfirmar = null);
    // Si todo sale bien, el enrutador redirige solo al contenedor principal.
    await ref.read(proveedorControladorInicioSesion.notifier).iniciarSesion(
          correo: _controladorCorreo.text,
          contrasena: _controladorContrasena.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(proveedorControladorInicioSesion, (_, siguiente) {
      if (siguiente is! AsyncError) return;
      mostrarAvisoError(context, siguiente.error);
      final error = siguiente.error;
      if (error is FalloAutenticacion && error.esCorreoNoConfirmado) {
        setState(() => _correoSinConfirmar = _controladorCorreo.text.trim());
      }
    });
    final correoSinConfirmar = _correoSinConfirmar;
    final cargando = ref.watch(proveedorControladorInicioSesion).isLoading;

    return EstructuraAutenticacion(
      contenido: AutofillGroup(
        child: Form(
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EncabezadoAutenticacion(),
              const SizedBox(height: 32),
              CampoTextoAutenticacion(
                controlador: _controladorCorreo,
                etiqueta: 'Correo electrónico',
                icono: Icons.mail_outline,
                tipoTeclado: TextInputType.emailAddress,
                pistasAutocompletado: const [AutofillHints.email],
                validador: ValidadoresAutenticacion.correo,
                habilitado: !cargando,
              ),
              const SizedBox(height: 16),
              CampoTextoAutenticacion(
                controlador: _controladorContrasena,
                etiqueta: 'Contraseña',
                icono: Icons.lock_outline,
                esContrasena: true,
                accionTeclado: TextInputAction.done,
                pistasAutocompletado: const [AutofillHints.password],
                validador: ValidadoresAutenticacion.contrasenaInicioSesion,
                habilitado: !cargando,
                alEnviar: (_) => _enviar(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: cargando
                      ? null
                      : () => context.push(RutasApp.recuperar),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: 8),
              BotonPrincipal(
                etiqueta: 'Iniciar sesión',
                cargando: cargando,
                alPresionar: _enviar,
              ),
              if (correoSinConfirmar != null) ...[
                const SizedBox(height: 16),
                _AvisoCorreoSinConfirmar(
                  alReenviar: () => context.push(
                    RutasApp.revisaTuCorreoPara(
                      correoSinConfirmar,
                      reenviar: true,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    '¿No tienes cuenta?',
                    style: TextStyle(color: ColoresApp.atenuado),
                  ),
                  TextButton(
                    onPressed: cargando
                        ? null
                        : () => context.push(RutasApp.registro),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso bajo el formulario cuando la cuenta existe pero no confirmó el
/// correo, con la opción de reenviar la confirmación.
class _AvisoCorreoSinConfirmar extends StatelessWidget {
  const _AvisoCorreoSinConfirmar({required this.alReenviar});

  final VoidCallback alReenviar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.acento.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresApp.acento.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tu correo aún no está confirmado. Abre el enlace que te enviamos '
            'o pide uno nuevo.',
            style: TextStyle(color: ColoresApp.sobreSuperficie),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: alReenviar,
            icon: const Icon(Icons.forward_to_inbox_outlined),
            label: const Text('Reenviar correo de confirmación'),
          ),
        ],
      ),
    );
  }
}
