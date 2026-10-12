import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/dominio/validador_nombre_usuario.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../autenticacion/aplicacion/proveedores_autenticacion.dart';
import '../../perfil/aplicacion/controlador_perfil.dart';
import '../aplicacion/proveedores_usuarios.dart';
import '../dominio/fallo_perfil_usuario.dart';
import '../dominio/repositorio_usuarios.dart';

/// Obligatoria cuando la fila `usuarios` no tiene `nombre_usuario`.
class PantallaElegirNombreUsuario extends ConsumerStatefulWidget {
  const PantallaElegirNombreUsuario({super.key});

  @override
  ConsumerState<PantallaElegirNombreUsuario> createState() =>
      _EstadoPantallaElegirNombreUsuario();
}

class _EstadoPantallaElegirNombreUsuario extends ConsumerState<PantallaElegirNombreUsuario> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controlador = TextEditingController();
  var _guardando = false;

  static const _esperaPerfil = Duration(seconds: 5);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;
    final uid = ref.read(proveedorRepositorioAutenticacion).usuarioActual?.uid;
    if (uid == null) return;
    setState(() => _guardando = true);
    try {
      final nombre = ValidadorNombreUsuario.normalizar(_controlador.text);
      final usuarios = ref.read(proveedorRepositorioUsuarios);
      await usuarios.establecerNombreUsuario(
        uid: uid,
        nombreUsuario: nombre,
      );
      await _esperarPerfilConArroba(usuarios, uid);
      if (!mounted) return;
      context.go(RutasApp.inicio);
    } catch (error) {
      if (!mounted) return;
      if (await _recuperarSiArrobaYaFijado(uid, error)) return;
      if (!mounted) return;
      mostrarAvisoError(context, error);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _esperarPerfilConArroba(
    RepositorioUsuarios usuarios,
    String uid,
  ) async {
    try {
      await usuarios
          .observarPerfil(uid)
          .firstWhere((p) => p != null && !p.necesitaNombreUsuario)
          .timeout(_esperaPerfil);
    } on TimeoutException {
      await usuarios
          .observarPerfil(uid)
          .firstWhere((p) => p != null && !p.necesitaNombreUsuario)
          .timeout(_esperaPerfil);
    }
  }

  Future<bool> _recuperarSiArrobaYaFijado(String? uid, Object error) async {
    if (uid == null) return false;
    final esYaFijado = error is FalloPerfilUsuario &&
        error.codigo == FalloPerfilUsuario.codigoNombreUsuarioYaFijado;
    if (!esYaFijado) return false;
    final perfil = ref.read(proveedorPerfilUsuarioActual).value;
    if (perfil != null && !perfil.necesitaNombreUsuario) {
      if (!mounted) return false;
      context.go(RutasApp.inicio);
      return true;
    }
    final leido = await ref
        .read(proveedorRepositorioUsuarios)
        .observarPerfil(uid)
        .first;
    if (leido != null && !leido.necesitaNombreUsuario) {
      if (!mounted) return false;
      context.go(RutasApp.inicio);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PantallaCapsoul(
      appBar: AppBar(title: const Text('Tu usuario @')),
      cuerpo: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Así te encontrarán tus amigos en Capsoul. '
                'Solo letras minúsculas, números y guion bajo.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('campo-nombre-usuario'),
                controller: _controlador,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixText: '@',
                ),
                autocorrect: false,
                textInputAction: TextInputAction.done,
                validator: ValidadorNombreUsuario.validar,
                onFieldSubmitted: (_) {
                  if (!_guardando) _guardar();
                },
              ),
              const SizedBox(height: 24),
              BotonPrincipal(
                key: const Key('boton-guardar-usuario'),
                etiqueta: 'Continuar',
                cargando: _guardando,
                alPresionar: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
