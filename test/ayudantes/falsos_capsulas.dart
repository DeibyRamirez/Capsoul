import 'package:capsoul/funcionalidades/capsulas/dominio/capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/estado_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/nueva_capsula.dart';
import 'package:capsoul/funcionalidades/capsulas/dominio/repositorio_capsulas.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/medio_subido.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/repositorio_medios.dart';
import 'package:capsoul/funcionalidades/inicio/dominio/repositorio_resumen_inicio.dart';
import 'package:capsoul/funcionalidades/inicio/dominio/resumen_inicio.dart';
import 'package:capsoul/nucleo/errores/fallo_app.dart';

/// [RepositorioResumenInicio] con conteos fijos.
class RepositorioResumenInicioFalso implements RepositorioResumenInicio {
  RepositorioResumenInicioFalso([this.resumen = ResumenInicio.vacio]);

  ResumenInicio resumen;

  @override
  Future<ResumenInicio> leerResumen(String uid) async => resumen;
}

/// [RepositorioCapsulas] en memoria.
class RepositorioCapsulasFalso implements RepositorioCapsulas {
  RepositorioCapsulasFalso({this.autorId = 'uid-123'});

  final String autorId;
  final Map<String, Capsula> capsulas = {};
  final List<NuevaCapsula> creadas = [];
  FalloApp? siguienteFallo;

  @override
  Future<String> crearCapsula(NuevaCapsula nueva) async {
    final fallo = siguienteFallo;
    if (fallo != null) {
      siguienteFallo = null;
      throw fallo;
    }
    creadas.add(nueva);
    final id = 'capsula-${creadas.length}';
    capsulas[id] = Capsula(
      id: id,
      autorId: autorId,
      titulo: nueva.titulo.trim(),
      mensaje: nueva.mensaje,
      fechaApertura: nueva.fechaApertura,
      estado: EstadoCapsula.programada,
      creadoEn: DateTime(2026, 10, 3),
      elementos: nueva.recuerdos,
    );
    return id;
  }

  @override
  Future<List<Capsula>> listarMisCapsulas() async => capsulas.values.toList();

  @override
  Future<Capsula?> obtenerCapsula(String id) async => capsulas[id];
}

/// [RepositorioMedios] que devuelve una subida fija o lanza [fallo].
class RepositorioMediosFalso implements RepositorioMedios {
  final List<ElementoBorrador> subidos = [];
  FalloApp? fallo;

  @override
  Future<MedioSubido> subir(ElementoBorrador elemento) async {
    final error = fallo;
    if (error != null) throw error;
    subidos.add(elemento);
    return MedioSubido(
      publicId: 'capsoul/aleatorio-${subidos.length}',
      tipoRecurso: elemento.tipo.tipoRecursoCloudinary ?? 'image',
      bytes: elemento.bytes,
      version: 1,
      formato: elemento.formato,
      ancho: elemento.ancho,
      alto: elemento.alto,
    );
  }
}
