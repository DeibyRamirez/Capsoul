import 'package:capsoul/nucleo/infraestructura/proveedores/supabase/cliente_postgrest_supabase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('respuestaRpcComoLista', () {
    test('devuelve la lista tal cual', () {
      final lista = [1, {'a': 1}];
      expect(respuestaRpcComoLista(lista), lista);
    });

    test('envuelve un entero escalar', () {
      expect(respuestaRpcComoLista(15), [15]);
    });

    test('null devuelve lista vacía', () {
      expect(respuestaRpcComoLista(null), isEmpty);
    });
  });
}
