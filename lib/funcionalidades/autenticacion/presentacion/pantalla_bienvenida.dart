import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/ilustracion_capsoul.dart';
import '../../../nucleo/componentes/ilustracion_marca.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/espaciado_app.dart';
import '../../../nucleo/tema/tipografia_app.dart';

/// Tres pasos: guardar, sellar y dejar un legado.
class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _EstadoPantallaBienvenida();
}

class _EstadoPantallaBienvenida extends State<PantallaBienvenida> {
  final _controlador = PageController();
  var _pagina = 0;

  static const _pasos = [
    _PasoBienvenida(
      ilustracion: NombresIlustracion.onboarding1,
      icono: Icons.photo_outlined,
      titulo: 'Guarda lo que importa',
      texto: 'Una foto, una voz, una nota. Hoy cabe en un recuerdo.',
    ),
    _PasoBienvenida(
      ilustracion: NombresIlustracion.onboarding2,
      icono: Icons.lock_outline,
      titulo: 'Sella una cápsula',
      texto: 'Elige el día en que alguien —o tú— la va a abrir.',
    ),
    _PasoBienvenida(
      ilustracion: NombresIlustracion.onboarding3,
      rutaMarca: IlustracionesMarca.paisajeLago,
      icono: Icons.favorite_border,
      titulo: 'Deja un legado',
      texto: 'Una carta, una llave, algo pequeño para quien más quieres.',
    ),
  ];

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _cerrar() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RutasApp.iniciarSesion);
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = _pagina == _pasos.length - 1;
    return PantallaCapsoul(
      cuerpo: Padding(
        padding: const EdgeInsets.fromLTRB(
          EspaciadoApp.pantalla,
          EspaciadoApp.md,
          EspaciadoApp.pantalla,
          EspaciadoApp.lg,
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _cerrar,
                child: const Text('Saltar'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controlador,
                itemCount: _pasos.length,
                onPageChanged: (pagina) => setState(() => _pagina = pagina),
                itemBuilder: (context, indice) => _pasos[indice],
              ),
            ),
            const SizedBox(height: EspaciadoApp.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pasos.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _Punto(activo: i == _pagina),
                  ),
              ],
            ),
            const SizedBox(height: EspaciadoApp.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!ultimo) {
                    _controlador.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                    return;
                  }
                  context.go(RutasApp.registro);
                },
                child: Text(ultimo ? 'Crear cuenta' : 'Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasoBienvenida extends StatelessWidget {
  const _PasoBienvenida({
    required this.ilustracion,
    required this.icono,
    required this.titulo,
    required this.texto,
    this.rutaMarca,
  });

  final String ilustracion;
  final IconData icono;
  final String titulo;
  final String texto;

  /// Acuarela real. Si falta, se usa el hueco PNG [ilustracion].
  final String? rutaMarca;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (rutaMarca != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 240,
              height: 240,
              child: IlustracionMarca(ruta: rutaMarca!),
            ),
          )
        else
          IlustracionCapsoul(
            nombre: ilustracion,
            ancho: 220,
            alto: 180,
            fallback: Icon(icono, size: 72, color: ColoresApp.primario),
          ),
        const SizedBox(height: EspaciadoApp.lg),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TipografiaApp.titular,
        ),
        const SizedBox(height: EspaciadoApp.sm),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: TipografiaApp.cuerpoPequeno,
        ),
      ],
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: activo ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: activo ? ColoresApp.primario : ColoresApp.azul100,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
