import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/infraestructura/proveedores_infraestructura.dart';
import 'urls_avatar.dart';

/// Par de URLs para el avatar (principal + respaldo).
typedef UrlsAvatar = ({String principal, String? alternativa});

/// URL firmada del avatar propio. [fotoPublicId] evita llamadas sin foto en BD.
final proveedorUrlsAvatarPerfil =
    FutureProvider.autoDispose.family<UrlsAvatar?, String?>((ref, fotoPublicId) async {
  final id = fotoPublicId?.trim();
  if (id == null || id.isEmpty) return null;
  final medio =
      await ref.read(proveedorClienteFuncionesApi).firmarAvatarPerfil();
  final principal = urlPreferidaAvatar(medio);
  if (principal == null) return null;
  return (
    principal: principal,
    alternativa: urlAlternativaAvatar(medio, principal),
  );
});

/// Compatibilidad: solo la URL principal.
final proveedorUrlAvatarPerfil =
    FutureProvider.autoDispose.family<String?, String?>((ref, fotoPublicId) async {
  final urls =
      await ref.read(proveedorUrlsAvatarPerfil(fotoPublicId).future);
  return urls?.principal;
});

/// URLs firmadas del avatar de otro usuario visible.
final proveedorUrlsAvatarUsuario = FutureProvider.autoDispose
    .family<UrlsAvatar?, ({String usuarioId, String? fotoPublicId})>(
        (ref, clave) async {
  final publicId = clave.fotoPublicId?.trim();
  if (publicId == null || publicId.isEmpty) return null;
  final medios = await ref
      .read(proveedorClienteFuncionesApi)
      .firmarAvataresUsuarios([clave.usuarioId]);
  if (medios.isEmpty) return null;
  final medio = medios.first;
  final principal = urlPreferidaAvatar(medio);
  if (principal == null) return null;
  return (
    principal: principal,
    alternativa: urlAlternativaAvatar(medio, principal),
  );
});

final proveedorUrlAvatarUsuario = FutureProvider.autoDispose
    .family<String?, ({String usuarioId, String? fotoPublicId})>(
        (ref, clave) async {
  final urls = await ref.read(proveedorUrlsAvatarUsuario(clave).future);
  return urls?.principal;
});
