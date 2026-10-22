import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Imagen de red con caché en disco y decodificación al tamaño en pantalla.
///
/// [cacheWidth] de [Image.network] solo vive en memoria. Aquí el archivo se
/// guarda con [CacheManager] y se decodifica con [ResizeImage].
class ImagenRedCapsoul extends StatefulWidget {
  const ImagenRedCapsoul({
    super.key,
    required this.url,
    this.ancho,
    this.alto,
    this.ajuste = BoxFit.cover,
    this.alListo,
    this.alError,
    this.marcador,
    this.recorte,
  });

  final String url;
  final double? ancho;
  final double? alto;
  final BoxFit ajuste;

  /// Se llama una vez, fuera de [build], cuando el archivo ya está listo.
  final VoidCallback? alListo;
  final VoidCallback? alError;
  final Widget? marcador;
  final BorderRadius? recorte;

  @override
  State<ImagenRedCapsoul> createState() => _EstadoImagenRedCapsoul();
}

class _EstadoImagenRedCapsoul extends State<ImagenRedCapsoul> {
  static final CacheManager _cache = DefaultCacheManager();

  ImageProvider? _proveedor;
  bool _fallo = false;
  int _generacion = 0;
  String? _urlCargada;
  int? _pxAncho;
  int? _pxAlto;
  bool _avisoListo = false;
  bool _avisoError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _programarCarga();
  }

  @override
  void didUpdateWidget(ImagenRedCapsoul anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.url != widget.url) {
      _avisoListo = false;
      _avisoError = false;
      _programarCarga();
    }
  }

  void _programarCarga() {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final anchoLogico = widget.ancho ?? 48;
    final altoLogico = widget.alto ?? anchoLogico;
    final pxAncho = (anchoLogico * dpr).round().clamp(1, 2048);
    final pxAlto = (altoLogico * dpr).round().clamp(1, 2048);
    if (_urlCargada == widget.url &&
        _pxAncho == pxAncho &&
        _pxAlto == pxAlto &&
        (_proveedor != null || _fallo)) {
      return;
    }
    _urlCargada = widget.url;
    _pxAncho = pxAncho;
    _pxAlto = pxAlto;
    _cargar(widget.url, pxAncho, pxAlto);
  }

  Future<void> _cargar(String url, int pxAncho, int pxAlto) async {
    final generacion = ++_generacion;
    try {
      final archivo = await _cache.getSingleFile(url);
      if (!mounted || generacion != _generacion) return;
      setState(() {
        _fallo = false;
        _proveedor = ResizeImage(
          FileImage(archivo),
          width: pxAncho,
          height: pxAlto,
          policy: ResizeImagePolicy.fit,
        );
      });
      _notificarListo();
    } catch (_) {
      if (!mounted || generacion != _generacion) return;
      setState(() {
        _fallo = true;
        _proveedor = null;
      });
      _notificarError();
    }
  }

  void _notificarError() {
    if (_avisoError) return;
    _avisoError = true;
    widget.alError?.call();
  }

  void _notificarListo() {
    if (_avisoListo) return;
    _avisoListo = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.alListo?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = _proveedor;
    Widget hijo;
    if (_fallo || proveedor == null) {
      hijo = widget.marcador ??
          SizedBox(width: widget.ancho, height: widget.alto);
    } else {
      hijo = Image(
        image: proveedor,
        width: widget.ancho,
        height: widget.alto,
        fit: widget.ajuste,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            widget.marcador ?? SizedBox(width: widget.ancho, height: widget.alto),
      );
    }
    final recorte = widget.recorte;
    if (recorte == null) return hijo;
    return ClipRRect(borderRadius: recorte, clipBehavior: Clip.hardEdge, child: hijo);
  }
}
