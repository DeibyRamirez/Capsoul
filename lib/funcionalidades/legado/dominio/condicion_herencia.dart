enum CondicionHerencia {
  fecha('fecha'),
  inactividad('inactividad'),
  confirmacionConfianza('confirmacion_confianza');

  const CondicionHerencia(this.valorBd);

  final String valorBd;

  static CondicionHerencia? desdeBd(String? valor) {
    if (valor == null) return null;
    for (final c in CondicionHerencia.values) {
      if (c.valorBd == valor) return c;
    }
    return null;
  }
}
