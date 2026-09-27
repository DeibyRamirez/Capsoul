import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/controladores_autenticacion.dart';
import 'componentes/campo_texto_autenticacion.dart';
import 'componentes/encabezado_autenticacion.dart';
import 'componentes/estructura_autenticacion.dart';
import 'validadores_autenticacion.dart';

/// Confirmación neutra: nunca revela si la cuenta existe.
const String kMensajeEnlaceRecuperacionEnviado =
    'Si existe una cuenta con ese correo, te enviamos un enlace para '
    'restablecer tu contraseña. Revisa también la carpeta de spam.';

class PantallaRecuperarContrasena extends ConsumerStatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  ConsumerState<PantallaRecuperarContrasena> createState() =>
      _EstadoPantallaRecuperarContrasena();
}

class _EstadoPantallaRecuperarContrasena
    extends ConsumerState<PantallaRecuperarContrasena> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  bool _enviado = false;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;
    final enviado = await ref
        .read(proveedorControladorRecuperacion.notifier)
        .enviarEnlaceRecuperacion(_controladorCorreo.text);
    if (enviado && mounted) setState(() => _enviado = true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(proveedorControladorRecuperacion, (_, siguiente) {
      if (siguiente is AsyncError) mostrarAvisoError(context, siguiente.error);
    });
    final cargando = ref.watch(proveedorControladorRecuperacion).isLoading;

    return EstructuraAutenticacion(
      mostrarAtras: true,
      contenido: _enviado
          ? const _EnlaceRecuperacionEnviado()
          : _construirFormulario(cargando),
    );
  }

  Widget _construirFormulario(bool cargando) {
    return Form(
      key: _claveFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoAutenticacion(
            subtitulo: 'Escribe el correo de tu cuenta y te enviaremos un '
                'enlace para restablecer tu contraseña.',
          ),
          const SizedBox(height: 32),
          CampoTextoAutenticacion(
            controlador: _controladorCorreo,
            etiqueta: 'Correo electrónico',
            icono: Icons.mail_outline,
            tipoTeclado: TextInputType.emailAddress,
            accionTeclado: TextInputAction.done,
            pistasAutocompletado: const [AutofillHints.email],
            validador: ValidadoresAutenticacion.correo,
            habilitado: !cargando,
            alEnviar: (_) => _enviar(),
          ),
          const SizedBox(height: 24),
          BotonPrincipal(
            etiqueta: 'Enviar enlace',
            cargando: cargando,
            alPresionar: _enviar,
          ),
        ],
      ),
    );
  }
}

class _EnlaceRecuperacionEnviado extends StatelessWidget {
  const _EnlaceRecuperacionEnviado();

  @override
  Widget build(BuildContext context) {
    final estilosTexto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: ColoresApp.acento,
        ),
        const SizedBox(height: 16),
        Text(
          'Revisa tu correo',
          textAlign: TextAlign.center,
          style: estilosTexto.headlineSmall?.copyWith(
            color: ColoresApp.primario,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          kMensajeEnlaceRecuperacionEnviado,
          textAlign: TextAlign.center,
          style: estilosTexto.bodyLarge?.copyWith(color: ColoresApp.atenuado),
        ),
        const SizedBox(height: 32),
        BotonPrincipal(
          etiqueta: 'Volver a iniciar sesión',
          alPresionar: () => context.go(RutasApp.iniciarSesion),
        ),
      ],
    );
  }
}
