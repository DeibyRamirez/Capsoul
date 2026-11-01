import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../recuerdos/aplicacion/proveedores_recuerdos.dart';
import '../../aplicacion/coordinador_preview_musica.dart';
import '../../aplicacion/intentar_cargar_preview_con_refresco.dart';
import '../../aplicacion/proveedores_musica.dart';
import '../../dominio/fallo_musica.dart';
import '../../dominio/referencia_musica.dart';
import 'barra_progreso_preview.dart';
import 'credito_deezer.dart';
import 'disco_portada_giratorio.dart';
import 'enlaces_escuchar_completo.dart';

/// Vista centrada: disco giratorio, metadatos, preview de 30 s en streaming,
/// progreso, crédito de Deezer y botones para escuchar en otras apps.
class EscenaPreviewMusica extends ConsumerStatefulWidget {
  const EscenaPreviewMusica({
    super.key,
    required this.referencia,
    this.reproducirAutomaticamente = false,
    this.alturaDisco,
    this.mostrarEnlacesCompletos = true,
    this.mostrarPieMetadata = true,

    /// Solo filas antiguas (Spotify): tras refrescar se persiste la URL.
    /// En Deezer la URL del preview nunca se guarda.
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
  late final CoordinadorPreviewMusica _coordinador;
  bool _cargando = false;
  bool _reproduciendo = false;
  bool _listo = false;
  bool _sinPreview = false;
  late ReferenciaMusica _referencia;

  bool get _disponible => _referencia.puedeReproducirPreview && !_sinPreview;

  @override
  void initState() {
    super.initState();
    _referencia = widget.referencia;
    _coordinador = ref.read(proveedorCoordinadorPreviewMusica);
    _suscripcionEstado = _reproductor.playerStateStream.listen((estado) {
      if (!mounted) return;
      if (estado.processingState == ProcessingState.completed) {
        unawaited(_reproductor.pause());
        unawaited(_reproductor.seek(Duration.zero));
      }
      final sonando = estado.playing &&
          estado.processingState != ProcessingState.completed;
      if (sonando != _reproduciendo) setState(() => _reproduciendo = sonando);
    });
    if (widget.reproducirAutomaticamente && _disponible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _alternar());
    }
  }

  @override
  void didUpdateWidget(covariant EscenaPreviewMusica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.referencia != oldWidget.referencia) {
      _referencia = widget.referencia;
      _listo = false;
      _sinPreview = false;
    }
  }

  @override
  void dispose() {
    _suscripcionEstado?.cancel();
    _coordinador.soltar(_reproductor);
    unawaited(_reproductor.dispose());
    super.dispose();
  }

  /// Detiene el preview antes de cerrar la pantalla (p. ej. al guardar).
  Future<void> pausarPreview() async {
    try {
      await _reproductor.stop();
      _listo = false;
    } catch (_) {
      // Ignorar si el reproductor ya se liberó.
    }
    if (mounted) {
      setState(() {
        _reproduciendo = false;
        _cargando = false;
      });
    }
  }

  Future<void> _alternar() async {
    if (!_disponible || !mounted || _cargando) return;
    if (_reproduciendo) {
      await _reproductor.pause();
      return;
    }
    setState(() => _cargando = true);
    try {
      if (!_listo) {
        final resultado = await intentarCargarPreviewConRefresco(
          _reproductor,
          _referencia,
          ref.read(proveedorRepositorioCatalogoMusica),
        );
        if (!mounted) return;
        setState(() {
          _referencia = resultado.referencia;
          _listo = true;
        });
        final idElemento = widget.elementoRecuerdoIdParaPersistir;
        if (resultado.refrescada && idElemento != null) {
          await ref
              .read(proveedorRepositorioRecuerdos)
              .actualizarMusicaPreview(idElemento, resultado.referencia);
        }
      }
      if (!mounted) return;
      await _coordinador.tomar(_reproductor);
      unawaited(_reproductor.play());
    } on FalloMusica catch (fallo) {
      if (!mounted) return;
      if (fallo.tipo == TipoFalloMusica.sinPreview) {
        setState(() => _sinPreview = true);
      } else {
        mostrarAvisoInformativo(context, fallo.mensaje);
      }
    } catch (error) {
      debugPrint('Capsoul: preview de música falló: $error');
      if (mounted) {
        mostrarAvisoInformativo(
          context,
          'No se pudo reproducir la vista previa. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  bool get _usaDeezer =>
      _referencia.esDeezer ||
      _referencia.previewProveedorEfectivo == ProveedorPreviewMusica.deezer;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
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
              alTocar: _disponible && !_cargando ? _alternar : null,
            ),
          ),
        ),
        Text(
          _referencia.titulo,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tema.textTheme.titleLarge?.copyWith(
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
          style: tema.textTheme.titleMedium?.copyWith(
            color: esquema.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (!_disponible)
          Text(
            'No hay muestra de 30 s para esta canción. '
            'Puedes escucharla completa en tu app favorita.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: esquema.onSurfaceVariant,
            ),
          )
        else ...[
          Center(
            child: TextButton.icon(
              onPressed: _cargando ? null : _alternar,
              icon: _cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _reproduciendo ? Icons.pause_circle : Icons.play_circle,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BarraProgresoPreview(reproductor: _reproductor),
          ),
        ],
        if (widget.mostrarEnlacesCompletos) ...[
          const SizedBox(height: 20),
          EnlacesEscucharCompleto(referencia: _referencia),
        ],
        if (widget.mostrarPieMetadata) ...[
          const SizedBox(height: 12),
          if (_usaDeezer)
            const Center(child: CreditoDeezer(mostrarUsoPersonal: true))
          else
            Text(
              'Música · ${_referencia.etiquetaCorta}',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall?.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }
}
