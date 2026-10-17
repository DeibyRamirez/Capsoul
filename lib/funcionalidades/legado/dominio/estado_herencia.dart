/// Estado de una fila `herencias`.
enum EstadoHerencia {
  borrador('borrador'),
  activa('activa'),
  enVerificacion('en_verificacion'),
  liberada('liberada'),
  revocada('revocada');

  const EstadoHerencia(this.valorBd);

  final String valorBd;

  static EstadoHerencia? desdeBd(String? valor) {
    if (valor == null) return null;
    for (final e in EstadoHerencia.values) {
      if (e.valorBd == valor) return e;
    }
    return null;
  }

  bool get requiereRevision => this == EstadoHerencia.enVerificacion;
}
