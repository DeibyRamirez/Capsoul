import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/filtro_recuerdos.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/nuevo_recuerdo.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/recuerdo.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/repositorio_recuerdos.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/repositorio_urls_medio.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/url_medio.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/uso_medios.dart';
import 'package:capsoul/nucleo/errores/fallo_app.dart';

/// Recuerdo de prueba.
Recuerdo recuerdoPrueba(
  String id, {
  TipoElemento tipo = TipoElemento.foto,
  DateTime? fecha,
  String propietarioId = 'uid-123',
  String? titulo,
  String? texto,
}) {
  final dia = fecha ?? DateTime(2026, 10, 3);
  return Recuerdo(
    id: id,
    propietarioId: propietarioId,
    tipo: tipo,
    fechaRecuerdo: dia,
    creadoEn: dia,
    titulo: titulo,
    contenidoTexto: tipo == TipoElemento.texto ? (texto ?? 'Nota $id') : null,
    publicId: tipo == TipoElemento.texto ? null : 'capsoul/$id',
    bytes: tipo == TipoElemento.texto ? null : 1000,
  );
}

/// [RepositorioRecuerdos] en memoria.
class RepositorioRecuerdosFalso implements RepositorioRecuerdos {
  RepositorioRecuerdosFalso({List<Recuerdo> iniciales = const []}) {
    for (final recuerdo in iniciales) {
      recuerdos[recuerdo.id] = recuerdo;
    }
  }

  final Map<String, Recuerdo> recuerdos = {};
  final List<NuevoRecuerdo> creados = [];
  final List<String> eliminados = [];

  /// Cápsulas selladas por id de recuerdo.
  final Map<String, int> selladas = {};
  int bytesUsados = 0;
  FalloApp? siguienteFallo;

  void _fallarSiToca() {
    final fallo = siguienteFallo;
    if (fallo != null) {
      siguienteFallo = null;
      throw fallo;
    }
  }

  @override
  Future<Recuerdo> crear(NuevoRecuerdo nuevo) async {
    _fallarSiToca();
    creados.add(nuevo);
    final id = 'recuerdo-${creados.length}';
    final titulo = nuevo.titulo?.trim();
    final recuerdo = Recuerdo(
      id: id,
      propietarioId: 'uid-123',
      tipo: nuevo.elemento.tipo,
      fechaRecuerdo: nuevo.fechaRecuerdo,
      creadoEn: DateTime(2026, 10, 3),
      titulo: (titulo == null || titulo.isEmpty) ? null : titulo,
      contenidoTexto: nuevo.elemento.texto,
      bytes: nuevo.elemento.bytes,
    );
    recuerdos[id] = recuerdo;
    return recuerdo;
  }

  @override
  Future<List<Recuerdo>> listar(FiltroRecuerdos filtro) async {
    _fallarSiToca();
    final lista = recuerdos.values.where(filtro.admite).toList()
      ..sort((a, b) => b.fechaRecuerdo.compareTo(a.fechaRecuerdo));
    return lista;
  }

  @override
  Future<Recuerdo?> obtener(String id) async => recuerdos[id];

  @override
  Future<int> contarCapsulasSelladas(String id) async => selladas[id] ?? 0;

  @override
  Future<void> eliminar(String id) async {
    _fallarSiToca();
    eliminados.add(id);
    recuerdos.remove(id);
  }

  @override
  Future<UsoMedios> leerUsoMedios() async =>
      UsoMedios(bytesUsados: bytesUsados);
}

/// [RepositorioUrlsMedio] sin entrega: la UI muestra los respaldos.
class RepositorioUrlsMedioFalso implements RepositorioUrlsMedio {
  RepositorioUrlsMedioFalso([this.urls = const {}]);

  final Map<String, UrlMedio> urls;

  @override
  Future<UrlMedio?> obtener(String idRecuerdo) async => urls[idRecuerdo];
}
