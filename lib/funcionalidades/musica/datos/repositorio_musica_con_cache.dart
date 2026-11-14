import '../dominio/cache_busquedas_musica.dart';
import '../dominio/referencia_musica.dart';
import '../dominio/repositorio_catalogo_musica.dart';

/// Catálogo con caché en memoria y una sola petición por consulta en curso.
///
/// `obtenerPorId` no se cachea: el preview se pide siempre fresco a
/// `/track/<id>` y la URL no se reutiliza pasada su vigencia.
class RepositorioMusicaConCache implements RepositorioCatalogoMusica {
  RepositorioMusicaConCache(this._interno, {CacheBusquedasMusica? cache})
    : _cache = cache ?? CacheBusquedasMusica();

  final RepositorioCatalogoMusica _interno;
  final CacheBusquedasMusica _cache;
  final Map<String, Future<List<ReferenciaMusica>>> _enCurso = {};

  @override
  Future<List<ReferenciaMusica>> buscar(
    String consulta, {
    int limite = 25,
    String mercado = 'CO',
  }) {
    final clave = normalizarConsultaMusica(consulta);
    if (clave.isEmpty) return Future.value(const []);

    final guardada = _cache.obtener(clave);
    if (guardada != null) return Future.value(guardada);

    final enCurso = _enCurso[clave];
    if (enCurso != null) return enCurso;

    // Un solo Future: quien llegue mientras sigue en curso lo reutiliza.
    // El callback corre después de asignar [futuro] (el `then` es asíncrono).
    late final Future<List<ReferenciaMusica>> futuro;
    futuro = _interno
        .buscar(consulta, limite: limite, mercado: mercado)
        .then((resultados) {
          _cache.guardar(consulta, resultados);
          return resultados;
        })
        .whenComplete(() {
          if (identical(_enCurso[clave], futuro)) {
            _enCurso.remove(clave);
          }
        });
    _enCurso[clave] = futuro;
    return futuro;
  }

  @override
  Future<ReferenciaMusica?> obtenerPorId(String idExterno) =>
      _interno.obtenerPorId(idExterno);
}
