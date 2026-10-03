import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/controladores_autenticacion.dart';
import 'componentes/estructura_autenticacion.dart';

/// Espera entre reenvíos (Supabase limita el envío de correos).
const Duration kEnfriamientoReenvio = Duration(seconds: 60);

const String kMensajeCorreoReenviado =
    'Te enviamos un nuevo correo de confirmación. Revisa también la carpeta '
    'de spam.';

/// "Revisa tu correo": la cuenta existe pero falta confirmar el correo.
/// Permite reenviar la confirmación (con enfriamiento) y volver a iniciar
/// sesión. Al abrir el enlace, el deep link abre la sesión y el enrutador
/// lleva al contenedor principal.
class PantallaRevisaTuCorreo extends ConsumerStatefulWidget {
  const PantallaRevisaTuCorreo({
    super.key,
    required this.correo,
    this.reenviarAlEntrar = false,
  });

  final String correo;

  /// `true` cuando se llega desde el inicio de sesión de una cuenta sin
  /// confirmar: se reenvía el correo al abrir la pantalla.
  final bool reenviarAlEntrar;

  @override
  ConsumerState<PantallaRevisaTuCorreo> createState() =>
      _EstadoPantallaRevisaTuCorreo();
}

class _EstadoPantallaRevisaTuCorreo
    extends ConsumerState<PantallaRevisaTuCorreo> {
  Timer? _temporizador;
  int _segundosRestantes = 0;

  @override
  void initState() {
    super.initState();
    if (widget.reenviarAlEntrar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reenviar();
      });
    } else {
      // El registro acaba de enviar un correo: se espera antes de reenviar.
      _iniciarEnfriamiento();
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _iniciarEnfriamiento() {
    _temporizador?.cancel();
    _segundosRestantes = kEnfriamientoReenvio.inSeconds;
    _temporizador = Timer.periodic(const Duration(seconds: 1), (temporizador) {
      if (!mounted) return;
      setState(() {
        _segundosRestantes--;
        if (_segundosRestantes <= 0) {
          _segundosRestantes = 0;
          temporizador.cancel();
        }
      });
    });
  }

  Future<void> _reenviar() async {
    final enviado = await ref
        .read(proveedorControladorReenvioConfirmacion.notifier)
        .reenviar(widget.correo);
    if (!enviado || !mounted) return;
    mostrarAvisoInformativo(context, kMensajeCorreoReenviado);
    setState(_iniciarEnfriamiento);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(proveedorControladorReenvioConfirmacion,
        (_, siguiente) {
      if (siguiente is AsyncError) mostrarAvisoError(context, siguiente.error);
    });
    final cargando = ref.watch(proveedorControladorReenvioConfirmacion).isLoading;
    final enEnfriamiento = _segundosRestantes > 0;
    final puedeReenviar = widget.correo.isNotEmpty && !enEnfriamiento;
    final estilosTexto = Theme.of(context).textTheme;

    return EstructuraAutenticacion(
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 72,
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
          const Text(
            'Te enviamos un enlace para confirmar tu cuenta a:',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresApp.sobreSuperficie),
          ),
          const SizedBox(height: 4),
          Text(
            widget.correo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: ColoresApp.primario,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ábrelo desde este teléfono para entrar a Capsoul. Si no lo ves, '
            'revisa la carpeta de spam.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresApp.atenuado),
          ),
          const SizedBox(height: 32),
          BotonPrincipal(
            etiqueta: enEnfriamiento
                ? 'Reenviar en $_segundosRestantes s'
                : 'Reenviar correo',
            cargando: cargando,
            alPresionar: puedeReenviar ? _reenviar : null,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: cargando ? null : () => context.go(RutasApp.iniciarSesion),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text('Volver a iniciar sesión'),
          ),
        ],
      ),
    );
  }
}
