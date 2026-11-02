import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
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
import '../dominio/herencia_recibida.dart';
import 'componentes/tarjeta_seguridad_legado.dart';
import 'heroes_legado.dart';

class PantallaLegado extends ConsumerWidget {
  const PantallaLegado({super.key});

  Future<void> _elegirConfianza(BuildContext context, WidgetRef ref) async {
    final amigos = ref.read(proveedorMisAmigos).value ?? const <Amigo>[];
    if (amigos.isEmpty) {
      mostrarAvisoInformativo(
        context,
        'Primero agrega amigos para elegir persona de confianza.',
      );
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
                subtitle: a.nombreUsuario != null
                    ? Text('@${a.nombreUsuario}')
                    : null,
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
          ref.invalidate(proveedorHerenciasRecibidas);
          ref.invalidate(proveedorHerenciasPorConfirmar);
          await Future.wait([
            ref.read(proveedorGruposLegadoBeneficiario.future),
            ref.read(proveedorHerenciasRecibidas.future),
            ref.read(proveedorHerenciasPorConfirmar.future),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Mi legado',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ColoresApp.primario,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.favorite_border,
                          color: ColoresApp.primario,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lo que quieres dejar, organizado y protegido.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: ColoresApp.atenuado),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: TarjetaSeguridadLegado()),
            const SliverToBoxAdapter(child: _BloquePorConfirmar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SegmentedButton<BandejaLegado>(
                  segments: const [
                    ButtonSegment(
                      value: BandejaLegado.creadas,
                      label: Text('Creadas'),
                      icon: Icon(Icons.edit_outlined),
                    ),
                    ButtonSegment(
                      value: BandejaLegado.recibidas,
                      label: Text('Recibidas'),
                      icon: Icon(Icons.inbox_outlined),
                    ),
                  ],
                  selected: {ref.watch(proveedorBandejaLegado)},
                  onSelectionChanged: (s) {
                    ref.read(proveedorBandejaLegado.notifier).elegir(s.first);
                  },
                ),
              ),
            ),
            if (ref.watch(proveedorBandejaLegado) == BandejaLegado.creadas)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Para las personas que amo',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const _BotonNuevaHerencia(),
                    ],
                  ),
                ),
              ),
            if (ref.watch(proveedorBandejaLegado) == BandejaLegado.recibidas)
              const _ListaHerenciasRecibidas()
            else
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
                  leading: const Icon(
                    Icons.description_outlined,
                    color: ColoresApp.primario,
                  ),
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
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
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
    final lista = await ref
        .read(proveedorRepositorioLegado)
        .listarPorBeneficiario(uid);
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
                subtitle: Text(
                  h.etiquetaEstado(ahora: DateTime.now()),
                ),
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

class _BotonNuevaHerencia extends StatefulWidget {
  const _BotonNuevaHerencia();

  @override
  State<_BotonNuevaHerencia> createState() => _EstadoBotonNuevaHerencia();
}

class _EstadoBotonNuevaHerencia extends State<_BotonNuevaHerencia> {
  bool _pulsado = false;

  void _marcar(bool valor) {
    if (_pulsado == valor) return;
    setState(() => _pulsado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _marcar(true),
      onPointerUp: (_) => _marcar(false),
      onPointerCancel: (_) => _marcar(false),
      child: AnimatedScale(
        scale: _pulsado ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Hero(
          tag: HeroesLegado.nuevaHerencia,
          child: Material(
            type: MaterialType.transparency,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
              onPressed: () => context.push(RutasApp.legadoNuevaHerencia),
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            ),
          ),
        ),
      ),
    );
  }
}

class _BloquePorConfirmar extends ConsumerWidget {
  const _BloquePorConfirmar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientes = ref.watch(proveedorHerenciasPorConfirmar);
    return pendientes.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (lista) {
        if (lista.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Te piden confirmar un legado',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'No verás el contenido. Al confirmar, se lo entregamos a quien lo recibe.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: ColoresApp.atenuado),
              ),
              const SizedBox(height: 8),
              for (final h in lista)
                Card(
                  child: ListTile(
                    title: Text(h.titulo),
                    subtitle: Text(
                      '${h.propietarioNombre} → ${h.beneficiarioNombre ?? 'alguien'}',
                    ),
                    trailing: FilledButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(proveedorRepositorioLegado)
                              .confirmarHerencia(h.id);
                          ref.invalidate(proveedorHerenciasPorConfirmar);
                          ref.invalidate(proveedorHerenciasRecibidas);
                          if (context.mounted) {
                            mostrarAvisoInformativo(
                              context,
                              'Legado confirmado. El beneficiario ya puede verlo.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) mostrarAvisoError(context, e);
                        }
                      },
                      child: const Text('Confirmar'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ListaHerenciasRecibidas extends ConsumerWidget {
  const _ListaHerenciasRecibidas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recibidas = ref.watch(proveedorHerenciasRecibidas);
    return recibidas.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No pudimos cargar las herencias recibidas.'),
        ),
      ),
      data: (lista) {
        if (lista.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Cuando alguien te asigne una pequeña herencia, aparecerá aquí.',
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _FilaHerenciaRecibida(herencia: lista[i]),
            childCount: lista.length,
          ),
        );
      },
    );
  }
}

class _FilaHerenciaRecibida extends StatelessWidget {
  const _FilaHerenciaRecibida({required this.herencia});

  final HerenciaRecibida herencia;

  @override
  Widget build(BuildContext context) {
    return _TarjetaFilaLegado(
      child: ListTile(
        leading: Icon(
          herencia.contenidoVisible
              ? Icons.lock_open_outlined
              : Icons.lock_outline,
          color: ColoresApp.primario,
        ),
        title: Text(herencia.titulo),
        subtitle: Text(
          herencia.contenidoVisible
              ? 'De ${herencia.propietarioNombre} · ya puedes verla'
              : 'De ${herencia.propietarioNombre} · sellada',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(RutasApp.detalleHerenciaDe(herencia.id)),
      ),
    );
  }
}

class _TarjetaFilaLegado extends StatelessWidget {
  const _TarjetaFilaLegado({required this.child, this.margenInferior = 10});

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
