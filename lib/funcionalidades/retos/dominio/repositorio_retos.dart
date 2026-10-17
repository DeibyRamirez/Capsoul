import 'reto.dart';

abstract interface class RepositorioRetos {
  Future<List<Reto>> listar();

  Future<int> contarPendientes();
}
