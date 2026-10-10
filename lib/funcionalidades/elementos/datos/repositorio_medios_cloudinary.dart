import 'package:flutter/foundation.dart';

import '../dominio/elemento_borrador.dart';
import '../dominio/fallo_medios.dart';
import '../dominio/medio_subido.dart';
import '../dominio/repositorio_medios.dart';
import '../../../nucleo/infraestructura/cliente_almacenamiento.dart';
import '../../../nucleo/infraestructura/cliente_funciones_api.dart';

/// [RepositorioMedios] con subida firmada directa a Cloudinary.
class RepositorioMediosCloudinary implements RepositorioMedios {
  RepositorioMediosCloudinary({
    required ClienteFuncionesApi funciones,
    required ClienteAlmacenamiento almacenamiento,
  })  : _funciones = funciones,
        _almacenamiento = almacenamiento;

  final ClienteFuncionesApi _funciones;
  final ClienteAlmacenamiento _almacenamiento;

  @override
  Future<MedioSubido> subir(ElementoBorrador elemento) async {
    final ruta = elemento.rutaArchivo;
    if (!elemento.tipo.esMedio || ruta == null) {
      throw const FalloMedios.subidaFallida();
    }
    try {
      final firma = await _funciones.firmarSubida(
        tipo: elemento.tipo,
        bytes: elemento.bytes,
        duracion: elemento.duracion,
        formato: elemento.formato,
      );
      return _almacenamiento.subirArchivo(
        rutaLocal: ruta,
        urlSubida: firma.urlSubida,
        parametrosFirma: firma.parametros,
      );
    } on ErrorFuncionesApi catch (error) {
      throw traducirErrorFuncion(error);
    }
  }

  @visibleForTesting
  static FalloMedios traducirErrorFuncion(ErrorFuncionesApi error) {
    final detalles = error.detalles;
    final codigo = detalles is Map ? detalles['codigo'] : null;
    if (codigo == 'cuota_excedida') return const FalloMedios.cuotaExcedida();
    if (detalles is Map && detalles['mensaje'] is String && error.estado == 422) {
      return FalloMedios(
        codigo is String ? codigo : FalloMedios.codigoSubidaFallida,
        detalles['mensaje'] as String,
      );
    }
    return switch (error.estado) {
      404 => const FalloMedios.subidaNoDisponible(),
      _ => const FalloMedios.subidaFallida(),
    };
  }
}
