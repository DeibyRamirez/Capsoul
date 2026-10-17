import '../dominio/repositorio_retos.dart';
import '../dominio/reto.dart';
import 'acceso_tablas_retos.dart';
import 'mapeo_retos.dart';

class RepositorioRetosSupabase implements RepositorioRetos {
  RepositorioRetosSupabase(this._acceso);

  final AccesoTablasRetos _acceso;

  @override
  Future<List<Reto>> listar() async {
    final filas = await _acceso.listarGlobales();
    return filas.map(retoDesdeFila).toList();
  }

  @override
  Future<int> contarPendientes() => _acceso.contarPendientes();
}
