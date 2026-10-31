import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/fallo_musica.dart';
import 'estado_busqueda_musica.dart';
import 'proveedores_musica.dart';

/// Búsqueda con debounce. Cada búsqueda lleva un número; si llega la
/// respuesta de una búsqueda vieja, se ignora.
class ControladorBusquedaMusica extends Notifier<EstadoBusquedaMusica> {
  Timer? _espera;
  int _peticion = 0;

  @override
  EstadoBusquedaMusica build() {
    ref.onDispose(() => _espera?.cancel());
    return const EstadoBusquedaMusica();
  }

  /// Llamar en cada cambio del campo de texto.
  void cambiarConsulta(String texto) {
    _espera?.cancel();
    final consulta = texto.trim();
    if (consulta.length < EstadoBusquedaMusica.largoMinimo) {
      _peticion++; // invalida cualquier respuesta pendiente
      state = EstadoBusquedaMusica(consulta: consulta);
      return;
    }
    if (consulta == state.consulta && state.consultaBuscada == consulta) {
      return;
    }
    state = state.copiarCon(consulta: consulta);
    _espera = Timer(ref.read(proveedorEsperaBusquedaMusica), buscarAhora);
  }

  /// Busca sin esperar (al enviar el teclado o reintentar).
  Future<void> buscarAhora() async {
    _espera?.cancel();
    final consulta = state.consulta;
    if (consulta.length < EstadoBusquedaMusica.largoMinimo) return;
    final numero = ++_peticion;
    state = state.copiarCon(cargando: true, quitarError: true);
    try {
      final resultados = await ref
          .read(proveedorRepositorioCatalogoMusica)
          .buscar(consulta);
      if (!ref.mounted || numero != _peticion) return;
      state = EstadoBusquedaMusica(
        consulta: consulta,
        resultados: resultados,
        consultaBuscada: consulta,
      );
    } on FalloMusica catch (fallo) {
      if (!ref.mounted || numero != _peticion) return;
      state = state.copiarCon(cargando: false, error: fallo.mensaje);
    } catch (_) {
      if (!ref.mounted || numero != _peticion) return;
      state = state.copiarCon(
        cargando: false,
        error: 'No se pudo buscar. Intenta de nuevo.',
      );
    }
  }
}

final proveedorControladorBusquedaMusica = NotifierProvider.autoDispose<
    ControladorBusquedaMusica, EstadoBusquedaMusica>(
  ControladorBusquedaMusica.new,
);
