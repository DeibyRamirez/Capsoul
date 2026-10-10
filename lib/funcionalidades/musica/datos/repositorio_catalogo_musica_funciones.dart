import '../../../nucleo/infraestructura/cliente_funciones_api.dart';
import '../dominio/referencia_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';

class RepositorioCatalogoMusicaFunciones implements RepositorioCatalogoMusica {
  RepositorioCatalogoMusicaFunciones(this._funciones);

  final ClienteFuncionesApi _funciones;

  @override
  Future<List<ReferenciaMusica>> buscar(
    String consulta, {
    int limite = 10,
    String mercado = 'CO',
  }) async {
    final filas = await _funciones.buscarMusica(
      consulta: consulta,
      limite: limite,
      mercado: mercado,
    );
    return [
      for (final fila in filas) ?ReferenciaMusica.desdeJsonApi(fila),
    ];
  }
}
