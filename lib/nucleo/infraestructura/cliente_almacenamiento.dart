import '../../funcionalidades/elementos/dominio/medio_subido.dart';

/// Contrato para subir un archivo binario a un proveedor de almacenamiento
/// (Cloudinary hoy; S3 u otro mañana).
abstract interface class ClienteAlmacenamiento {
  Future<MedioSubido> subirArchivo({
    required String rutaLocal,
    required String urlSubida,
    required Map<String, String> parametrosFirma,
  });
}
