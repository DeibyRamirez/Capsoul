import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:just_audio/just_audio.dart';



import '../../aplicacion/intentar_cargar_preview_con_refresco.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';

import '../../../../nucleo/tema/colores_app.dart';

import '../../aplicacion/preview_musica_compartido.dart';

import '../../aplicacion/proveedores_musica.dart';

import '../../dominio/referencia_musica.dart';



/// Reproduce el preview de 30 s de una [ReferenciaMusica] (URL de Spotify).

class ReproductorPreviewMusica extends ConsumerStatefulWidget {

  const ReproductorPreviewMusica({

    super.key,

    required this.referencia,

    this.compacto = false,

    this.compartido,

    this.alQuitar,

  });



  final ReferenciaMusica referencia;

  final bool compacto;

  final PreviewMusicaCompartido? compartido;

  final VoidCallback? alQuitar;



  @override

  ConsumerState<ReproductorPreviewMusica> createState() =>

      ReproductorPreviewMusicaState();

}



class ReproductorPreviewMusicaState

    extends ConsumerState<ReproductorPreviewMusica> {

  AudioPlayer? _propio;

  bool _cargando = false;

  bool _reproduciendo = false;

  String? _previewUrlCargada;

  late ReferenciaMusica _referencia;



  AudioPlayer get _reproductor =>

      widget.compartido?.reproductor ?? (_propio ??= AudioPlayer());



  @override

  void initState() {

    super.initState();

    _referencia = widget.referencia;

    _reproductor.playerStateStream.listen((estado) {

      if (!mounted) return;

      setState(() => _reproduciendo = estado.playing);

    });

    widget.compartido?.addListener(_alCambiarCompartido);

  }



  @override

  void didUpdateWidget(covariant ReproductorPreviewMusica oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (widget.referencia != oldWidget.referencia) {

      _referencia = widget.referencia;

      _previewUrlCargada = null;

    }

  }



  void _alCambiarCompartido() {

    if (!mounted) return;

    final activo = widget.compartido?.idActivo == _referencia.idExterno;

    if (!activo && _reproduciendo) {

      setState(() => _reproduciendo = false);

    }

  }



  @override

  void dispose() {

    widget.compartido?.removeListener(_alCambiarCompartido);

    _propio?.dispose();

    super.dispose();

  }



  /// Inicia el preview si hay URL (p. ej. autoplay del visor).

  Future<void> reproducirSiPuede() async {

    if (_reproduciendo || _cargando) return;

    await _alternar();

  }



  Future<void> _alternar() async {

    if (!_referencia.tienePreview) return;

    final url = _referencia.previewUrl!;

    if (_reproduciendo) {

      await _reproductor.pause();

      return;

    }

    await widget.compartido?.pausarSiNoEs(_referencia.idExterno);

    setState(() => _cargando = true);

    try {

      final idCambio =

          widget.compartido?.idActivo != _referencia.idExterno;

      if (_previewUrlCargada != url || idCambio) {

        final catalogo = ref.read(proveedorRepositorioCatalogoMusica);

        final resultado = await intentarCargarPreviewConRefresco(

          _reproductor,

          _referencia,

          catalogo,

        );

        if (resultado.refrescada) {

          setState(() => _referencia = resultado.referencia);

          if (mounted) {

            mostrarAvisoInformativo(context, 'Actualizamos la vista previa.');

          }

        }

        _previewUrlCargada = resultado.referencia.previewUrl;

        widget.compartido?.marcarActivo(_referencia.idExterno);

      }

      await _reproductor.play();

    } catch (e, st) {

      debugPrint('Capsoul: preview música falló: $e\n$st');

      if (mounted) {

        mostrarAvisoError(

          context,

          'No se pudo reproducir la vista previa.',

        );

      }

    } finally {

      if (mounted) setState(() => _cargando = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final sinPreview = !_referencia.tienePreview;

    if (widget.compacto) {

      return IconButton(

        tooltip: sinPreview ? 'Sin vista previa' : 'Escuchar vista previa',

        onPressed: sinPreview || _cargando ? null : _alternar,

        icon: _cargando

            ? const SizedBox(

                width: 20,

                height: 20,

                child: CircularProgressIndicator(strokeWidth: 2),

              )

            : Icon(

                _reproduciendo ? Icons.pause_circle_filled : Icons.play_circle,

                color: ColoresApp.acento,

              ),

      );

    }

    return Row(

      children: [

        Expanded(

          child: Text(

            _referencia.etiquetaCorta,

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(fontWeight: FontWeight.w600),

          ),

        ),

        if (sinPreview)

          const Text(

            'Sin vista previa',

            style: TextStyle(color: ColoresApp.atenuado, fontSize: 12),

          )

        else

          IconButton(

            onPressed: _cargando ? null : _alternar,

            icon: _cargando

                ? const SizedBox(

                    width: 24,

                    height: 24,

                    child: CircularProgressIndicator(strokeWidth: 2),

                  )

                : Icon(

                    _reproduciendo ? Icons.pause : Icons.play_arrow,

                    color: ColoresApp.primario,

                  ),

          ),

        if (widget.alQuitar != null)

          IconButton(

            tooltip: 'Quitar música',

            onPressed: widget.alQuitar,

            icon: const Icon(Icons.close),

          ),

      ],

    );

  }

}


