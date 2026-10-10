import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/infraestructura/cliente_funciones_api.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_musica.dart';
import '../dominio/referencia_musica.dart';
import 'componentes/reproductor_preview_musica.dart';

/// Busca pistas en Spotify y devuelve la elegida con `Navigator.pop`.
class PantallaBuscarMusica extends ConsumerStatefulWidget {
  const PantallaBuscarMusica({super.key, this.soloSeleccion = false});

  /// Si es true, el botón principal confirma la pista en reproducción.
  final bool soloSeleccion;

  @override
  ConsumerState<PantallaBuscarMusica> createState() =>
      _EstadoPantallaBuscarMusica();
}

class _EstadoPantallaBuscarMusica extends ConsumerState<PantallaBuscarMusica> {
  final _consulta = TextEditingController();
  Timer? _debounce;
  List<ReferenciaMusica> _resultados = const [];
  bool _buscando = false;
  String? _error;
  ReferenciaMusica? _seleccionada;

  @override
  void dispose() {
    _debounce?.cancel();
    _consulta.dispose();
    super.dispose();
  }

  void _programarBusqueda() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _buscar);
  }

  Future<void> _buscar() async {
    final texto = _consulta.text.trim();
    if (texto.length < 2) {
      setState(() {
        _resultados = const [];
        _error = null;
      });
      return;
    }
    setState(() {
      _buscando = true;
      _error = null;
    });
    try {
      final lista = await ref
          .read(proveedorRepositorioCatalogoMusica)
          .buscar(texto, limite: 10);
      if (!mounted) return;
      setState(() {
        _resultados = lista;
        _buscando = false;
      });
    } on ErrorFuncionesApi catch (error) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
        _error = mensajeErrorFuncionesApi(
          error,
          porDefecto: 'No se pudo buscar. Intenta de nuevo.',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
        _error = 'Error inesperado al buscar.';
      });
    }
  }

  void _elegir(ReferenciaMusica ref) {
    if (widget.soloSeleccion) {
      setState(() => _seleccionada = ref);
      return;
    }
    Navigator.of(context).pop(ref);
  }

  void _confirmarSeleccion() {
    final ref = _seleccionada;
    if (ref == null) {
      mostrarAvisoInformativo(context, 'Elige una canción de la lista.');
      return;
    }
    Navigator.of(context).pop(ref);
  }

  @override
  Widget build(BuildContext context) {
    return PantallaCapsoul(
      appBar: AppBar(
        title: Text(widget.soloSeleccion ? 'Elegir música' : 'Buscar música'),
      ),
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _consulta,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Artista o canción',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _consulta.clear();
                          setState(() => _resultados = const []);
                        },
                      ),
              ),
              onChanged: (_) => _programarBusqueda(),
              onSubmitted: (_) => _buscar(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _resultados.length,
              itemBuilder: (context, indice) {
                final pista = _resultados[indice];
                final elegida = _seleccionada?.idExterno == pista.idExterno;
                return ListTile(
                  leading: _Portada(pista: pista),
                  title: Text(pista.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  ),
                  selected: elegida,
                  onTap: () => _elegir(pista),
                  onLongPress: () => _elegir(pista),
                );
              },
            ),
          ),
          if (widget.soloSeleccion)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _confirmarSeleccion,
                  child: const Text('Usar esta canción'),
                ),
              ),
            ),
        ],
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
      return const CircleAvatar(
        child: Icon(Icons.music_note, color: ColoresApp.primario),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
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
