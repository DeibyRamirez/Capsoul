import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:capsoul/funcionalidades/recuerdos/aplicacion/proveedores_recuerdos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const borrador = ElementoBorrador(
    idLocal: 'local-1',
    tipo: TipoElemento.video,
    rutaArchivo: '/tmp/video.mp4',
    bytes: 100,
  );

  group('borradorParaGuardarRecuerdo', () {
    test('prefiere extra cuando es ElementoBorrador', () {
      const otro = ElementoBorrador(
        idLocal: 'local-2',
        tipo: TipoElemento.foto,
        bytes: 1,
      );
      expect(
        borradorParaGuardarRecuerdo(extra: borrador, pendiente: otro),
        borrador,
      );
    });

    test('usa pendiente si extra no es borrador', () {
      expect(
        borradorParaGuardarRecuerdo(extra: null, pendiente: borrador),
        borrador,
      );
      expect(
        borradorParaGuardarRecuerdo(extra: 'otro', pendiente: borrador),
        borrador,
      );
    });

    test('devuelve null sin extra ni pendiente', () {
      expect(
        borradorParaGuardarRecuerdo(extra: null, pendiente: null),
        isNull,
      );
    });
  });

  test('proveedorBorradorRecuerdoPendiente guarda y limpia', () {
    final container = ProviderContainer();
    final notifier =
        container.read(proveedorBorradorRecuerdoPendiente.notifier);

    expect(container.read(proveedorBorradorRecuerdoPendiente), isNull);
    notifier.establecer(borrador);
    expect(container.read(proveedorBorradorRecuerdoPendiente), borrador);
    notifier.limpiar();
    expect(container.read(proveedorBorradorRecuerdoPendiente), isNull);
    container.dispose();
  });
}
