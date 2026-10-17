import 'package:url_launcher/url_launcher.dart';

/// Abre la pista en Spotify (app si está instalada, si no en el navegador).
Future<bool> abrirEnSpotify({
  required String urlCompleta,
  String? uriProfundo,
}) async {
  if (uriProfundo != null && uriProfundo.startsWith('spotify:')) {
    final uriApp = Uri.parse(uriProfundo);
    if (await canLaunchUrl(uriApp)) {
      return launchUrl(uriApp, mode: LaunchMode.externalApplication);
    }
  }
  final uriWeb = Uri.parse(urlCompleta);
  return launchUrl(uriWeb, mode: LaunchMode.externalApplication);
}
