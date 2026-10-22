import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/app_bar_capsoul.dart';
import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../nucleo/componentes/pantalla_capsoul.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/espaciado_app.dart';
import '../../../nucleo/tema/movimiento_app.dart';
import '../../../nucleo/tema/tipografia_app.dart';
import 'componentes/animacion_sellado.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../../recuerdos/presentacion/componentes/hoja_nuevo_recuerdo.dart';
import '../../recuerdos/presentacion/pantalla_elegir_recuerdos.dart';
import '../aplicacion/controlador_crear_capsula.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/validador_capsula.dart';
import 'componentes/botones_agregar_elemento.dart';
import 'componentes/elegir_fecha_hora_apertura.dart';
import 'componentes/selector_destinatarios_amigos.dart';
import 'componentes/tarjeta_recuerdo_elegido.dart';

/// Formulario "Nueva cápsula": recuerdos del banco (hasta 10), título,
/// mensaje, fecha de apertura futura y amigo destinatario.
class PantallaCrearCapsula extends ConsumerStatefulWidget {
  const PantallaCrearCapsula({super.key});

  @override
  ConsumerState<PantallaCrearCapsula> createState() =>
      _EstadoPantallaCrearCapsula();
}

class _EstadoPantallaCrearCapsula extends ConsumerState<PantallaCrearCapsula> {
  final _titulo = TextEditingController();
  final _mensaje = TextEditingController();
  var _paso = 0;
  @override
  void dispose() {
    _titulo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  ControladorCrearCapsula get _controlador =>
      ref.read(proveedorControladorCrearCapsula.notifier);

  /// Abre el banco de recuerdos en modo selección.
  Future<void> _elegirDeMisRecuerdos() async {
    final estado = ref.read(proveedorControladorCrearCapsula);
    final elegidos = await context.push<List<Recuerdo>>(
      RutasApp.elegirRecuerdos,
      extra: ParametrosElegirRecuerdos(
        titulo: 'Recuerdos para la cápsula',
        yaElegidos: estado.idsElegidos,
        maximo: estado.disponibles,
      ),
    );
    if (elegidos != null && mounted) _controlador.agregarRecuerdos(elegidos);
  }

  /// Captura un recuerdo nuevo, lo guarda en el banco y lo agrega.
  Future<void> _capturarAhora(TipoElemento tipo) async {
    final recuerdo = await capturarRecuerdo(context, tipo);
    if (recuerdo != null && mounted) _controlador.agregarRecuerdos([recuerdo]);
  }

  Future<void> _elegirFecha() async {
    final ahora = ref.read(proveedorReloj)();
    final actual = ref.read(proveedorControladorCrearCapsula).fechaApertura;
    final elegida = await elegirFechaHoraApertura(
      context,
      ahora: ahora,
      fechaActual: actual,
    );
    if (elegida != null && mounted) _controlador.elegirFecha(elegida);
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final id = await _controlador.guardar(
      titulo: _titulo.text,
      mensaje: _mensaje.text,
    );
    if (id == null || !mounted) return;
    await mostrarAnimacionSellado(context);
    if (!mounted) return;
    mostrarAvisoInformativo(context, 'Tu cápsula quedó guardada.');
    context.pushReplacement(RutasApp.detalleCapsulaDe(id));
  }

  void _siguiente() {
    if (_paso >= 2) return;
    setState(() => _paso += 1);
  }

  void _anterior() {
    if (_paso <= 0) return;
    setState(() => _paso -= 1);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proveedorControladorCrearCapsula, (anterior, siguiente) {
      final error = siguiente.error;
      if (error != null && error != anterior?.error) {
        mostrarAvisoError(context, error);
        _controlador.limpiarError();
      }
    });
    final estado = ref.watch(proveedorControladorCrearCapsula);
    final fecha = estado.fechaApertura;
    final total = estado.recuerdos.length;
    final puedeAgregar = !estado.llena && !estado.guardando;

    return PantallaCapsoul(
      appBar: AppBarCapsoul(titulo: const Text('Nueva cápsula')),
      cuerpo: ListView(
          key: const Key('formulario-capsula'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const _Encabezado(),
            const SizedBox(height: EspaciadoApp.md),
            _Pasos(paso: _paso),
            const SizedBox(height: EspaciadoApp.lg),
            if (_paso == 0) ...[
              _TituloSeccion(
                'Recuerdos ($total/${EstadoCrearCapsula.maximo})',
              ),
              const SizedBox(height: 8),
              for (final recuerdo in estado.recuerdos)
                TarjetaRecuerdoElegido(
                  key: ValueKey(recuerdo.id),
                  recuerdo: recuerdo,
                  alQuitar: estado.guardando
                      ? null
                      : () => _controlador.quitar(recuerdo.id),
                ),
              OutlinedButton.icon(
                key: const Key('boton-elegir-recuerdos'),
                onPressed: puedeAgregar ? _elegirDeMisRecuerdos : null,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir de mis recuerdos'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Capturar ahora',
                style: TextStyle(color: ColoresApp.atenuado),
              ),
              const SizedBox(height: 8),
              BotonesAgregarElemento(
                habilitado: puedeAgregar,
                alElegir: _capturarAhora,
              ),
            ],
            if (_paso == 1) ...[
              TextField(
                key: const Key('campo-titulo'),
                controller: _titulo,
                enabled: !estado.guardando,
                maxLength: ValidadorCapsula.caracteresMaxTitulo,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Para …',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('campo-mensaje'),
                controller: _mensaje,
                enabled: !estado.guardando,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  hintText: 'Cuéntale por qué guardas esto para el futuro',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              SelectorDestinatariosAmigos(
                seleccionados: estado.destinatariosUsuarioIds,
                deshabilitado: estado.guardando,
                alCambiar: _controlador.elegirDestinatarios,
              ),
            ],
            if (_paso == 2) ...[
              Text(
                total == 1
                    ? '1 recuerdo listo para sellar.'
                    : '$total recuerdos listos para sellar.',
                style: TipografiaApp.cuerpo,
              ),
              const SizedBox(height: 12),
              _CampoFecha(
                texto: textoFechaHoraApertura(fecha),
                alTocar: estado.guardando ? null : _elegirFecha,
              ),
              const SizedBox(height: 28),
              BotonPrincipal(
                etiqueta: 'Sellar cápsula',
                cargando: estado.guardando,
                alPresionar: _guardar,
              ),
            ],
            const SizedBox(height: EspaciadoApp.lg),
            Row(
              children: [
                if (_paso > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: estado.guardando ? null : _anterior,
                      child: const Text('Atrás'),
                    ),
                  ),
                if (_paso > 0) const SizedBox(width: 12),
                if (_paso < 2)
                  Expanded(
                    child: FilledButton(
                      onPressed: estado.guardando ? null : _siguiente,
                      child: const Text('Siguiente'),
                    ),
                  ),
              ],
            ),
          ],
        ),
    );
  }
}

class _Pasos extends StatelessWidget {
  const _Pasos({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    const nombres = ['Contenido', 'Para quién', 'Cuándo'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso ${paso + 1} de 3 · ${nombres[paso]}',
          style: TipografiaApp.etiqueta,
        ),
        const SizedBox(height: EspaciadoApp.xs),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: MovimientoApp.rapido,
                  curve: MovimientoApp.curva,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= paso ? ColoresApp.primario : ColoresApp.azul100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Row(
      children: [
        const FrascoLuminoso(tamano: 72, brillo: 0.8),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guarda hoy, abre en el futuro',
                style: estilos.titleMedium?.copyWith(
                  color: ColoresApp.primario,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Elige recuerdos guardados o captura uno nuevo.',
                style: estilos.bodyMedium?.copyWith(color: ColoresApp.atenuado),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: ColoresApp.primario,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Fecha de apertura',
        contentPadding: EdgeInsets.zero,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const Key('campo-fecha'),
          leading:
              const Icon(Icons.lock_clock_outlined, color: ColoresApp.acento),
          title: Text(texto),
          trailing: const Icon(Icons.calendar_month_outlined),
          onTap: alTocar,
        ),
      ),
    );
  }
}

