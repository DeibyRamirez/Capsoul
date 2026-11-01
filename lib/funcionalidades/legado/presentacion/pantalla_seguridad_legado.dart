import 'package:flutter/material.dart';

import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../nucleo/tema/colores_app.dart';
import 'heroes_legado.dart';

class PantallaSeguridadLegado extends StatelessWidget {
  const PantallaSeguridadLegado({super.key});

  static const _puntos = <_PuntoSeguridad>[
    _PuntoSeguridad(
      icono: Icons.cloud_outlined,
      titulo: 'Medios autenticados',
      cuerpo:
          'Los medios están en Cloudinary con entrega autenticada; las URLs '
          'se firman en el servidor y caducan.',
    ),
    _PuntoSeguridad(
      icono: Icons.lock_outline,
      titulo: 'Solo tú editas',
      cuerpo:
          'Solo tú editas herencias en borrador o activas; la liberación la '
          'hace el servidor (fecha, inactividad o confirmación de confianza).',
    ),
    _PuntoSeguridad(
      icono: Icons.people_outline,
      titulo: 'Persona de confianza',
      cuerpo:
          'La persona de confianza no puede modificar tu legado; solo confirmar '
          'cuando corresponda y ver el contenido tras la liberación.',
    ),
    _PuntoSeguridad(
      icono: Icons.gavel_outlined,
      titulo: 'Respaldo jurídico',
      cuerpo:
          'Puedes solicitar revisión desde el detalle de cada herencia '
          '(equipo Capsoul Legal, proceso manual por ahora).',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PantallaCapsoul(
      usarAreaSegura: false,
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabeceraDetalleCapsoul(
            titulo: 'Seguridad y respaldo',
            subtitulo: 'Cómo protegemos tu legado',
            trailing: const Hero(
              tag: HeroesLegado.seguridad,
              child: Material(
                type: MaterialType.transparency,
                child: Icon(
                  Icons.verified_user_outlined,
                  color: ColoresApp.primario,
                  size: 32,
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: _puntos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, indice) {
                  final punto = _puntos[indice];
                  return TarjetaCapsoul(
                    icono: punto.icono,
                    titulo: punto.titulo,
                    child: Text(
                      punto.cuerpo,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: ColoresApp.atenuado),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PuntoSeguridad {
  const _PuntoSeguridad({
    required this.icono,
    required this.titulo,
    required this.cuerpo,
  });

  final IconData icono;
  final String titulo;
  final String cuerpo;
}
