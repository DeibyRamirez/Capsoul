import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/configuracion_crear.dart';

export 'controlador_sesion_captura.dart'
    show proveedorControladorSesionCaptura, ControladorSesionCaptura;

final proveedorConfiguracionCrear = Provider<ConfiguracionCrear>(
  (ref) => ConfiguracionCrear.porDefecto,
);
