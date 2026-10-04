import 'package:capsoul/funcionalidades/momentos/dominio/momento.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/nuevo_momento.dart';
import 'package:capsoul/funcionalidades/momentos/dominio/repositorio_momentos.dart';
import 'package:capsoul/nucleo/errores/fallo_app.dart';

/// [RepositorioMomentos] en memoria.
class RepositorioMomentosFalso implements RepositorioMomentos {
  final Map<String, Momento> momentos = {};
  final List<NuevoMomento> creados = [];
  final List<String> eliminados = [];
  FalloApp? siguienteFallo;

  @override
  Future<String> crear(NuevoMomento nuevo) async {
    final fallo = siguienteFallo;
    if (fallo != null) {
      siguienteFallo = null;
      throw fallo;
    }
    creados.add(nuevo);
    final id = 'momento-${creados.length}';
    final portadaId = nuevo.portadaId;
    momentos[id] = Momento(
      id: id,
      autorId: 'uid-123',
      titulo: nuevo.titulo.trim(),
      descripcion: nuevo.descripcion,
      creadoEn: DateTime(2026, 10, 3),
      portada: portadaId == null
          ? null
          : nuevo.recuerdos.firstWhere((r) => r.id == portadaId),
      cantidad: nuevo.recuerdos.length,
      recuerdos: nuevo.recuerdos,
    );
    return id;
  }

  @override
  Future<List<Momento>> listar() async => momentos.values.toList();

  @override
  Future<Momento?> obtener(String id) async => momentos[id];

  @override
  Future<void> eliminar(String id) async {
    eliminados.add(id);
    momentos.remove(id);
  }
}
