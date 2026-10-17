import 'elemento_borrador.dart';
import 'tipo_elemento.dart';

/// Elige un archivo del dispositivo y lo prepara como [ElementoBorrador].
abstract interface class ImportadorMedios {
  Future<ElementoBorrador?> importar(TipoElemento tipo);
}
