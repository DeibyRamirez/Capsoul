import '../dominio/reto.dart';

/// Agrupa el catálogo plano en secciones del Diario.
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

  /// El catálogo ampliado reserva esta entrada como meta final del Diario.
  static const String slugEspecial = 'veinticinco_recuerdos';
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

  Reto? especial;
  for (final reto in activos) {
    if (reto.slug == ClasificacionRetosUi.slugEspecial) {
      especial = reto;
      break;
    }
  }

  Reto? diario;
  for (final reto in activos) {
    if (reto.id != especial?.id) {
      diario = reto;
      break;
    }
  }

  final semanales = activos
      .where((reto) => reto.id != diario?.id && reto.id != especial?.id)
      .take(2)
      .toList();

  final excluidos = <String>{
    if (diario != null) diario.id,
    if (especial != null) especial.id,
    ...semanales.map((reto) => reto.id),
  };
  final restoActivos = activos
      .where((reto) => !excluidos.contains(reto.id))
      .toList();

  return ClasificacionRetosUi(
    diario: diario,
    semanales: semanales,
    especial: especial,
    restoActivos: restoActivos,
    completados: completados,
    totalCompletados: completados.length,
  );
}

/// Agrupa las entradas restantes para que el catálogo largo siga siendo legible.
List<({String titulo, List<Reto> retos})> agruparRestoActivos(
  List<Reto> retos,
) {
  const ordenGrupos = [
    'Primeros pasos',
    'Recuerdos',
    'Cápsulas',
    'Momentos',
    'Legado',
  ];
  final grupos = <String, List<Reto>>{
    for (final titulo in ordenGrupos) titulo: <Reto>[],
  };
  for (final reto in retos) {
    grupos[_grupoDeReto(reto)]!.add(reto);
  }
  return [
    for (final titulo in ordenGrupos)
      if (grupos[titulo]!.isNotEmpty)
        (titulo: titulo, retos: List.unmodifiable(grupos[titulo]!)),
  ];
}

String _grupoDeReto(Reto reto) {
  final clave = reto.criterioClave;
  if (clave == 'primer_momento' || clave.startsWith('momento')) {
    return 'Momentos';
  }
  if (clave.startsWith('herencia') || clave == 'persona_confianza') {
    return 'Legado';
  }
  if (clave == 'primer_capsula' || clave.startsWith('capsula')) {
    return 'Cápsulas';
  }
  if (clave.startsWith('recuerdo')) return 'Recuerdos';
  return 'Primeros pasos';
}
