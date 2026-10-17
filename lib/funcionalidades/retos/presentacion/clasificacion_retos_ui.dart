import '../dominio/reto.dart';

/// Agrupa el catálogo plano en secciones del mockup (heurísticas en cliente).
class ClasificacionRetosUi {
  const ClasificacionRetosUi({
    required this.diario,
    required this.semanales,
    required this.especial,
    required this.restoActivos,
    required this.completados,
    required this.totalCompletados,
  });

  final Reto? diario;
  final List<Reto> semanales;
  final Reto? especial;
  final List<Reto> restoActivos;
  final List<Reto> completados;
  final int totalCompletados;

  static const int metaEspecialDias = 30;
}

/// Presentación hasta migración de categorías / favoritos en backend.
ClasificacionRetosUi clasificarRetosParaUi(List<Reto> todos) {
  final ordenados = [...todos]..sort((a, b) => a.orden.compareTo(b.orden));
  final activos = ordenados.where((r) => !r.completado).toList();
  final completados = [...ordenados.where((r) => r.completado)]
    ..sort((a, b) {
      final fa = a.completadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fb = b.completadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      return fb.compareTo(fa);
    });

  final diario = activos.isEmpty ? null : activos.first;
  final trasDiario = diario == null ? activos : activos.sublist(1);
  final semanales = trasDiario.take(2).toList();
  final trasSemanales = trasDiario.skip(2).toList();

  Reto? especial;
  List<Reto> restoActivos;
  if (activos.length >= 4 && trasSemanales.isNotEmpty) {
    especial = trasSemanales.last;
    restoActivos = trasSemanales.length > 1
        ? trasSemanales.sublist(0, trasSemanales.length - 1)
        : const [];
  } else {
    especial = null;
    restoActivos = trasSemanales;
  }

  return ClasificacionRetosUi(
    diario: diario,
    semanales: semanales,
    especial: especial,
    restoActivos: restoActivos,
    completados: completados,
    totalCompletados: completados.length,
  );
}

/// Puntos del reto diario (máx. 6 círculos).
int puntosDiariosRellenos(Reto reto) {
  if (reto.completado) return puntosDiariosTotal(reto);
  return reto.pasos.isEmpty ? 0 : 1;
}

int puntosDiariosTotal(Reto reto) {
  final total = reto.pasos.isEmpty ? 6 : reto.pasos.length;
  return total.clamp(1, 6);
}

/// Fracción decorativa semanal en pestaña Activos (mock 2/7, 1/7).
int numeradorProgresoSemanal(int indice, Reto reto) {
  if (reto.completado) return 7;
  return (2 - indice).clamp(0, 7);
}
