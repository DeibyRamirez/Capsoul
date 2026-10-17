import 'package:flutter/foundation.dart';

@immutable
class GrupoLegadoBeneficiario {
  const GrupoLegadoBeneficiario({
    this.beneficiarioUsuarioId,
    this.beneficiarioCorreo,
    this.nombreVisible,
    this.fotoPublicId,
    required this.nHerencias,
    required this.nCapsulas,
  });

  final String? beneficiarioUsuarioId;
  final String? beneficiarioCorreo;
  final String? nombreVisible;
  final String? fotoPublicId;
  final int nHerencias;
  final int nCapsulas;

  String etiquetaPara() {
    final nombre = nombreVisible?.trim();
    if (nombre != null && nombre.isNotEmpty) return 'Para $nombre';
    final correo = beneficiarioCorreo?.trim();
    if (correo != null && correo.isNotEmpty) return 'Para $correo';
    return 'Para alguien especial';
  }

  factory GrupoLegadoBeneficiario.desdeFila(Map<String, dynamic> fila) {
    return GrupoLegadoBeneficiario(
      beneficiarioUsuarioId: fila['beneficiario_usuario_id'] as String?,
      beneficiarioCorreo: fila['beneficiario_correo'] as String?,
      nombreVisible: fila['nombre_visible'] as String?,
      fotoPublicId: fila['foto_public_id'] as String?,
      nHerencias: fila['n_herencias'] as int? ?? 0,
      nCapsulas: fila['n_capsulas'] as int? ?? 0,
    );
  }
}

@immutable
class ResumenLegado {
  const ResumenLegado({
    required this.herenciasActivas,
    required this.tieneInstrucciones,
    this.personaConfianzaId,
  });

  final int herenciasActivas;
  final bool tieneInstrucciones;
  final String? personaConfianzaId;

  factory ResumenLegado.desdeJson(Map<String, dynamic>? json) {
    if (json == null) return const ResumenLegado(herenciasActivas: 0, tieneInstrucciones: false);
    return ResumenLegado(
      herenciasActivas: json['herencias_activas'] as int? ?? 0,
      tieneInstrucciones: json['tiene_instrucciones'] as bool? ?? false,
      personaConfianzaId: json['persona_confianza_id'] as String?,
    );
  }
}
