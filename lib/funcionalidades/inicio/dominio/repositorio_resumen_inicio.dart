import 'resumen_inicio.dart';

/// Lee los conteos de Inicio del usuario [uid].
abstract interface class RepositorioResumenInicio {
  Future<ResumenInicio> leerResumen(String uid);
}
