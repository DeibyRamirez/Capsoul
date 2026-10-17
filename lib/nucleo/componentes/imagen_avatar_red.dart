import 'dart:async';

import 'package:flutter/material.dart';

/// Imagen de avatar con URL alternativa si la principal falla o tarda demasiado.
class ImagenAvatarRed extends StatefulWidget {
  const ImagenAvatarRed({
    super.key,
    required this.urlPrincipal,
    this.urlAlternativa,
    required this.tamano,
    required this.fallback,
    this.tiempoMaximoCarga = const Duration(seconds: 20),
  });

  final String urlPrincipal;
  final String? urlAlternativa;
  final double tamano;
  final Widget fallback;
  final Duration tiempoMaximoCarga;

  @override
  State<ImagenAvatarRed> createState() => _ImagenAvatarRedState();
}

class _ImagenAvatarRedState extends State<ImagenAvatarRed> {
  late String _urlActiva;
  bool _mostrarFallback = false;
  Timer? _tiempoCarga;

  @override
  void initState() {
    super.initState();
    _urlActiva = widget.urlPrincipal;
    _iniciarTiempoCarga();
  }

  @override
  void didUpdateWidget(ImagenAvatarRed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urlPrincipal != widget.urlPrincipal ||
        oldWidget.urlAlternativa != widget.urlAlternativa) {
      _urlActiva = widget.urlPrincipal;
      _mostrarFallback = false;
      _iniciarTiempoCarga();
    }
  }

  @override
  void dispose() {
    _tiempoCarga?.cancel();
    super.dispose();
  }

  void _iniciarTiempoCarga() {
    _tiempoCarga?.cancel();
    _tiempoCarga = Timer(widget.tiempoMaximoCarga, () {
      if (mounted && !_mostrarFallback) _alErrorCarga();
    });
  }

  void _cargaCompletada() {
    _tiempoCarga?.cancel();
  }

  void _alErrorCarga() {
    _cargaCompletada();
    final alt = widget.urlAlternativa;
    if (alt != null && alt != _urlActiva) {
      setState(() {
        _urlActiva = alt;
        _mostrarFallback = false;
      });
      _iniciarTiempoCarga();
      return;
    }
    setState(() => _mostrarFallback = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarFallback) return widget.fallback;

    return ClipOval(
      child: Image.network(
        _urlActiva,
        key: ValueKey(_urlActiva),
        width: widget.tamano,
        height: widget.tamano,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progreso) {
          if (progreso == null) {
            _cargaCompletada();
            return child;
          }
          return SizedBox(
            width: widget.tamano,
            height: widget.tamano,
            child: Center(
              child: SizedBox(
                width: widget.tamano * 0.35,
                height: widget.tamano * 0.35,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progreso.expectedTotalBytes != null
                      ? progreso.cumulativeBytesLoaded /
                          progreso.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _alErrorCarga();
          });
          return SizedBox(width: widget.tamano, height: widget.tamano);
        },
      ),
    );
  }
}
