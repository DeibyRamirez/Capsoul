import 'elemento_borrador.dart';
import 'medio_subido.dart';

/// Sube los medios de un elemento a Cloudinary con una firma del servidor
/// (Edge Function `firmar-subida`). Lanza [FalloMedios] si no se puede.
abstract interface class RepositorioMedios {
  Future<MedioSubido> subir(ElementoBorrador elemento);
}
