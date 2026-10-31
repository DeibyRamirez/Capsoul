/// True si la URL se puede usar con ExoPlayer en Android (HTTPS, no localhost).
bool urlPreviewConfiable(String? url) {
  final texto = url?.trim() ?? '';
  if (texto.isEmpty) return false;
  final uri = Uri.tryParse(texto);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
  if (uri.scheme.toLowerCase() != 'https') return false;
  final host = uri.host.toLowerCase();
  if (host.isEmpty) return false;
  if (host == 'localhost' || host == '127.0.0.1' || host.endsWith('.localhost')) {
    return false;
  }
  return true;
}
