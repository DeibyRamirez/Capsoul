import 'dart:math' as math;

import 'fallo_medios.dart';
import 'limites_medios.dart';
import 'tipo_elemento.dart';

/// Reglas puras de [LimitesMedios] (sin plugins), probadas con pruebas
/// unitarias.
abstract final class ValidadorMedios {
  /// Devuelve el fallo si un medio de [tipo] con [bytes] y [duracion] no
  /// cumple los límites, o `null` si los cumple.
  static FalloMedios? validarMedio({
    required TipoElemento tipo,
    required int bytes,
    Duration? duracion,
  }) {
    final maximo = LimitesMedios.bytesMaximos(tipo);
    if (maximo != null && bytes > maximo) {
      return FalloMedios(
        FalloMedios.codigoExcedeTamano,
        '${_articulo(tipo)} pesa ${formatearBytes(bytes)} incluso después de '
        'comprimir${tipo == TipoElemento.foto ? 'la' : 'lo'} y el máximo es '
        '${formatearBytes(maximo)}. '
        '${tipo == TipoElemento.foto ? 'Prueba con otra foto.' : 'Graba uno más corto.'}',
      );
    }
    final duracionMaxima = LimitesMedios.duracionMaxima(tipo);
    if (duracionMaxima != null &&
        duracion != null &&
        duracion > duracionMaxima + LimitesMedios.toleranciaDuracion) {
      return FalloMedios(
        FalloMedios.codigoExcedeDuracion,
        '${_articulo(tipo)} dura ${formatearDuracion(duracion)} y el máximo es '
        '${formatearDuracion(duracionMaxima)}.',
      );
    }
    return null;
  }

  /// Valida el texto de una nota (no vacío y como máximo
  /// [LimitesMedios.caracteresMaxNota] caracteres).
  static FalloMedios? validarNota(String texto) {
    if (texto.trim().isEmpty) {
      return const FalloMedios(
        FalloMedios.codigoNotaVacia,
        'Escribe algo antes de guardar la nota.',
      );
    }
    if (contarCaracteres(texto) > LimitesMedios.caracteresMaxNota) {
      return const FalloMedios(
        FalloMedios.codigoNotaLarga,
        'La nota puede tener como máximo 5000 caracteres.',
      );
    }
    return null;
  }

  /// Tamaño final de una foto de [ancho] × [alto] para que su lado mayor no
  /// pase de [LimitesMedios.ladoMayorFotoPx]. Nunca agranda.
  static ({int ancho, int alto}) dimensionesObjetivoFoto(int ancho, int alto) {
    final ladoMayor = math.max(ancho, alto);
    if (ladoMayor <= LimitesMedios.ladoMayorFotoPx || ladoMayor <= 0) {
      return (ancho: ancho, alto: alto);
    }
    final escala = LimitesMedios.ladoMayorFotoPx / ladoMayor;
    return (
      ancho: math.max(1, (ancho * escala).floor()),
      alto: math.max(1, (alto * escala).floor()),
    );
  }

  static String _articulo(TipoElemento tipo) => switch (tipo) {
        TipoElemento.foto => 'La foto',
        TipoElemento.video => 'El video',
        TipoElemento.audio => 'El audio',
        TipoElemento.texto => 'La nota',
        TipoElemento.musica => 'La canción',
      };
}

/// "2 MB", "2,3 MB", "850 KB" (MB binarios, coma decimal).
String formatearBytes(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  if (bytes >= mb) {
    final valor = bytes / mb;
    final texto = valor == valor.truncateToDouble()
        ? valor.toStringAsFixed(0)
        : valor.toStringAsFixed(1);
    return '${texto.replaceAll('.', ',')} MB';
  }
  if (bytes >= kb) return '${(bytes / kb).round()} KB';
  return '$bytes B';
}

/// "mm:ss" (p. ej. "01:32"); con horas, "h:mm:ss".
String formatearDuracion(Duration duracion) {
  final horas = duracion.inHours;
  final minutos = duracion.inMinutes.remainder(60).toString().padLeft(2, '0');
  final segundos = duracion.inSeconds.remainder(60).toString().padLeft(2, '0');
  return horas > 0 ? '$horas:$minutos:$segundos' : '$minutos:$segundos';
}

/// Caracteres como los cuenta Postgres (`char_length`): puntos de código
/// Unicode.
int contarCaracteres(String texto) => texto.runes.length;
