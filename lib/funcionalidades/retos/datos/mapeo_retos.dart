import '../dominio/reto.dart';

List<String> _leerPasos(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((e) => e.toString()).toList();
}

Reto retoDesdeFila(Map<String, dynamic> fila) {
  final completadoEn = fila['completado_en'];
  return Reto(
    id: fila['id'] as String,
    slug: fila['slug'] as String,
    titulo: fila['titulo'] as String,
    descripcion: fila['descripcion'] as String?,
    pasos: _leerPasos(fila['pasos']),
    orden: (fila['orden'] as num?)?.toInt() ?? 0,
    criterioClave: fila['criterio_clave'] as String,
    completado: fila['completado'] == true,
    completadoEn: completadoEn is String
        ? DateTime.tryParse(completadoEn)
        : completadoEn is DateTime
            ? completadoEn
            : null,
  );
}
