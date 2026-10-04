import 'package:capsoul/funcionalidades/elementos/dominio/fallo_medios.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/limites_medios.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/validador_medios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mb = 1024 * 1024;

  group('LimitesMedios', () {
    test('coinciden con los límites aprobados por el PO', () {
      expect(LimitesMedios.ladoMayorFotoPx, 1600);
      expect(LimitesMedios.calidadJpegFoto, 75);
      expect(LimitesMedios.bytesMaxFoto, 2 * mb);
      expect(LimitesMedios.altoVideoPx, 720);
      expect(LimitesMedios.duracionMaxVideo, const Duration(seconds: 60));
      expect(LimitesMedios.bitrateVideo, 2500000);
      expect(LimitesMedios.bytesMaxVideo, 20 * mb);
      expect(LimitesMedios.bitrateAudio, 64000);
      expect(LimitesMedios.canalesAudio, 1);
      expect(LimitesMedios.duracionMaxAudio, const Duration(minutes: 5));
      expect(LimitesMedios.caracteresMaxNota, 5000);
      expect(LimitesMedios.elementosMaxPorCapsula, 10);
      expect(LimitesMedios.cuotaBytesPorUsuario, 200 * mb);
    });

    test('60 s de video a 2,5 Mbps + 64 kbps de audio caben en 20 MB', () {
      const bytes = (LimitesMedios.bitrateVideo +
              LimitesMedios.bitrateAudioDeVideo) *
          60 ~/
          8;
      expect(bytes, lessThan(LimitesMedios.bytesMaxVideo));
    });

    test('5 min de audio a 64 kbps (~2,4 MB) caben en el tope de audio', () {
      const bytes = LimitesMedios.bitrateAudio * 300 ~/ 8;
      expect(bytes, 2400000);
      expect(bytes, lessThan(LimitesMedios.bytesMaxAudio));
    });

    test('las notas no tienen tope de bytes ni duración', () {
      expect(LimitesMedios.bytesMaximos(TipoElemento.texto), isNull);
      expect(LimitesMedios.duracionMaxima(TipoElemento.texto), isNull);
      expect(LimitesMedios.duracionMaxima(TipoElemento.foto), isNull);
    });
  });

  group('ValidadorMedios.validarMedio', () {
    test('acepta una foto de 2 MB exactos y rechaza una de más', () {
      expect(
        ValidadorMedios.validarMedio(tipo: TipoElemento.foto, bytes: 2 * mb),
        isNull,
      );
      final fallo = ValidadorMedios.validarMedio(
        tipo: TipoElemento.foto,
        bytes: 2 * mb + 1,
      );
      expect(fallo?.codigo, FalloMedios.codigoExcedeTamano);
      expect(fallo?.mensaje, contains('máximo es 2 MB'));
    });

    test('rechaza un video de más de 20 MB', () {
      final fallo = ValidadorMedios.validarMedio(
        tipo: TipoElemento.video,
        bytes: 21 * mb,
        duracion: const Duration(seconds: 30),
      );
      expect(fallo?.codigo, FalloMedios.codigoExcedeTamano);
      expect(fallo?.mensaje, contains('El video pesa 21 MB'));
    });

    test('tolera 1 s de holgura en la duración del video', () {
      expect(
        ValidadorMedios.validarMedio(
          tipo: TipoElemento.video,
          bytes: mb,
          duracion: const Duration(milliseconds: 60800),
        ),
        isNull,
      );
      expect(
        ValidadorMedios.validarMedio(
          tipo: TipoElemento.video,
          bytes: mb,
          duracion: const Duration(seconds: 62),
        )?.codigo,
        FalloMedios.codigoExcedeDuracion,
      );
    });

    test('rechaza audios de más de 5 minutos o más de 3 MB', () {
      expect(
        ValidadorMedios.validarMedio(
          tipo: TipoElemento.audio,
          bytes: mb,
          duracion: const Duration(minutes: 6),
        )?.mensaje,
        'El audio dura 06:00 y el máximo es 05:00.',
      );
      expect(
        ValidadorMedios.validarMedio(
          tipo: TipoElemento.audio,
          bytes: 3 * mb + 1,
          duracion: const Duration(minutes: 4),
        )?.codigo,
        FalloMedios.codigoExcedeTamano,
      );
    });
  });

  group('ValidadorMedios.validarNota', () {
    test('rechaza notas vacías o con solo espacios', () {
      expect(
        ValidadorMedios.validarNota('   ')?.codigo,
        FalloMedios.codigoNotaVacia,
      );
    });

    test('acepta 5000 caracteres y rechaza 5001', () {
      expect(ValidadorMedios.validarNota('a' * 5000), isNull);
      expect(
        ValidadorMedios.validarNota('a' * 5001)?.codigo,
        FalloMedios.codigoNotaLarga,
      );
    });

    test('cuenta caracteres como Postgres (puntos de código)', () {
      expect(contarCaracteres('ñandú'), 5);
      expect(contarCaracteres('🎁'), 1);
      expect(ValidadorMedios.validarNota('🎁' * 5000), isNull);
    });
  });

  group('ValidadorMedios.dimensionesObjetivoFoto', () {
    test('reduce el lado mayor a 1600 px manteniendo la proporción', () {
      expect(
        ValidadorMedios.dimensionesObjetivoFoto(4000, 3000),
        (ancho: 1600, alto: 1200),
      );
      expect(
        ValidadorMedios.dimensionesObjetivoFoto(3024, 4032),
        (ancho: 1200, alto: 1600),
      );
    });

    test('nunca agranda una foto pequeña', () {
      expect(
        ValidadorMedios.dimensionesObjetivoFoto(1280, 720),
        (ancho: 1280, alto: 720),
      );
    });
  });

  group('formatos', () {
    test('formatearBytes usa coma decimal y MB binarios', () {
      expect(formatearBytes(2 * mb), '2 MB');
      expect(formatearBytes((2.3 * mb).round()), '2,3 MB');
      expect(formatearBytes(850 * 1024), '850 KB');
      expect(formatearBytes(12), '12 B');
    });

    test('formatearDuracion usa mm:ss', () {
      expect(formatearDuracion(const Duration(seconds: 92)), '01:32');
      expect(formatearDuracion(const Duration(minutes: 5)), '05:00');
      expect(
        formatearDuracion(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });
}
