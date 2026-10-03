import 'package:capsoul/nucleo/supabase/configuracion_supabase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sin variables indica cuáles faltan', () {
    final problema = problemaConfiguracionSupabase(url: '', claveAnonima: ' ');

    expect(problema, contains('SUPABASE_URL y SUPABASE_ANON_KEY'));
    expect(problema, contains('--dart-define-from-file'));
  });

  test('solo falta la clave', () {
    final problema = problemaConfiguracionSupabase(
      url: 'https://mslcdvcmfuqopfwojxvt.supabase.co',
      claveAnonima: '',
    );

    expect(problema, contains('SUPABASE_ANON_KEY'));
    expect(problema, isNot(contains('SUPABASE_URL ')));
  });

  test('rechaza una URL que no es https', () {
    expect(
      problemaConfiguracionSupabase(
        url: 'http://localhost:54321',
        claveAnonima: 'clave',
      ),
      'SUPABASE_URL no es una dirección https válida.',
    );
  });

  test('configuración completa no tiene problemas', () {
    expect(
      problemaConfiguracionSupabase(
        url: 'https://mslcdvcmfuqopfwojxvt.supabase.co',
        claveAnonima: 'clave-publica',
      ),
      isNull,
    );
  });
}
