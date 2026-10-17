import 'package:capsoul/funcionalidades/elementos/datos/importador_medios_dispositivo.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/compresor_medios.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/elemento_borrador.dart';
import 'package:capsoul/funcionalidades/elementos/dominio/tipo_elemento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _CompresorFalso extends Mock implements CompresorMedios {}

class _SelectorImagenFalso extends Mock implements ImagePicker {}

void main() {
  late _CompresorFalso compresor;
  late _SelectorImagenFalso selector;

  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
  });

  setUp(() {
    compresor = _CompresorFalso();
    selector = _SelectorImagenFalso();
  });

  test('foto de galería llama prepararFoto sin espejo frontal', () async {
    when(() => selector.pickImage(source: ImageSource.gallery)).thenAnswer(
      (_) async => XFile('/tmp/foto.jpg'),
    );
    when(() => compresor.prepararFoto(any())).thenAnswer(
      (_) async => ElementoBorrador(
        idLocal: 'local-1',
        tipo: TipoElemento.foto,
        rutaArchivo: '/tmp/foto.jpg',
        bytes: 100,
      ),
    );

    final importador = ImportadorMediosDispositivo(compresor, selectorImagen: selector);
    final borrador = await importador.importar(TipoElemento.foto);

    expect(borrador?.tipo, TipoElemento.foto);
    verify(() => compresor.prepararFoto('/tmp/foto.jpg')).called(1);
  });

  test('cancelar galería devuelve null', () async {
    when(() => selector.pickImage(source: ImageSource.gallery))
        .thenAnswer((_) async => null);

    final importador = ImportadorMediosDispositivo(compresor, selectorImagen: selector);
    final borrador = await importador.importar(TipoElemento.foto);

    expect(borrador, isNull);
    verifyNever(() => compresor.prepararFoto(any()));
  });
}
