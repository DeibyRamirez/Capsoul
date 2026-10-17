import 'package:flutter/material.dart';

class PantallaSeguridadLegado extends StatelessWidget {
  const PantallaSeguridadLegado({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad y respaldo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            Text(
              'Cómo protegemos tu legado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16),
            Text(
              '• Los medios están en Cloudinary con entrega autenticada; las URLs '
              'se firman en el servidor y caducan.\n'
              '• Solo tú editas herencias en borrador o activas; la liberación la '
              'hace el servidor (fecha, inactividad o confirmación de confianza).\n'
              '• La persona de confianza no puede modificar tu legado; solo confirmar '
              'cuando corresponda y ver el contenido tras la liberación.\n'
              '• Respaldo jurídico: puedes solicitar revisión desde el detalle de '
              'cada herencia (equipo Capsoul Legal, proceso manual por ahora).',
            ),
          ],
        ),
      ),
    );
  }
}
