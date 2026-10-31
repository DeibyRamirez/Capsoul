import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../../nucleo/tema/tema_app.dart';
import '../../../inicio/dominio/resumen_inicio.dart';
import 'avatar_perfil.dart';

/// Cabecera estilo Instagram: avatar, estadísticas, bio y botones de acción.
class EncabezadoPerfil extends StatelessWidget {
  const EncabezadoPerfil({
    super.key,
    required this.nombre,
    this.nombreUsuario,
    required this.inicial,
    required this.resumen,
    required this.publicaciones,
    required this.ocupado,
    required this.alEditar,
    required this.alCerrarSesion,
    this.fotoPublicId,
    this.alTocarAvatar,
  });

  final String nombre;
  final String? nombreUsuario;
  final String inicial;
  final ResumenInicio resumen;
  final int publicaciones;
  final bool ocupado;
  final VoidCallback alEditar;
  final VoidCallback alCerrarSesion;
  final String? fotoPublicId;
  final VoidCallback? alTocarAvatar;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColoresApp.fondoInicio,
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
              AvatarPerfil(
                inicial: inicial,
                fotoPublicId: fotoPublicId,
                alTocar: alTocarAvatar,
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
          Semantics(
            button: true,
            label: 'Editar nombre',
            child: InkWell(
              onTap: ocupado ? null : alEditar,
              borderRadius: BorderRadius.circular(TemaApp.radioPequeno),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: estilos.titleMedium?.copyWith(
                          color: ColoresApp.primario,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: ocupado
                          ? ColoresApp.atenuado
                          : ColoresApp.acento,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (nombreUsuario != null && nombreUsuario!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@$nombreUsuario',
              style: estilos.bodyMedium?.copyWith(color: ColoresApp.atenuado),
            ),
          ],
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
                  child: const Text('Editar nombre'),
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
