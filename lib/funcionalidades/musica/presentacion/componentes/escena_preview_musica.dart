import 'dart:async';



import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:just_audio/just_audio.dart';



import '../../aplicacion/intentar_cargar_preview_con_refresco.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';

import '../../../../nucleo/tema/colores_app.dart';

import '../../aplicacion/proveedores_musica.dart';

import '../../dominio/referencia_musica.dart';

import '../../../recuerdos/aplicacion/proveedores_recuerdos.dart';

import 'disco_portada_giratorio.dart';

import 'enlaces_escuchar_completo.dart';



/// Vista centrada: disco giratorio, metadatos y preview de 30 s (Spotify/Deezer).

class EscenaPreviewMusica extends ConsumerStatefulWidget {

  const EscenaPreviewMusica({

    super.key,

    required this.referencia,

    this.reproducirAutomaticamente = false,

    this.alturaDisco,

    this.mostrarEnlacesCompletos = true,

    this.mostrarPieMetadata = true,

    /// Si se indica, tras refrescar preview se persiste en el elemento.

    this.elementoRecuerdoIdParaPersistir,

  });



  final ReferenciaMusica referencia;

  final bool reproducirAutomaticamente;

  final double? alturaDisco;

  final bool mostrarEnlacesCompletos;

  final bool mostrarPieMetadata;

  final String? elementoRecuerdoIdParaPersistir;



  @override

  ConsumerState<EscenaPreviewMusica> createState() =>

      EscenaPreviewMusicaState();

}



class EscenaPreviewMusicaState extends ConsumerState<EscenaPreviewMusica> {

  final AudioPlayer _reproductor = AudioPlayer();

  StreamSubscription<PlayerState>? _suscripcionEstado;

  bool _cargando = false;

  bool _reproduciendo = false;

  String? _previewUrlCargada;

  late ReferenciaMusica _referencia;



  bool get _tienePreview => _referencia.tienePreview;



  @override

  void initState() {

    super.initState();

    _referencia = widget.referencia;

    _suscripcionEstado = _reproductor.playerStateStream.listen((estado) {

      if (!mounted) return;

      setState(() => _reproduciendo = estado.playing);

    });

    if (widget.reproducirAutomaticamente && _tienePreview) {

      WidgetsBinding.instance.addPostFrameCallback((_) => _alternar());

    }

  }



  @override

  void didUpdateWidget(covariant EscenaPreviewMusica oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (widget.referencia != oldWidget.referencia) {

      _referencia = widget.referencia;

      _previewUrlCargada = null;

    }

  }



  @override

  void dispose() {

    _suscripcionEstado?.cancel();

    unawaited(_reproductor.stop());

    _reproductor.dispose();

    super.dispose();

  }



  /// Detiene el preview antes de cerrar la pantalla (p. ej. al guardar).

  Future<void> pausarPreview() async {

    try {

      await _reproductor.stop();

    } catch (_) {

      // Ignorar si el player ya se liberó.

    }

    if (mounted) {

      setState(() {

        _reproduciendo = false;

        _cargando = false;

      });

    }

  }



  Future<void> _alternar() async {

    if (!_tienePreview || !mounted) return;

    final url = _referencia.previewUrl;

    if (url == null || url.isEmpty) return;



    if (_reproduciendo) {

      await _reproductor.pause();

      return;

    }



    setState(() => _cargando = true);

    try {

      if (_previewUrlCargada != url) {

        final catalogo = ref.read(proveedorRepositorioCatalogoMusica);

        final resultado = await intentarCargarPreviewConRefresco(

          _reproductor,

          _referencia,

          catalogo,

        );

        if (resultado.refrescada) {

          setState(() => _referencia = resultado.referencia);

          final idElemento = widget.elementoRecuerdoIdParaPersistir;

          if (idElemento != null) {

            await ref

                .read(proveedorRepositorioRecuerdos)

                .actualizarMusicaPreview(idElemento, resultado.referencia);

          }

          if (mounted) {

            mostrarAvisoInformativo(context, 'Actualizamos la vista previa.');

          }

        }

        _previewUrlCargada = resultado.referencia.previewUrl;

      }

      if (!mounted) return;

      await _reproductor.play();

    } catch (e, st) {

      debugPrint('Capsoul: preview música falló: $e\n$st');

      if (mounted) {

        mostrarAvisoError(

          context,

          'No se pudo reproducir la vista previa. Intenta de nuevo.',

        );

      }

    } finally {

      if (mounted) setState(() => _cargando = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final esquema = Theme.of(context).colorScheme;

    final alturaPantalla = MediaQuery.sizeOf(context).height;

    final tamanoDisco =

        widget.alturaDisco ?? (alturaPantalla * 0.42).clamp(200.0, 320.0);



    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        SizedBox(

          height: tamanoDisco + 24,

          child: Center(

            child: DiscoPortadaGiratorio(

              referencia: _referencia,

              girando: _reproduciendo,

              tamano: tamanoDisco,

              alTocar: _tienePreview && !_cargando ? _alternar : null,

            ),

          ),

        ),

        Text(

          _referencia.titulo,

          textAlign: TextAlign.center,

          maxLines: 2,

          overflow: TextOverflow.ellipsis,

          style: Theme.of(context).textTheme.titleLarge?.copyWith(

                fontWeight: FontWeight.w700,

                color: esquema.onSurface,

              ),

        ),

        const SizedBox(height: 4),

        Text(

          _referencia.artista,

          textAlign: TextAlign.center,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: Theme.of(context).textTheme.titleMedium?.copyWith(

                color: esquema.onSurfaceVariant,

              ),

        ),

        const SizedBox(height: 12),

        if (!_tienePreview)

          Text(

            'No hay muestra de 30 s para esta pista. '

            'Puedes escucharla completa en tu plataforma favorita.',

            textAlign: TextAlign.center,

            style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                  color: esquema.onSurfaceVariant,

                ),

          )

        else

          Column(

            children: [

              Row(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  TextButton.icon(

                    onPressed: _cargando ? null : _alternar,

                    icon: _cargando

                        ? const SizedBox(

                            width: 20,

                            height: 20,

                            child: CircularProgressIndicator(strokeWidth: 2),

                          )

                        : Icon(

                            _reproduciendo

                                ? Icons.pause_circle

                                : Icons.play_circle,

                            color: ColoresApp.acento,

                            size: 28,

                          ),

                    label: Text(

                      _reproduciendo

                          ? 'Pausar vista previa'

                          : 'Reproducir vista previa',

                      style: const TextStyle(color: ColoresApp.acento),

                    ),

                  ),

                ],

              ),

              if (_referencia.previewProveedorEfectivo ==

                  ProveedorPreviewMusica.deezer)

                Text(

                  _referencia.etiquetaPreview,

                  textAlign: TextAlign.center,

                  style: Theme.of(context).textTheme.bodySmall?.copyWith(

                        color: esquema.onSurfaceVariant,

                      ),

                ),

            ],

          ),

        if (widget.mostrarEnlacesCompletos) ...[

          const SizedBox(height: 20),

          EnlacesEscucharCompleto(referencia: _referencia),

        ],

        if (widget.mostrarPieMetadata) ...[

          const SizedBox(height: 4),

          Text(

            'Música · ${_referencia.etiquetaCorta}',

            textAlign: TextAlign.center,

            style: Theme.of(context).textTheme.bodySmall?.copyWith(

                  color: esquema.onSurfaceVariant,

                ),

          ),

        ],

      ],

    );

  }

}


