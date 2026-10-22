import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/ilustracion_marca.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../amistades/aplicacion/proveedores_amistades.dart';
import '../../amistades/dominio/amigo.dart';
import '../../../nucleo/componentes/avatar_usuario.dart';
import '../aplicacion/proveedores_legado.dart';
import '../dominio/grupo_legado_beneficiario.dart';
import '../dominio/herencia.dart';
import 'componentes/tarjeta_seguridad_legado.dart';

class PantallaLegado extends ConsumerWidget {
  const PantallaLegado({super.key});

  Future<void> _elegirConfianza(BuildContext context, WidgetRef ref) async {
    final amigos = ref.read(proveedorMisAmigos).value ?? const <Amigo>[];
    if (amigos.isEmpty) {
      mostrarAvisoInformativo(context, 'Primero agrega amigos para elegir persona de confianza.');
      return;
    }
    final elegido = await showModalBottomSheet<Amigo>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Elige persona de confianza (@)'),
            ),
            for (final a in amigos)
              ListTile(
                leading: AvatarUsuario(
                  usuarioId: a.usuarioId,
                  nombreVisible: a.nombreVisible,
                  fotoPublicId: a.fotoPublicId,
                ),
                title: Text(a.nombreVisible),
                subtitle: a.nombreUsuario != null ? Text('@${a.nombreUsuario}') : null,
                onTap: () => Navigator.pop(ctx, a),
              ),
          ],
        ),
      ),
    );
    if (elegido?.nombreUsuario == null || !context.mounted) return;
    try {
      await ref
          .read(proveedorRepositorioLegado)
          .establecerPersonaConfianza(elegido!.nombreUsuario!);
      ref.invalidate(proveedorPersonaConfianzaLegadoId);
      if (context.mounted) {
        mostrarAvisoInformativo(context, 'Persona de confianza actualizada.');
      }
    } catch (e) {
      if (context.mounted) mostrarAvisoError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grupos = ref.watch(proveedorGruposLegadoBeneficiario);
    final confianzaId = ref.watch(proveedorPersonaConfianzaLegadoId);
    final amigos = ref.watch(proveedorMisAmigos).value ?? const <Amigo>[];
    Amigo? confianza;
    final idConf = confianzaId.value;
    if (idConf != null) {
      for (final a in amigos) {
        if (a.usuarioId == idConf) {
          confianza = a;
          break;
        }
      }
    }

    return PantallaCapsoul(
      cuerpo: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(proveedorGruposLegadoBeneficiario);
          ref.invalidate(proveedorResumenLegado);
          ref.invalidate(proveedorPersonaConfianzaLegadoId);
          ref.invalidate(proveedorInstruccionesLegado);
          await ref.read(proveedorGruposLegadoBeneficiario.future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: IlustracionMarca(
                  ruta: IlustracionesMarca.paisajeLago,
                  fundirAbajo: true,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Mi legado',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ColoresApp.primario,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite_border, color: ColoresApp.primario),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lo que quieres dejar, organizado y protegido.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ColoresApp.atenuado,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: TarjetaSeguridadLegado()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Para las personas que amo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(RutasApp.legadoNuevaHerencia),
                      child: const Text('Nueva'),
                    ),
                  ],
                ),
              ),
            ),
            grupos.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, _) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No pudimos cargar tu legado.'),
                ),
              ),
              data: (lista) {
                if (lista.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aún no has creado herencias. Toca «Nueva» para empezar.',
                        style: TextStyle(color: ColoresApp.atenuado),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _FilaBeneficiario(grupo: lista[i]),
                    childCount: lista.length,
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: _TarjetaFilaLegado(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined, color: ColoresApp.primario),
                  title: const Text('Mis instrucciones'),
                  subtitle: const Text('Lo que quiero que sepan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RutasApp.legadoInstrucciones),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Mi persona de confianza',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _TarjetaFilaLegado(
                margenInferior: 24,
                child: ListTile(
                  leading: confianza != null
                      ? AvatarUsuario(
                          usuarioId: confianza.usuarioId,
                          nombreVisible: confianza.nombreVisible,
                          fotoPublicId: confianza.fotoPublicId,
                        )
                      : const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(confianza?.nombreVisible ?? 'Elegir por @'),
                  subtitle: Text(
                    confianza != null
                        ? 'Podrá confirmar tu legado si lo necesitas; no puede editarlo.'
                        : 'Debe ser tu amigo en Capsoul.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _elegirConfianza(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaBeneficiario extends ConsumerWidget {
  const _FilaBeneficiario({required this.grupo});

  final GrupoLegadoBeneficiario grupo;

  Future<void> _abrir(BuildContext context, WidgetRef ref) async {
    final uid = grupo.beneficiarioUsuarioId;
    if (uid == null) return;
    final lista = await ref.read(proveedorRepositorioLegado).listarPorBeneficiario(uid);
    if (!context.mounted) return;
    if (lista.isEmpty) {
      context.push(RutasApp.legadoNuevaHerencia);
      return;
    }
    if (lista.length == 1) {
      context.push(RutasApp.detalleHerenciaDe(lista.first.id));
      return;
    }
    final elegida = await showModalBottomSheet<Herencia>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final h in lista)
              ListTile(
                title: Text(h.titulo),
                onTap: () => Navigator.pop(ctx, h),
              ),
          ],
        ),
      ),
    );
    if (elegida != null && context.mounted) {
      context.push(RutasApp.detalleHerenciaDe(elegida.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = grupo.beneficiarioUsuarioId;
    return _TarjetaFilaLegado(
      child: ListTile(
        leading: uid != null
            ? AvatarUsuario(
                usuarioId: uid,
                nombreVisible: grupo.nombreVisible ?? '?',
                fotoPublicId: grupo.fotoPublicId,
              )
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(grupo.etiquetaPara()),
        subtitle: Text(
          '${grupo.nHerencias} herencia${grupo.nHerencias == 1 ? '' : 's'} · '
          '${grupo.nCapsulas} cápsula${grupo.nCapsulas == 1 ? '' : 's'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _abrir(context, ref),
      ),
    );
  }
}

class _TarjetaFilaLegado extends StatelessWidget {
  const _TarjetaFilaLegado({
    required this.child,
    this.margenInferior = 10,
  });

  final Widget child;
  final double margenInferior;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, margenInferior),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: ColoresApp.tarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TemaApp.radioGrande),
          side: const BorderSide(color: ColoresApp.bordeTarjeta),
        ),
        child: child,
      ),
    );
  }
}
