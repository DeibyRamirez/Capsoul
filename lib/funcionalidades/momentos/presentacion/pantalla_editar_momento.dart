import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/errores/fallo_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../inicio/aplicacion/proveedores_inicio.dart';
import '../aplicacion/proveedores_momentos.dart';
import '../dominio/validador_momento.dart';

/// Edición del título y la descripción de un momento.
class PantallaEditarMomento extends ConsumerStatefulWidget {
  const PantallaEditarMomento({super.key, required this.idMomento});

  final String idMomento;

  @override
  ConsumerState<PantallaEditarMomento> createState() =>
      _EstadoPantallaEditarMomento();
}

class _EstadoPantallaEditarMomento extends ConsumerState<PantallaEditarMomento> {
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  var _guardando = false;
  var _inicializado = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty ||
        titulo.length > ValidadorMomento.caracteresMaxTitulo) {
      mostrarAvisoInformativo(context, 'Escribe un título válido.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(proveedorRepositorioMomentos).actualizarMetadatos(
            widget.idMomento,
            titulo: titulo,
            descripcion: _descripcion.text.trim(),
          );
      ref
        ..invalidate(proveedorMomento(widget.idMomento))
        ..invalidate(proveedorMomentos)
        ..invalidate(proveedorResumenInicio);
      if (mounted) {
        mostrarAvisoInformativo(context, 'Momento actualizado.');
        context.pop();
      }
    } catch (error) {
      if (mounted) mostrarAvisoError(context, error);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final momento = ref.watch(proveedorMomento(widget.idMomento));
    return Scaffold(
      backgroundColor: ColoresApp.superficie,
      body: momento.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Mensaje(mensajeParaUsuario(error)),
        data: (m) {
          if (m == null) {
            return const _Mensaje('Este momento no existe o no puedes verlo.');
          }
          if (!_inicializado) {
            _titulo.text = m.titulo;
            _descripcion.text = m.descripcion ?? '';
            _inicializado = true;
          }
          return Column(
            children: [
              const CabeceraDetalleCapsoul(
                titulo: 'Editar momento',
                subtitulo: 'Título y descripción',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    TextField(
                      controller: _titulo,
                      decoration: const InputDecoration(labelText: 'Título'),
                      maxLength: ValidadorMomento.caracteresMaxTitulo,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descripcion,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Opcional',
                      ),
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    BotonPrincipal(
                      etiqueta: 'Guardar cambios',
                      cargando: _guardando,
                      alPresionar: _guardar,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(texto, textAlign: TextAlign.center),
        ),
      );
}
