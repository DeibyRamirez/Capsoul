import '../../recuerdos/dominio/url_medio.dart';

/// URL preferida para mostrar un avatar (original antes que miniatura eager).
String? urlPreferidaAvatar(UrlMedio? medio) =>
    medio?.url ?? medio?.urlMiniatura;

/// URL alternativa si la preferida falla al cargar.
String? urlAlternativaAvatar(UrlMedio? medio, String urlPreferida) {
  if (medio == null) return null;
  final original = medio.url;
  final mini = medio.urlMiniatura;
  if (urlPreferida == original) return mini;
  if (urlPreferida == mini) return original;
  return null;
}
