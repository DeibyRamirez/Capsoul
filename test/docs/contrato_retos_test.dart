import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contrato-retos.json trae los 15 seeds y criterios del motor', () {
    final crudo = File('docs/contrato-retos.json').readAsStringSync();
    final json = jsonDecode(crudo) as Map<String, dynamic>;
    final retos = json['retos'] as List<dynamic>;
    final criterios = json['criterios_permitidos'] as List<dynamic>;

    expect(retos, hasLength(15));
    expect(
      retos.map((r) => (r as Map)['slug']).toList(),
      [
        'primer_capsula',
        'nombre_usuario',
        'primer_amigo',
        'foto_con_musica',
        'primer_momento',
        'recuerdo_nota',
        'recuerdo_audio',
        'recuerdo_video',
        'recuerdo_foto',
        'recuerdo_musica',
        'capsula_programada',
        'herencia_borrador',
        'recuerdos_cinco',
        'recuerdos_diez',
        'recuerdos_tres',
      ],
    );
    expect(
      criterios.map((c) => (c as Map)['clave']).toSet(),
      {
        'recuerdo_foto',
        'recuerdo_foto_con_musica',
        'recuerdo_video',
        'recuerdo_audio',
        'recuerdo_nota',
        'recuerdo_musica',
        'primer_capsula',
        'capsula_programada',
        'primer_momento',
        'primer_amigo',
        'nombre_usuario',
        'recuerdos_cantidad',
        'herencia_borrador',
      },
    );
    final cinco = retos.firstWhere(
      (r) => (r as Map)['slug'] == 'recuerdos_cinco',
    ) as Map<String, dynamic>;
    expect(cinco['criterio']['clave'], 'recuerdos_cantidad');
    expect(cinco['criterio']['parametros']['minimo'], 5);
  });
}
