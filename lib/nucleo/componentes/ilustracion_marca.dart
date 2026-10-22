import 'package:flutter/material.dart';

import '../tema/colores_app.dart';

/// Ilustraciones reales de la marca (WebP en `assets/illustrations/`).
///
/// Se decodifican a 1024 px ([cacheWidth]) y se pueden precargar para que
/// el hero no aparezca de golpe.
abstract final class IlustracionesMarca {
  static const String heroCalma = 'assets/illustrations/hero_calm.webp';
  static const String paisajeLago = 'assets/illustrations/landscape_lake.webp';

  /// Lado máximo de decodificación. Los archivos ya miden como mucho 1024 px.
  static const int anchoDecodificado = 1024;

  static ImageProvider proveedor(String ruta) {
    return ResizeImage.resizeIfNeeded(
      anchoDecodificado,
      null,
      AssetImage(ruta),
    );
  }

  static Future<void> precargar(BuildContext context) {
    return Future.wait([
      precacheImage(proveedor(heroCalma), context),
      precacheImage(proveedor(paisajeLago), context),
    ]);
  }
}

/// Precarga el hero y el paisaje una sola vez, en cuanto hay un [BuildContext].
class PrecargaIlustracionesMarca extends StatefulWidget {
  const PrecargaIlustracionesMarca({super.key, required this.child});

  final Widget child;

  @override
  State<PrecargaIlustracionesMarca> createState() =>
      _EstadoPrecargaIlustracionesMarca();
}

class _EstadoPrecargaIlustracionesMarca
    extends State<PrecargaIlustracionesMarca> {
  static bool _pedido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pedido) return;
    _pedido = true;
    IlustracionesMarca.precargar(context).ignore();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Pintura de marca a tamaño de caja, con fundido opcional hacia [superficie].
class IlustracionMarca extends StatelessWidget {
  const IlustracionMarca({
    super.key,
    required this.ruta,
    this.ajuste = BoxFit.cover,
    this.alineacion = Alignment.center,
    this.fundirAbajo = false,
  });

  final String ruta;
  final BoxFit ajuste;
  final Alignment alineacion;

  /// Disuelve el borde inferior en el fondo #F4F8FC.
  final bool fundirAbajo;

  @override
  Widget build(BuildContext context) {
    final imagen = Image(
      image: IlustracionesMarca.proveedor(ruta),
      fit: ajuste,
      alignment: alineacion,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      width: double.infinity,
      height: double.infinity,
      excludeFromSemantics: true,
    );
    if (!fundirAbajo) return imagen;
    return Stack(
      fit: StackFit.expand,
      children: [
        imagen,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.55, 0.82, 1],
              colors: [
                ColoresApp.superficie.withValues(alpha: 0),
                ColoresApp.superficie.withValues(alpha: 0.7),
                ColoresApp.superficie,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
