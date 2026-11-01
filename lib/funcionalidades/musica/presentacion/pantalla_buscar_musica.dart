import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../aplicacion/controlador_busqueda_musica.dart';
import '../aplicacion/estado_busqueda_musica.dart';
import '../aplicacion/preview_musica_compartido.dart';
import '../dominio/referencia_musica.dart';
import 'componentes/barra_progreso_preview.dart';
import 'componentes/credito_deezer.dart';
import 'componentes/reproductor_preview_musica.dart';

/// Busca canciones en Deezer y devuelve la elegida con `Navigator.pop`.
class PantallaBuscarMusica extends ConsumerStatefulWidget {
  const PantallaBuscarMusica({super.key, this.soloSeleccion = false});

  /// Si es true, el botón principal confirma la canción marcada.
  final bool soloSeleccion;

  @override
  ConsumerState<PantallaBuscarMusica> createState() =>
      _EstadoPantallaBuscarMusica();
}

class _EstadoPantallaBuscarMusica extends ConsumerState<PantallaBuscarMusica> {
  final _consulta = TextEditingController();

  /// Un solo reproductor para toda la lista: nunca suenan dos previews.
  final _previewCompartido = PreviewMusicaCompartido();
  ReferenciaMusica? _seleccionada;

  @override
  void dispose() {
    // Detener el preview al salir de la pantalla.
    unawaited(_previewCompartido.reproductor.stop());
    _previewCompartido.dispose();
    _consulta.dispose();
    super.dispose();
  }

  void _elegir(ReferenciaMusica pista) {
    setState(() => _seleccionada = pista);
    if (!widget.soloSeleccion) {
      unawaited(_previewCompartido.reproductor.stop());
      Navigator.of(context).pop(pista);
    }
  }

  void _confirmarSeleccion() {
    final pista = _seleccionada;
    if (pista == null) {
      mostrarAvisoInformativo(context, 'Elige una canción de la lista.');
      return;
    }
    unawaited(_previewCompartido.reproductor.stop());
    Navigator.of(context).pop(pista);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(proveedorControladorBusquedaMusica);
    final controlador = ref.read(proveedorControladorBusquedaMusica.notifier);
    return PantallaCapsoul(
      usarAreaSegura: false,
      cuerpo: Column(
        children: [
          CabeceraDetalleCapsoul(
            titulo: widget.soloSeleccion ? 'Elegir música' : 'Buscar música',
            subtitulo: 'Busca por artista o canción.',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: DecoratedBox(
                      decoration: TemaApp.decoracionTarjeta(
                        radio: TemaApp.radioMediano,
                      ),
                      child: TextField(
                        key: const Key('campo_buscar_musica'),
                        controller: _consulta,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Artista o canción',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: ColoresApp.tarjeta,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          suffixIcon: _consulta.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Borrar búsqueda',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _consulta.clear();
                                    controlador.cambiarConsulta('');
                                    setState(() {});
                                  },
                                ),
                        ),
                        onChanged: (texto) {
                          controlador.cambiarConsulta(texto);
                          setState(() {});
                        },
                        onSubmitted: (_) => controlador.buscarAhora(),
                      ),
                    ),
                  ),
                  if (estado.cargando && estado.resultados.isNotEmpty)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(child: _contenido(estado, controlador)),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: CreditoDeezer(mostrarUsoPersonal: true),
                  ),
                  if (widget.soloSeleccion)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: BotonPrincipal(
                        etiqueta: 'Usar esta canción',
                        alPresionar: _confirmarSeleccion,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido(
    EstadoBusquedaMusica estado,
    ControladorBusquedaMusica controlador,
  ) {
    final error = estado.error;
    if (error != null) {
      return _Mensaje(
        icono: Icons.wifi_off_rounded,
        texto: error,
        accion: TextButton.icon(
          onPressed: controlador.buscarAhora,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }
    if (estado.cargando && estado.resultados.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!estado.consultaValida) {
      return const _Mensaje(
        icono: Icons.music_note_outlined,
        texto: 'Escribe el nombre de una canción o de un artista.',
      );
    }
    if (estado.sinResultados) {
      return _Mensaje(
        icono: Icons.search_off_rounded,
        texto: 'No encontramos canciones para «${estado.consultaBuscada}».',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: estado.resultados.length,
      itemBuilder: (context, indice) {
        final pista = estado.resultados[indice];
        return _FilaPista(
          pista: pista,
          elegida: _seleccionada?.idExterno == pista.idExterno,
          compartido: _previewCompartido,
          alElegir: () => _elegir(pista),
        );
      },
    );
  }
}

class _FilaPista extends StatelessWidget {
  const _FilaPista({
    required this.pista,
    required this.elegida,
    required this.compartido,
    required this.alElegir,
  });

  final ReferenciaMusica pista;
  final bool elegida;
  final PreviewMusicaCompartido compartido;
  final VoidCallback alElegir;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: elegida
            ? ColoresApp.primario.withValues(alpha: 0.08)
            : ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        border: Border.all(
          color: elegida ? ColoresApp.primario : ColoresApp.bordeTarjeta,
          width: elegida ? 2 : 1,
        ),
        boxShadow: TemaApp.sombraTarjeta,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(TemaApp.radioMediano),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _Portada(pista: pista),
              title: Text(
                pista.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pista.artista,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pista.etiquetaPreview,
                    style: TextStyle(
                      fontSize: 12,
                      color: pista.tienePreview
                          ? ColoresApp.acento
                          : ColoresApp.atenuado,
                      fontWeight: pista.tienePreview
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: ReproductorPreviewMusica(
                referencia: pista,
                compacto: true,
                compartido: compartido,
              ),
              onTap: alElegir,
            ),
            ListenableBuilder(
              listenable: compartido,
              builder: (context, _) {
                if (compartido.idActivo != pista.idExterno) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: BarraProgresoPreview(
                    reproductor: compartido.reproductor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.icono, required this.texto, this.accion});

  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final accion = this.accion;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 40, color: ColoresApp.navInactivo),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: ColoresApp.textoSecundario),
            ),
            if (accion != null) ...[const SizedBox(height: 8), accion],
          ],
        ),
      ),
    );
  }
}

class _Portada extends StatelessWidget {
  const _Portada({required this.pista});

  final ReferenciaMusica pista;

  @override
  Widget build(BuildContext context) {
    final url = pista.portadaUrl;
    if (url == null) {
      return CircleAvatar(
        backgroundColor: ColoresApp.primario.withValues(alpha: 0.08),
        child: const Icon(Icons.music_note, color: ColoresApp.primario),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.album_outlined),
      ),
    );
  }
}
