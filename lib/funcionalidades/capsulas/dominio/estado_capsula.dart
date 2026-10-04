/// Estados de una cápsula (enum `public.estado_capsula`).
enum EstadoCapsula {
  borrador('borrador'),
  programada('programada'),
  liberada('liberada'),
  cancelada('cancelada');

  const EstadoCapsula(this.valorBd);

  final String valorBd;

  static EstadoCapsula? desdeValorBd(Object? valor) {
    for (final estado in EstadoCapsula.values) {
      if (estado.valorBd == valor) return estado;
    }
    return null;
  }
}
