import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../aplicacion/controladores_autenticacion.dart';
import 'componentes/campo_texto_autenticacion.dart';
import 'componentes/encabezado_autenticacion.dart';
import 'componentes/estructura_autenticacion.dart';
import 'validadores_autenticacion.dart';

class PantallaRegistro extends ConsumerStatefulWidget {
  const PantallaRegistro({super.key});

  @override
  ConsumerState<PantallaRegistro> createState() => _EstadoPantallaRegistro();
}

class _EstadoPantallaRegistro extends ConsumerState<PantallaRegistro> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  final _controladorConfirmacion = TextEditingController();

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    _controladorConfirmacion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;
    // Si todo sale bien, el enrutador redirige solo al contenedor principal.
    await ref.read(proveedorControladorRegistro.notifier).registrarUsuario(
          nombre: _controladorNombre.text,
          correo: _controladorCorreo.text,
          contrasena: _controladorContrasena.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(proveedorControladorRegistro, (_, siguiente) {
      if (siguiente is AsyncError) mostrarAvisoError(context, siguiente.error);
    });
    final cargando = ref.watch(proveedorControladorRegistro).isLoading;

    return EstructuraAutenticacion(
      mostrarAtras: true,
      contenido: AutofillGroup(
        child: Form(
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EncabezadoAutenticacion(
                subtitulo: 'Crea tu cuenta y empieza a guardar tu legado.',
              ),
              const SizedBox(height: 32),
              CampoTextoAutenticacion(
                controlador: _controladorNombre,
                etiqueta: 'Nombre',
                icono: Icons.person_outline,
                tipoTeclado: TextInputType.name,
                capitalizacion: TextCapitalization.words,
                pistasAutocompletado: const [AutofillHints.name],
                validador: ValidadoresAutenticacion.nombreVisible,
                habilitado: !cargando,
              ),
              const SizedBox(height: 16),
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
                alEnviar: (_) => _enviar(),
              ),
              const SizedBox(height: 24),
              BotonPrincipal(
                etiqueta: 'Crear cuenta',
                cargando: cargando,
                alPresionar: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
