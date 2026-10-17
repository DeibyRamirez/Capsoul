import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../amistades/aplicacion/proveedores_amistades.dart';
import '../../../amistades/dominio/amigo.dart';
import '../../../../nucleo/tema/colores_app.dart';

/// Lista de amigos aceptados con selección múltiple (destinatarios de cápsula).
class SelectorDestinatariosAmigos extends ConsumerStatefulWidget {
  const SelectorDestinatariosAmigos({
    super.key,
    required this.seleccionados,
    required this.deshabilitado,
    required this.alCambiar,
  });

  final Set<String> seleccionados;
  final bool deshabilitado;
  final void Function(Set<String> ids) alCambiar;

  @override
  ConsumerState<SelectorDestinatariosAmigos> createState() =>
      _EstadoSelectorDestinatariosAmigos();
}

class _EstadoSelectorDestinatariosAmigos extends ConsumerState<SelectorDestinatariosAmigos> {
  final _filtro = TextEditingController();

  @override
  void dispose() {
    _filtro.dispose();
    super.dispose();
  }

  bool _coincide(Amigo amigo, String consulta) {
    if (consulta.isEmpty) return true;
    final q = consulta.toLowerCase();
    if (amigo.nombreVisible.toLowerCase().contains(q)) return true;
    final arroba = amigo.nombreUsuario;
    if (arroba != null && arroba.toLowerCase().contains(q)) return true;
    if (arroba != null && '@$arroba'.contains(q)) return true;
    return false;
  }

  void _alternar(String usuarioId, bool? marcado) {
    final ids = Set<String>.from(widget.seleccionados);
    if (marcado == true) {
      ids.add(usuarioId);
    } else {
      ids.remove(usuarioId);
    }
    widget.alCambiar(ids);
  }

  @override
  Widget build(BuildContext context) {
    final amigos = ref.watch(proveedorMisAmigos);
    return amigos.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text(
        'No pudimos cargar tus amigos. Revisa tu conexión.',
        style: TextStyle(color: ColoresApp.atenuado),
      ),
      data: (lista) {
        if (lista.isEmpty) {
          return const Text(
            'Aún no tienes amigos en Capsoul. Invítalos desde tu perfil '
            'y vuelve a crear la cápsula.',
            style: TextStyle(color: ColoresApp.atenuado),
          );
        }
        final consulta = _filtro.text.trim().toLowerCase();
        final filtrados = [
          for (final amigo in lista)
            if (_coincide(amigo, consulta)) amigo,
        ];
        final n = widget.seleccionados.length;
        return InputDecorator(
          decoration: InputDecoration(
            labelText: n == 0 ? 'Destinatarios' : 'Destinatarios ($n)',
            contentPadding: EdgeInsets.zero,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  key: const Key('filtro-destinatario-arroba'),
                  controller: _filtro,
                  decoration: const InputDecoration(
                    hintText: 'Filtrar por nombre o @',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (filtrados.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Ningún amigo coincide con ese filtro.',
                    style: TextStyle(color: ColoresApp.atenuado),
                  ),
                ),
              for (final amigo in filtrados)
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    key: Key('destinatario-${amigo.usuarioId}'),
                    value: widget.seleccionados.contains(amigo.usuarioId),
                    onChanged: widget.deshabilitado
                        ? null
                        : (valor) => _alternar(amigo.usuarioId, valor),
                    title: Text(amigo.nombreVisible),
                    subtitle: Text(amigo.etiquetaArroba),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
