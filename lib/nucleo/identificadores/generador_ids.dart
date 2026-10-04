import 'package:uuid/uuid.dart';

/// Genera el `id` (UUID v4) de una fila nueva en el cliente. Así los
/// inserts no necesitan `.select()` (RETURNING) para conocer el id.
typedef GeneradorIds = String Function();

const Uuid _uuid = Uuid();

/// [GeneradorIds] por defecto: UUID v4 aleatorio.
String generarIdAleatorio() => _uuid.v4();
