import '../../elementos/dominio/tipo_elemento.dart';

/// Proporción visual de un medio (ancho / alto).
double aspectoMedio({
  required TipoElemento tipo,
  int? ancho,
  int? alto,
}) {
  if (ancho != null && alto != null && alto > 0) {
    return ancho / alto;
  }
  return switch (tipo) {
    TipoElemento.foto => 4 / 3,
    TipoElemento.video => 16 / 9,
    _ => 4 / 3,
  };
}
