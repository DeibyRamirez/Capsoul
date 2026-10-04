import 'filtro_recuerdos.dart';
import 'nuevo_recuerdo.dart';
import 'recuerdo.dart';
import 'uso_medios.dart';

/// Banco de recuerdos del usuario. Las implementaciones traducen los errores
/// a [FalloRecuerdo] o [FalloMedios].
abstract interface class RepositorioRecuerdos {
  /// Sube el medio (si lo hay) y guarda el recuerdo en `elementos`.
  Future<Recuerdo> crear(NuevoRecuerdo nuevo);

  /// Recuerdos propios que pasan [filtro], del más reciente al más antiguo.
  Future<List<Recuerdo>> listar(FiltroRecuerdos filtro);

  /// Recuerdo visible para quien mira, o `null`.
  Future<Recuerdo?> obtener(String id);

  /// Cuántas cápsulas programadas o liberadas contienen el recuerdo (si es
  /// mayor que 0 no se puede borrar: CAP03).
  Future<int> contarCapsulasSelladas(String id);

  Future<void> eliminar(String id);

  Future<UsoMedios> leerUsoMedios();
}
