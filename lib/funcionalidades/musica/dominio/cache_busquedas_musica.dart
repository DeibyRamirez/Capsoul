import 'referencia_musica.dart';

/// Consulta lista para usarla como llave: minúsculas, sin espacios al
/// inicio ni al final y con los espacios internos reducidos a uno.
String normalizarConsultaMusica(String consulta) =>
    consulta.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Búsquedas de música guardadas en la memoria del teléfono.
///
/// La llave es la consulta normalizada. Cada entrada dura [vigencia] y,
/// al pasar de [maximoEntradas], se borran las más viejas. No guarda la
/// URL del preview: caduca, y al reproducir se pide `/track/<id>`.
class CacheBusquedasMusica {
  CacheBusquedasMusica({
    DateTime Function()? reloj,
    this.vigencia = vigenciaPorDefecto,
    this.maximoEntradas = maximoPorDefecto,
  }) : _reloj = reloj ?? DateTime.now;

  static const vigenciaPorDefecto = Duration(minutes: 15);
  static const maximoPorDefecto = 50;

  final DateTime Function() _reloj;
  final Duration vigencia;
  final int maximoEntradas;

  /// Orden de inserción: la primera llave es la más vieja.
  final Map<String, _EntradaCacheBusqueda> _entradas = {};

  /// Entradas que siguen vigentes. Las vencidas se quitan.
  int get cantidad {
    _quitarVencidas();
    return _entradas.length;
  }

  /// Resultados vigentes, o null si no hay o ya vencieron.
  List<ReferenciaMusica>? obtener(String consulta) {
    final clave = normalizarConsultaMusica(consulta);
    if (clave.isEmpty) return null;
    final entrada = _entradas[clave];
    if (entrada == null) return null;
    if (!_sigueVigente(entrada)) {
      _entradas.remove(clave);
      return null;
    }
    return entrada.resultados;
  }

  /// Guarda los metadatos sin la URL del preview.
  void guardar(String consulta, List<ReferenciaMusica> resultados) {
    final clave = normalizarConsultaMusica(consulta);
    if (clave.isEmpty) return;
    _quitarVencidas();
    // Reinsertar deja la consulta como la más reciente.
    _entradas.remove(clave);
    _entradas[clave] = _EntradaCacheBusqueda(
      guardadaEn: _reloj(),
      resultados: List.unmodifiable([
        for (final pista in resultados) pista.sinUrlDePreview(),
      ]),
    );
    while (_entradas.length > maximoEntradas) {
      _entradas.remove(_entradas.keys.first);
    }
  }

  void vaciar() => _entradas.clear();

  void _quitarVencidas() {
    _entradas.removeWhere((_, entrada) => !_sigueVigente(entrada));
  }

  bool _sigueVigente(_EntradaCacheBusqueda entrada) =>
      _reloj().difference(entrada.guardadaEn) < vigencia;
}

class _EntradaCacheBusqueda {
  const _EntradaCacheBusqueda({
    required this.guardadaEn,
    required this.resultados,
  });

  final DateTime guardadaEn;
  final List<ReferenciaMusica> resultados;
}
