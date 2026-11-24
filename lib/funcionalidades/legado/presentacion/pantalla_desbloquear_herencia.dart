import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/cabecera_detalle_capsoul.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/componentes/tarjeta_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/formato/fechas.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../aplicacion/proveedores_legado.dart';
import '../dominio/acceso_herencia.dart';
import '../dominio/condicion_herencia.dart';
import '../dominio/estado_herencia.dart';
import '../dominio/herencia.dart';

class PantallaDesbloquearHerencia extends ConsumerStatefulWidget {
  const PantallaDesbloquearHerencia({super.key, required this.herenciaId});

  final String herenciaId;

  @override
  ConsumerState<PantallaDesbloquearHerencia> createState() =>
      _PantallaDesbloquearHerenciaState();
}

class _PantallaDesbloquearHerenciaState
    extends ConsumerState<PantallaDesbloquearHerencia> {
  final _codigoCtrl = TextEditingController();
  bool _validando = false;
  bool _reenviando = false;
  String? _error;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.length != 6) {
      setState(() => _error = 'Escribe los 6 dígitos del código.');
      return;
    }
    setState(() {
      _validando = true;
      _error = null;
    });
    try {
      final resultado = await ref
          .read(proveedorRepositorioLegado)
          .validarCodigoHerencia(widget.herenciaId, codigo);
      if (!mounted) return;
      if (resultado.ok) {
        ref.invalidate(proveedorDetalleHerencia(widget.herenciaId));
        ref.invalidate(proveedorEstadoAccesoHerencia(widget.herenciaId));
        ref.invalidate(proveedorHerenciasACuidado);
        mostrarAvisoInformativo(context, 'Legado desbloqueado.');
        context.pushReplacement(RutasApp.detalleHerenciaDe(widget.herenciaId));
        return;
      }
      setState(() {
        _error = resultado.mensaje ?? _mensajeDeError(resultado.codigoError);
      });
      ref.invalidate(proveedorEstadoAccesoHerencia(widget.herenciaId));
    } catch (e) {
      if (mounted) mostrarAvisoError(context, e);
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    try {
      await ref
          .read(proveedorRepositorioLegado)
          .solicitarCodigoHerencia(widget.herenciaId);
      if (!mounted) return;
      mostrarAvisoInformativo(
        context,
        'Te enviaremos un código nuevo al correo de tu cuenta.',
      );
      ref.invalidate(proveedorEstadoAccesoHerencia(widget.herenciaId));
    } catch (e) {
      if (mounted) mostrarAvisoError(context, e);
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  String _mensajeDeError(String? codigo) {
    switch (codigo) {
      case 'codigo_no_vigente':
        return 'El código no está vigente. Pide uno nuevo.';
      case 'codigo_bloqueado':
        return 'Demasiados intentos. Espera unos minutos.';
      case 'codigo_incorrecto':
        return 'Código incorrecto. Revisa el correo.';
      case 'sin_permiso':
        return 'No tienes permiso para abrir esta herencia.';
      case 'sin_sesion':
        return 'Inicia sesión para desbloquear la herencia.';
      default:
        return 'No pudimos validar el código. Inténtalo de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalle = ref.watch(proveedorDetalleHerencia(widget.herenciaId));
    final estado = ref.watch(proveedorEstadoAccesoHerencia(widget.herenciaId));

    return PantallaCapsoul(
      usarAreaSegura: false,
      cuerpo: Column(
        children: [
          const CabeceraDetalleCapsoul(
            titulo: 'Desbloquear legado',
            subtitulo: 'Un código para cuidar lo que te confiaron',
          ),
          Expanded(
            child: detalle.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Text('No pudimos cargar la herencia.'),
              ),
              data: (d) {
                final estadoAcceso = estado.value ??
                    const EstadoAccesoHerencia(
                      esConfianza: true,
                    );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _EncabezadoHerencia(detalle: d),
                    const SizedBox(height: 16),
                    if (estadoAcceso.accesoActivo)
                      _AccesoActivo(
                        expiraEn: estadoAcceso.accesoExpiraEn,
                        alVer: () => context.pushReplacement(
                          RutasApp.detalleHerenciaDe(widget.herenciaId),
                        ),
                      )
                    else if (d.herencia.estado != EstadoHerencia.liberada)
                      _HerenciaSellada(
                        fecha: d.herencia.fechaActivacion,
                      )
                    else
                      _FormularioCodigo(
                        controlador: _codigoCtrl,
                        validando: _validando,
                        reenviando: _reenviando,
                        error: _error,
                        intentosRestantes: estadoAcceso.intentosRestantes,
                        bloqueadoHasta: estadoAcceso.bloqueadoHasta,
                        alValidar: _validar,
                        alReenviar: _reenviar,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoHerencia extends StatelessWidget {
  const _EncabezadoHerencia({required this.detalle});

  final DetalleHerencia detalle;

  @override
  Widget build(BuildContext context) {
    final h = detalle.herencia;
    final fecha = h.fechaActivacion;
    final textoFecha = h.condicionActivacion == CondicionHerencia.fecha &&
            fecha != null
        ? 'Se abre el ${formatearFechaCorta(fecha)}.'
        : 'Te eligieron como persona de confianza.';
    return TarjetaCapsoul(
      icono: h.estado == EstadoHerencia.liberada
          ? Icons.lock_open_outlined
          : Icons.lock_outline,
      titulo: h.titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            textoFecha,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresApp.atenuado,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Podrás ver el contenido y ayudar a quien recibe la herencia. '
            'La persona que la creó no puede editar su contenido una vez abierta.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.atenuado,
                ),
          ),
        ],
      ),
    );
  }
}

class _HerenciaSellada extends StatelessWidget {
  const _HerenciaSellada({this.fecha});

  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    return TarjetaCapsoul(
      icono: Icons.lock_clock_outlined,
      titulo: 'Todavía no se puede abrir',
      child: Text(
        fecha == null
            ? 'La herencia se abrirá cuando se cumpla la condición indicada. '
                'Ese día recibirás el código en tu correo.'
            : 'La herencia se abre el ${formatearFechaCorta(fecha!)}. '
                'Ese día recibirás el código en el correo de tu cuenta Capsoul.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColoresApp.atenuado,
            ),
      ),
    );
  }
}

class _AccesoActivo extends StatelessWidget {
  const _AccesoActivo({required this.alVer, this.expiraEn});

  final DateTime? expiraEn;
  final VoidCallback alVer;

  @override
  Widget build(BuildContext context) {
    return TarjetaCapsoul(
      icono: Icons.key_outlined,
      titulo: 'Acceso desbloqueado',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            expiraEn == null
                ? 'Ya puedes ver el contenido de esta herencia.'
                : 'Ya puedes ver el contenido. El acceso está vigente hasta '
                    '${formatearFechaCorta(expiraEn!)}.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresApp.atenuado,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: alVer,
            child: const Text('Ver contenido'),
          ),
        ],
      ),
    );
  }
}

