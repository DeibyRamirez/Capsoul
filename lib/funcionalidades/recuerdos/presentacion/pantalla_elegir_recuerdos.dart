import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../capsulas/aplicacion/proveedores_capsulas.dart';
import '../aplicacion/proveedores_recuerdos.dart';
import '../dominio/filtro_recuerdos.dart';
import '../dominio/recuerdo.dart';
import 'componentes/barra_filtros_recuerdos.dart';
import 'componentes/rejilla_recuerdos.dart';

/// Parámetros de [PantallaElegirRecuerdos] (se pasan como `extra`).
@immutable
class ParametrosElegirRecuerdos {
  const ParametrosElegirRecuerdos({
    this.titulo = 'Elegir recuerdos',
    this.yaElegidos = const {},
    this.maximo,
    this.filtroInicial = FiltroRecuerdos.todos,
  });

  final String titulo;

  /// Ids que ya están en la cápsula o momento (no se vuelven a ofrecer).
  final Set<String> yaElegidos;

  /// Cuántos se pueden elegir como máximo; `null` sin límite.
  final int? maximo;

  final FiltroRecuerdos filtroInicial;
}

/// Selección múltiple sobre el banco de recuerdos. Devuelve con `pop` la
/// lista elegida (en el orden en que se tocaron).
class PantallaElegirRecuerdos extends ConsumerStatefulWidget {
  const PantallaElegirRecuerdos({
    super.key,
    this.parametros = const ParametrosElegirRecuerdos(),
  });

  final ParametrosElegirRecuerdos parametros;

  @override
  ConsumerState<PantallaElegirRecuerdos> createState() =>
      _EstadoPantallaElegirRecuerdos();
}

class _EstadoPantallaElegirRecuerdos
    extends ConsumerState<PantallaElegirRecuerdos> {
  late FiltroRecuerdos _filtro = widget.parametros.filtroInicial;
  final List<Recuerdo> _elegidos = [];

  Set<String> get _idsElegidos => {for (final r in _elegidos) r.id};

  void _alternar(Recuerdo recuerdo) {
    final indice = _elegidos.indexWhere((r) => r.id == recuerdo.id);
    if (indice >= 0) {
      setState(() => _elegidos.removeAt(indice));
      return;
    }
    final maximo = widget.parametros.maximo;
    if (maximo != null && _elegidos.length >= maximo) {
      mostrarAvisoInformativo(
        context,
        maximo == 1
            ? 'Puedes elegir 1 recuerdo.'
            : 'Puedes elegir hasta $maximo recuerdos.',
      );
      return;
    }
    setState(() => _elegidos.add(recuerdo));
  }

  @override
  Widget build(BuildContext context) {
    final recuerdos = ref.watch(proveedorRecuerdos(_filtro));
    final hoy = ref.watch(proveedorReloj)();
    final yaElegidos = widget.parametros.yaElegidos;
    final cantidad = _elegidos.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parametros.titulo),
        actions: [
          TextButton(
            key: const Key('boton-listo-elegir'),
            onPressed: cantidad == 0
                ? null
                : () => context.pop(List<Recuerdo>.of(_elegidos)),
            child: Text(cantidad == 0 ? 'Listo' : 'Listo ($cantidad)'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: BarraFiltrosRecuerdos(
                filtro: _filtro,
                hoy: hoy,
                alCambiar: (filtro) => setState(() => _filtro = filtro),
              ),
            ),
          ),
          ...recuerdos.when(
            loading: () => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              SinRecuerdos(mensaje: mensajeParaUsuario(error)),
            ],
            data: (lista) {
              final disponibles = [
                for (final recuerdo in lista)
                  if (!yaElegidos.contains(recuerdo.id)) recuerdo,
              ];
              return [
                if (disponibles.isEmpty)
                  SinRecuerdos(
                    mensaje: lista.isEmpty
                        ? 'No hay recuerdos con este filtro.'
                        : 'Ya agregaste todos los recuerdos de este filtro.',
                  )
                else
                  RejillaRecuerdos(
                    recuerdos: disponibles,
                    seleccionados: _idsElegidos,
                    alTocar: _alternar,
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
