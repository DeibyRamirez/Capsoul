import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../datos/compresor_medios_dispositivo.dart';
import '../datos/grabadora_audio_record.dart';
import '../datos/repositorio_medios_cloudinary.dart';
import '../dominio/compresor_medios.dart';
import '../dominio/grabadora_audio.dart';
import '../dominio/repositorio_medios.dart';

final proveedorCompresorMedios = Provider<CompresorMedios>(
  (ref) => CompresorMediosDispositivo(),
);

final proveedorRepositorioMedios = Provider<RepositorioMedios>((ref) {
  return RepositorioMediosCloudinary(
    funciones: ref.watch(proveedorClienteFuncionesApi),
    almacenamiento: ref.watch(proveedorClienteAlmacenamiento),
  );
});

final proveedorFabricaGrabadora = Provider<GrabadoraAudio Function()>(
  (ref) => GrabadoraAudioRecord.new,
);
