import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contrato-retos.json trae los 25 seeds y criterios del motor', () {
    final crudo = File('docs/contrato-retos.json').readAsStringSync();
    final json = jsonDecode(crudo) as Map<String, dynamic>;
    final retos = json['retos'] as List<dynamic>;
    final criterios = json['criterios_permitidos'] as List<dynamic>;

    expect(retos, hasLength(25));
    expect(retos.map((r) => (r as Map)['slug']).toList(), [
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
      'persona_confianza',
      'tres_capsulas',
      'capsula_tres_recuerdos',
      'tres_momentos',
      'momento_tres_recuerdos',
      'herencia_con_capsula',
      'comparte_capsula',
      'recuerdo_con_musica',
      'perfil_con_foto',
      'veinticinco_recuerdos',
    ]);
    expect(criterios.map((c) => (c as Map)['clave']).toSet(), {
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
      'recuerdo_con_musica',
      'recuerdos_cantidad',
      'recuerdos_tipos',
      'capsulas_cantidad',
      'capsula_elementos_cantidad',
      'capsula_compartida',
      'momentos_cantidad',
      'momento_elementos_cantidad',
      'herencia_borrador',
      'herencia_con_capsula',
      'persona_confianza',
      'perfil_con_foto',
    });
    final cinco = retos.firstWhere(
      (r) => (r as Map)['slug'] == 'recuerdos_cinco',
    ) as Map<String, dynamic>;
    expect(cinco['criterio']['clave'], 'recuerdos_cantidad');
    expect(cinco['criterio']['parametros']['minimo'], 5);

    final tresTipos = retos.firstWhere(
      (r) => (r as Map)['slug'] == 'recuerdos_tres',
    ) as Map<String, dynamic>;
    expect(tresTipos['criterio']['clave'], 'recuerdos_tipos');
    expect(tresTipos['criterio']['parametros']['minimo'], 3);

    final metaFinal = retos.last as Map<String, dynamic>;
    expect(metaFinal['slug'], 'veinticinco_recuerdos');
    expect(metaFinal['orden'], 25);
    expect(metaFinal['criterio']['clave'], 'recuerdos_cantidad');
    expect(metaFinal['criterio']['parametros']['minimo'], 25);
  });
}
