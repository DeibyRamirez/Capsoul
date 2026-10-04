import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/cliente_firma_subida.dart';
import '../datos/compresor_medios_dispositivo.dart';
import '../datos/grabadora_audio_record.dart';
import '../datos/repositorio_medios_cloudinary.dart';
import '../dominio/compresor_medios.dart';
import '../dominio/grabadora_audio.dart';
import '../dominio/repositorio_medios.dart';

/// Compresión y medición de medios en el teléfono (se sobrescribe en
/// pruebas).
final proveedorCompresorMedios = Provider<CompresorMedios>(
  (ref) => CompresorMediosDispositivo(),
);

/// Subida firmada a Cloudinary (se sobrescribe en pruebas).
final proveedorRepositorioMedios = Provider<RepositorioMedios>((ref) {
  final repositorio = RepositorioMediosCloudinary(ClienteFirmaSubidaSupabase());
  ref.onDispose(repositorio.liberarRecursos);
  return repositorio;
});

/// Fábrica de grabadoras: cada pantalla de audio crea y libera la suya.
final proveedorFabricaGrabadora = Provider<GrabadoraAudio Function()>(
  (ref) => GrabadoraAudioRecord.new,
);
