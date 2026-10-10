import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

/// Servidor mínimo de la API Capsoul. Los endpoints de firma delegan en la
/// misma lógica que las Edge Functions de Supabase (ver supabase/functions/).
Future<void> main(List<String> args) async {
  final puerto = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final app = Router();

  app.get('/health', (_) => Response.ok('ok'));

  app.get('/docs', (_) {
    final spec = File('openapi.yaml').readAsStringSync();
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <title>Capsoul API</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      spec: ${jsonEncode(spec)},
      dom_id: '#swagger-ui',
    });
  </script>
</body>
</html>''';
    return Response.ok(html, headers: {'Content-Type': 'text/html; charset=utf-8'});
  });

  app.post('/v1/medios/firmar-subida', (Request request) async {
    if (!_autenticado(request)) {
      return _error(401, 'no_autenticado', 'Inicia sesión para subir archivos.');
    }
    return Response.ok(
      jsonEncode({
        'codigo': 'no_implementado',
        'mensaje':
            'Conecta Cloudinary aquí (ver supabase/functions/firmar-subida).',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  app.post('/v1/musica/buscar', (Request request) async {
    if (!_autenticado(request)) {
      return _error(401, 'no_autenticado', 'Inicia sesión.');
    }
    return _error(
      501,
      'no_implementado',
      'Configura Spotify en el VPS (ver supabase/functions/buscar-musica).',
    );
  });

  app.post('/v1/medios/firmar-entrega', (Request request) async {
    if (!_autenticado(request)) {
      return _error(401, 'no_autenticado', 'Inicia sesión.');
    }
    return Response.ok(
      jsonEncode({'medios': []}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  app.post('/v1/auth/iniciar-sesion', (Request request) async {
    return _error(
      501,
      'no_implementado',
      'Implementa JWT + Postgres en el VPS (ver docs/migraciones.md).',
    );
  });

  app.post('/v1/auth/registro', (Request request) async {
    return _error(
      501,
      'no_implementado',
      'Implementa registro + perfil en el VPS.',
    );
  });

  final openapi = createStaticHandler('.', defaultDocument: 'openapi.yaml');
  final handler = Cascade().add(app.call).add(openapi).handler;

  final servidor = await shelf_io.serve(handler, '0.0.0.0', puerto);
  stdout.writeln('Capsoul API en http://${servidor.address.host}:${servidor.port}');
  stdout.writeln('Swagger UI: http://localhost:$puerto/docs');
}

bool _autenticado(Request request) {
  final auth = request.headers['authorization'] ?? '';
  return auth.startsWith('Bearer ') && auth.length > 10;
}

Response _error(int estado, String codigo, String mensaje) => Response(
      estado,
      body: jsonEncode({'codigo': codigo, 'mensaje': mensaje}),
      headers: {'Content-Type': 'application/json'},
    );
