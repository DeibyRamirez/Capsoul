import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import '../datos/repositorio_catalogo_musica_funciones.dart';
import '../dominio/repositorio_catalogo_musica.dart';

final proveedorRepositorioCatalogoMusica =
    Provider<RepositorioCatalogoMusica>((ref) {
  return RepositorioCatalogoMusicaFunciones(
    ref.watch(proveedorClienteFuncionesApi),
  );
});
