import '../../elementos/dominio/validador_medios.dart';
import 'fallo_momento.dart';
import 'nuevo_momento.dart';

/// Reglas de un momento nuevo (título 1..80 como la migración 000004;
/// descripción, cantidad y portada se validan también en la app).
abstract final class ValidadorMomento {
  static const int caracteresMaxTitulo = 80;
  static const int caracteresMaxDescripcion = 500;
  static const int recuerdosMax = 60;

  static FalloMomento? validar(NuevoMomento nuevo) {
    final titulo = contarCaracteres(nuevo.titulo.trim());
    if (titulo < 1 || titulo > caracteresMaxTitulo) {
      return const FalloMomento.tituloInvalido();
    }
    if (contarCaracteres(nuevo.descripcion?.trim() ?? '') >
        caracteresMaxDescripcion) {
      return const FalloMomento.descripcionLarga();
    }
    if (nuevo.recuerdos.isEmpty) return const FalloMomento.sinRecuerdos();
    if (nuevo.recuerdos.length > recuerdosMax) {
      return const FalloMomento.demasiadosRecuerdos();
    }
    final portada = nuevo.portadaId;
    if (portada != null &&
        !nuevo.recuerdos.any((r) => r.id == portada && r.esVisual)) {
      return const FalloMomento.portadaInvalida();
    }
    return null;
  }
}
