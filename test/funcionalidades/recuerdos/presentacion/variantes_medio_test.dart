import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/aplicacion/proveedores_recuerdos.dart';
import 'package:capsoul/funcionalidades/recuerdos/dominio/enlace_medio.dart';
import 'package:capsoul/funcionalidades/recuerdos/presentacion/componentes/miniatura_recuerdo_firmada.dart';
import 'package:capsoul/funcionalidades/recuerdos/presentacion/componentes/reproductores_medio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ayudantes/falsos_recuerdos.dart';

void main() {
  late RepositorioUrlsMedioFalso urls;

  Future<void> montar(WidgetTester tester, Widget hijo) async {
    urls = RepositorioUrlsMedioFalso();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proveedorRepositorioUrlsMedio.overrideWithValue(urls),
          proveedorArchivosMedio.overrideWithValue(ArchivosMedioFalso()),
        ],
        child: MaterialApp(home: Scaffold(body: hijo)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('las miniaturas de listas y rejillas piden solo la miniatura',
      (tester) async {
    final foto = recuerdoPrueba('f1');
    final nota = recuerdoPrueba('n1', tipo: TipoElemento.texto, texto: 'Hola');
    await montar(
      tester,
      Column(
        children: [
          SizedBox(height: 80, child: MiniaturaRecuerdoFirmada(recuerdo: foto)),
          SizedBox(height: 80, child: MiniaturaRecuerdoFirmada(recuerdo: nota)),
        ],
      ),
    );
    expect(urls.pedidos, [claveMedio(foto.publicId!, VarianteMedio.miniatura)]);
  });

  testWidgets('el detalle de la foto pide el original', (tester) async {
    final foto = recuerdoPrueba('f1');
    await montar(tester, FotoCompleta(recuerdo: foto));
    expect(
      urls.pedidos,
      contains(claveMedio(foto.publicId!, VarianteMedio.original)),
    );
  });

  test('solicitudMedioDe: sin miniatura para audio ni notas', () {
    expect(
      solicitudMedioDe(
        recuerdoPrueba('a1', tipo: TipoElemento.audio),
        VarianteMedio.miniatura,
      ),
      isNull,
    );
    expect(
      solicitudMedioDe(
        recuerdoPrueba('n1', tipo: TipoElemento.texto, texto: 'x'),
        VarianteMedio.original,
      ),
      isNull,
    );
  });
}
