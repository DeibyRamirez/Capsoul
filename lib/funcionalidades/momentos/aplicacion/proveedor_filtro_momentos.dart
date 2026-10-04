import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../elementos/dominio/tipo_elemento.dart';
import '../dominio/filtro_momentos.dart';

/// Filtro en memoria compartido entre Perfil y otras vistas de momentos.
final proveedorFiltroMomentos =
    NotifierProvider.autoDispose<FiltroMomentosNotifier, FiltroMomentos>(
  FiltroMomentosNotifier.new,
);

class FiltroMomentosNotifier extends Notifier<FiltroMomentos> {
  @override
  FiltroMomentos build() => const FiltroMomentos();

  void actualizarConsulta(String consulta) {
    state = state.conConsulta(consulta);
  }

  void actualizarTipo(TipoElemento? tipo) {
    state = state.conTipo(tipo);
  }
}
