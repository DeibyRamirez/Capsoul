import 'package:capsoul/nucleo/arranque/app_error_arranque.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el mensaje por defecto', (tester) async {
    await tester.pumpWidget(const AppErrorArranque());

    expect(find.text('No pudimos iniciar Capsoul'), findsOneWidget);
    expect(find.text(kMensajeErrorArranque), findsOneWidget);
  });

  testWidgets('muestra el detalle de la configuración faltante',
      (tester) async {
    await tester.pumpWidget(
      const AppErrorArranque(detalle: 'Falta la configuración del servidor.'),
    );

    expect(find.text('Falta la configuración del servidor.'), findsOneWidget);
    expect(find.text(kMensajeErrorArranque), findsNothing);
  });
}
