import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avatar_usuario.dart';
import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../amistades/aplicacion/proveedores_amistades.dart';
import '../../amistades/dominio/amigo.dart';
import '../aplicacion/proveedores_legado.dart';
import '../dominio/grupo_legado_beneficiario.dart';
import '../dominio/herencia.dart';
import 'componentes/tarjeta_herencia_recibida.dart';
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mi legado',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: ColoresApp.primario,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColoresApp.primario.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: ColoresApp.primario,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tu historia, con calma y a tu manera.',
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<BandejaLegado>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: ColoresApp.tarjeta,
                    foregroundColor: ColoresApp.primario,
                    selectedBackgroundColor: ColoresApp.primario,
                    selectedForegroundColor: ColoresApp.sobrePrimario,
                    side: const BorderSide(color: ColoresApp.bordeTarjeta),
                    minimumSize: const Size(0, 48),
                    textStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    shape: const StadiumBorder(),
                  ),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Para las personas que amo',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _BotonNuevaHerencia(),
                    ],
                  ),
                ),
              ),
            if (ref.watch(proveedorBandejaLegado) ==
                BandejaLegado.recibidas) ...[
              const SliverToBoxAdapter(child: _EncabezadoRecibidas()),
              const _ListaHerenciasRecibidas(),
            ] else
              grupos.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, _) => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Text(
                      'No pudimos cargar tus herencias.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (lista) {
                  if (lista.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _EstadoVacioCreadas(),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
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
                        ? 'Podrá confirmar la entrega si lo necesitas; no puede editarlo.'
                        : 'Debe ser tu amigo en Capsoul.',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ColoresApp.atenuado,
                  ),
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
                subtitle: Text(h.etiquetaEstado(ahora: DateTime.now())),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        trailing: const Icon(Icons.chevron_right, color: ColoresApp.atenuado),
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
              icon: const Icon(Icons.add, size: 18),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Una llave en tus manos',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'No verás el contenido. Tu aprobación lo entrega a la persona indicada.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: ColoresApp.atenuado),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < lista.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                  child: Card(
                    key: ValueKey(lista[i].id),
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    color: ColoresApp.tarjeta,
                    surfaceTintColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            lista[i].titulo,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lista[i].propietarioNombre} → '
                            '${lista[i].beneficiarioNombre ?? 'alguien'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: ColoresApp.atenuado),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(proveedorRepositorioLegado)
                                    .confirmarHerencia(lista[i].id);
                                ref.invalidate(proveedorHerenciasPorConfirmar);
                                ref.invalidate(proveedorHerenciasRecibidas);
                                if (context.mounted) {
                                  mostrarAvisoInformativo(
                                    context,
                                    'Legado confirmado. El beneficiario ya puede verlo.',
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  mostrarAvisoError(context, e);
                                }
                              }
                            },
                            icon: const Icon(Icons.key_outlined, size: 18),
                            label: const Text('Confirmar entrega'),
                          ),
                        ],
                      ),
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

class _EncabezadoRecibidas extends StatelessWidget {
  const _EncabezadoRecibidas();

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para ti',
            style: estilos.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Lo que otros dejaron a tu cuidado.',
            style: estilos.bodySmall?.copyWith(color: ColoresApp.atenuado),
          ),
        ],
      ),
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
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Text(
            'No pudimos cargar las herencias recibidas.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (lista) {
        if (lista.isEmpty) {
          return const SliverToBoxAdapter(child: _EstadoVacioRecibidas());
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          sliver: SliverList.separated(
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final herencia = lista[i];
              return TarjetaHerenciaRecibida(
                key: ValueKey(herencia.id),
                herencia: herencia,
                alTocar: () =>
                    context.push(RutasApp.detalleHerenciaDe(herencia.id)),
              );
            },
          ),
        );
      },
    );
  }
}

class _EstadoVacioCreadas extends StatelessWidget {
  const _EstadoVacioCreadas();

  @override
  Widget build(BuildContext context) {
    return const _EstadoVacioLegado(
      icono: Icons.edit_note_outlined,
      titulo: 'Aún no has creado herencias',
      mensaje: 'Toca «Nueva» para dejar tu primera historia.',
    );
  }
}

class _EstadoVacioRecibidas extends StatelessWidget {
  const _EstadoVacioRecibidas();

  @override
  Widget build(BuildContext context) {
    return const _EstadoVacioLegado(
      icono: Icons.lock_clock_outlined,
      titulo: 'Todavía no hay herencias',
      mensaje:
          'Cuando alguien te confíe parte de su historia, la encontrarás aquí.',
    );
  }
}

class _EstadoVacioLegado extends StatelessWidget {
  const _EstadoVacioLegado({
    required this.icono,
    required this.titulo,
    required this.mensaje,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ColoresApp.fondoInicio, ColoresApp.tarjeta],
              ),
              border: Border.all(color: ColoresApp.bordeTarjeta),
            ),
            child: Icon(icono, color: ColoresApp.primario, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: estilos.titleSmall?.copyWith(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: estilos.bodySmall?.copyWith(color: ColoresApp.atenuado),
          ),
        ],
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
