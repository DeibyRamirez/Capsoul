import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../inicio/dominio/resumen_inicio.dart';

/// Cabecera estilo Instagram: avatar, estadísticas, bio y botones de acción.
class EncabezadoPerfil extends StatelessWidget {
  const EncabezadoPerfil({
    super.key,
    required this.nombre,
    required this.inicial,
    required this.resumen,
    required this.publicaciones,
    required this.ocupado,
    required this.alEditar,
    required this.alCerrarSesion,
  });

  final String nombre;
  final String inicial;
  final ResumenInicio resumen;
  final int publicaciones;
  final bool ocupado;
  final VoidCallback alEditar;
  final VoidCallback alCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x2E3D6B9A),
            ColoresApp.superficie,
          ],
          stops: [0, 1],
        ),
      ),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: ColoresApp.primario,
                foregroundColor: ColoresApp.sobrePrimario,
                child: Text(
                  inicial,
                  style: estilos.headlineMedium?.copyWith(
                    color: ColoresApp.sobrePrimario,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _Stat(
                        valor: '$publicaciones',
                        etiqueta: 'publicaciones',
                      ),
                      SizedBox(width: 12),
                      _Stat(
                        valor: '${resumen.capsulas}',
                        etiqueta: 'cápsulas',
                      ),
                      SizedBox(width: 12),
                      _Stat(
                        valor: '${resumen.herencias}',
                        etiqueta: 'herencias',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            nombre,
            style: estilos.titleMedium?.copyWith(
              color: ColoresApp.primario,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Guardo hoy lo que alguien amará mañana.',
            style: TextStyle(color: ColoresApp.sobreSuperficie),
          ),
          const SizedBox(height: 8),
          const _LineaBio(
            icono: Icons.landscape_outlined,
            texto: 'Pequeñas herencias, grandes recuerdos',
          ),
          const _LineaBio(
            icono: Icons.grid_view_outlined,
            texto: 'Construyendo cápsoul cada día',
          ),
          const _LineaBio(
            icono: Icons.favorite_outline,
            texto: 'Para quienes más amo',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: ocupado ? null : alEditar,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
                    ),
                  ),
                  child: const Text('Editar perfil'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('boton-cerrar-sesion'),
                onPressed: ocupado ? null : alCerrarSesion,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
                  ),
                ),
                child: const Icon(Icons.logout, size: 20),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ColoresApp.primario,
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 12, color: ColoresApp.atenuado),
        ),
      ],
    );
  }
}

class _LineaBio extends StatelessWidget {
  const _LineaBio({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icono, size: 16, color: ColoresApp.acento),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13,
                color: ColoresApp.sobreSuperficie,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
