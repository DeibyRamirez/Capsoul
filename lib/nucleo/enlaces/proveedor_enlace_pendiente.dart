import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'enlace_pendiente.dart';

final proveedorEnlacePendiente =
    NotifierProvider<ControladorEnlacePendiente, EnlacePendiente?>(
  ControladorEnlacePendiente.new,
);

class ControladorEnlacePendiente extends Notifier<EnlacePendiente?> {
  @override
  EnlacePendiente? build() => null;

  void guardar(EnlacePendiente? enlace) => state = enlace;

  EnlacePendiente? consumir() {
    final actual = state;
    state = null;
    return actual;
  }
}