class _FormularioCodigo extends StatelessWidget {
  const _FormularioCodigo({
    required this.controlador,
    required this.validando,
    required this.reenviando,
    required this.alValidar,
    required this.alReenviar,
    this.error,
    this.intentosRestantes,
    this.bloqueadoHasta,
  });

  final TextEditingController controlador;
  final bool validando;
  final bool reenviando;
  final VoidCallback alValidar;
  final VoidCallback alReenviar;
  final String? error;
  final int? intentosRestantes;
  final DateTime? bloqueadoHasta;

  @override
  Widget build(BuildContext context) {
    final bloqueado = bloqueadoHasta != null &&
        bloqueadoHasta!.isAfter(DateTime.now());
    return TarjetaCapsoul(
      icono: Icons.mark_email_unread_outlined,
      titulo: 'Ingresa el código',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enviamos un código de 6 dígitos al correo de tu cuenta Capsoul. '
            'Escríbelo aquí para desbloquear la herencia.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresApp.atenuado,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('campo_codigo_herencia'),
            controller: controlador,
            enabled: !bloqueado && !validando,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              errorText: error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              if (!validando && !bloqueado) alValidar();
            },
          ),
          if (intentosRestantes != null && !bloqueado) ...[
            const SizedBox(height: 4),
            Text(
              'Intentos restantes: $intentosRestantes',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ColoresApp.atenuado,
                  ),
            ),
          ],
          if (bloqueado) ...[
            const SizedBox(height: 8),
            Text(
              'Por seguridad, espera unos minutos antes de volver a intentar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: validando || bloqueado ? null : alValidar,
            child: validando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Desbloquear'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: reenviando ? null : alReenviar,
            child: Text(reenviando ? 'Enviando…' : 'Reenviar código'),
          ),
        ],
      ),
    );
  }
}
