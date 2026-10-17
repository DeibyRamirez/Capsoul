import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/condicion_herencia.dart';
import '../dominio/fallo_legado.dart';
import '../dominio/metadatos_herencia.dart';
import 'proveedores_legado.dart';

class BorradorNuevaHerencia {
  const BorradorNuevaHerencia({
    this.paso = 0,
    this.descripcion = '',
    this.elementoIds = const [],
    this.capsulaIds = const [],
    this.beneficiarioUsuarioId,
    this.mensajePersonal = '',
    this.tipoActivo = '',
    this.titular = '',
    this.valorAproximado = '',
    this.instrucciones = '',
    this.condicion = CondicionHerencia.confirmacionConfianza,
    this.fechaActivacion,
    this.diasInactividad = 180,
  });

  final int paso;
  final String descripcion;
  final List<String> elementoIds;
  final List<String> capsulaIds;
  final String? beneficiarioUsuarioId;
  final String mensajePersonal;
  final String tipoActivo;
  final String titular;
  final String valorAproximado;
  final String instrucciones;
  final CondicionHerencia condicion;
  final DateTime? fechaActivacion;
  final int diasInactividad;

  static const int totalPasos = 6;

  BorradorNuevaHerencia copiar({
    int? paso,
    String? descripcion,
    List<String>? elementoIds,
    List<String>? capsulaIds,
    String? beneficiarioUsuarioId,
    String? mensajePersonal,
    String? tipoActivo,
    String? titular,
    String? valorAproximado,
    String? instrucciones,
    CondicionHerencia? condicion,
    DateTime? fechaActivacion,
    int? diasInactividad,
  }) {
    return BorradorNuevaHerencia(
      paso: paso ?? this.paso,
      descripcion: descripcion ?? this.descripcion,
      elementoIds: elementoIds ?? this.elementoIds,
      capsulaIds: capsulaIds ?? this.capsulaIds,
      beneficiarioUsuarioId: beneficiarioUsuarioId ?? this.beneficiarioUsuarioId,
      mensajePersonal: mensajePersonal ?? this.mensajePersonal,
      tipoActivo: tipoActivo ?? this.tipoActivo,
      titular: titular ?? this.titular,
      valorAproximado: valorAproximado ?? this.valorAproximado,
      instrucciones: instrucciones ?? this.instrucciones,
      condicion: condicion ?? this.condicion,
      fechaActivacion: fechaActivacion ?? this.fechaActivacion,
      diasInactividad: diasInactividad ?? this.diasInactividad,
    );
  }
}

class ControladorNuevaHerencia extends Notifier<BorradorNuevaHerencia> {
  @override
  BorradorNuevaHerencia build() => const BorradorNuevaHerencia();

  void actualizar(BorradorNuevaHerencia borrador) => state = borrador;

  /// Valida la condición de activación antes de guardar o avanzar del paso 4.
  Future<void> validarCondicionActivacion() async {
    final b = state;
    switch (b.condicion) {
      case CondicionHerencia.fecha:
        final fecha = b.fechaActivacion;
        if (fecha == null) throw FalloLegado.fechaRequerida;
        final hoy = DateTime.now();
        final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
        final diaElegido = DateTime(fecha.year, fecha.month, fecha.day);
        if (!diaElegido.isAfter(inicioHoy)) {
          throw FalloLegado.fechaDebeSerFutura;
        }
      case CondicionHerencia.inactividad:
        if (b.diasInactividad <= 0) throw FalloLegado.inactividadRequerida;
      case CondicionHerencia.confirmacionConfianza:
        final confianzaId =
            await ref.read(proveedorRepositorioLegado).leerPersonaConfianzaId();
        if (confianzaId == null || confianzaId.trim().isEmpty) {
          throw FalloLegado.personaConfianzaRequerida;
        }
    }
  }

  Future<String?> guardarYActivar() async {
    final b = state;
    final beneficiario = b.beneficiarioUsuarioId?.trim();
    if (beneficiario == null || beneficiario.isEmpty) return null;
    await validarCondicionActivacion();
    final titulo = b.tipoActivo.trim().isNotEmpty
        ? b.tipoActivo.trim()
        : (b.descripcion.trim().isNotEmpty
            ? b.descripcion.trim().split('\n').first
            : 'Pequeña herencia');
    final repo = ref.read(proveedorRepositorioLegado);
    final id = await repo.crearHerencia(
      titulo: titulo.length > 120 ? titulo.substring(0, 120) : titulo,
      descripcion: b.descripcion.trim().isEmpty ? b.mensajePersonal : b.descripcion,
      beneficiarioUsuarioId: beneficiario,
      condicion: b.condicion,
      fechaActivacion: b.condicion == CondicionHerencia.fecha ? b.fechaActivacion : null,
      diasInactividad:
          b.condicion == CondicionHerencia.inactividad ? b.diasInactividad : null,
      metadatos: MetadatosHerencia(
        tipoActivo: b.tipoActivo,
        titular: b.titular,
        valorAproximado: b.valorAproximado,
        instrucciones: b.instrucciones,
        mensajePersonal: b.mensajePersonal,
      ),
      activar: true,
    );
    if (b.elementoIds.isNotEmpty) {
      await repo.vincularElementos(id, b.elementoIds);
    }
    for (final capsulaId in b.capsulaIds) {
      await repo.vincularCapsula(id, capsulaId);
    }
    ref.invalidate(proveedorResumenLegado);
    ref.invalidate(proveedorGruposLegadoBeneficiario);
    return id;
  }
}

final proveedorControladorNuevaHerencia =
    NotifierProvider.autoDispose<ControladorNuevaHerencia, BorradorNuevaHerencia>(
  ControladorNuevaHerencia.new,
);
