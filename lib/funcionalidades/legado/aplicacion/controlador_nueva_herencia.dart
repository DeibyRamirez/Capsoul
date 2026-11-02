import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/formato/valor_monetario.dart';
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
    this.condicion = CondicionHerencia.fecha,
    this.fechaActivacion,
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
    );
  }
}

class ControladorNuevaHerencia extends Notifier<BorradorNuevaHerencia> {
  @override
  BorradorNuevaHerencia build() => const BorradorNuevaHerencia();

  void actualizar(BorradorNuevaHerencia borrador) => state = borrador;

  Future<void> validarPasoActual() async {
    final b = state;
    switch (b.paso) {
      case 0:
        if (b.descripcion.trim().isEmpty) throw FalloLegado.campoObligatorio;
      case 1:
        final id = b.beneficiarioUsuarioId?.trim();
        if (id == null || id.isEmpty) throw FalloLegado.beneficiarioRequerido;
      case 2:
        if (b.mensajePersonal.trim().isEmpty) throw FalloLegado.campoObligatorio;
      case 3:
        if (b.tipoActivo.trim().isEmpty ||
            b.titular.trim().isEmpty ||
            b.instrucciones.trim().isEmpty) {
          throw FalloLegado.campoObligatorio;
        }
        final valor = parsearEnteroMiles(b.valorAproximado);
        if (valor == null || valor <= 0) throw FalloLegado.valorInvalido;
      case 4:
        await validarCondicionActivacion();
    }
  }

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
        throw FalloLegado.condicionCoherente;
      case CondicionHerencia.confirmacionConfianza:
        final confianzaId =
            await ref.read(proveedorRepositorioLegado).leerPersonaConfianzaId();
        if (confianzaId == null || confianzaId.trim().isEmpty) {
          throw FalloLegado.personaConfianzaRequerida;
        }
        final benef = b.beneficiarioUsuarioId?.trim();
        if (benef != null && benef == confianzaId) {
          throw const FalloLegado(
            FalloLegado.codigoCondicionCoherente,
            'La persona de confianza no puede ser quien recibe la herencia.',
          );
        }
    }
  }

  Future<String?> guardarYActivar() async {
    final b = state;
    if (b.descripcion.trim().isEmpty ||
        b.mensajePersonal.trim().isEmpty ||
        b.tipoActivo.trim().isEmpty ||
        b.titular.trim().isEmpty ||
        b.instrucciones.trim().isEmpty) {
      throw FalloLegado.campoObligatorio;
    }
    final beneficiario = b.beneficiarioUsuarioId?.trim();
    if (beneficiario == null || beneficiario.isEmpty) {
      throw FalloLegado.beneficiarioRequerido;
    }
    await validarCondicionActivacion();
    final valor = parsearEnteroMiles(b.valorAproximado);
    if (valor == null || valor <= 0) throw FalloLegado.valorInvalido;
    final titulo = b.tipoActivo.trim();
    final repo = ref.read(proveedorRepositorioLegado);
    final id = await repo.crearHerencia(
      titulo: titulo.length > 120 ? titulo.substring(0, 120) : titulo,
      descripcion: b.descripcion.trim(),
      beneficiarioUsuarioId: beneficiario,
      condicion: b.condicion,
      fechaActivacion:
          b.condicion == CondicionHerencia.fecha ? b.fechaActivacion : null,
      metadatos: MetadatosHerencia(
        tipoActivo: b.tipoActivo.trim(),
        titular: b.titular.trim(),
        valorAproximado: valor,
        instrucciones: b.instrucciones.trim(),
        mensajePersonal: b.mensajePersonal.trim(),
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
    ref.invalidate(proveedorHerenciasRecibidas);
    return id;
  }
}

final proveedorControladorNuevaHerencia =
    NotifierProvider.autoDispose<ControladorNuevaHerencia, BorradorNuevaHerencia>(
  ControladorNuevaHerencia.new,
);
