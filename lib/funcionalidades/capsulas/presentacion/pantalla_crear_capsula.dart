import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../../recuerdos/dominio/recuerdo.dart';
import '../../recuerdos/presentacion/componentes/hoja_nuevo_recuerdo.dart';
import '../../recuerdos/presentacion/pantalla_elegir_recuerdos.dart';
import '../aplicacion/controlador_crear_capsula.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/apertura_capsula.dart';
import '../dominio/validador_capsula.dart';
import 'componentes/botones_agregar_elemento.dart';
import 'componentes/tarjeta_recuerdo_elegido.dart';

/// Formulario "Nueva cápsula": recuerdos del banco (hasta 10), título,
/// mensaje, fecha de apertura futura y destinatario (próximamente).
class PantallaCrearCapsula extends ConsumerStatefulWidget {
  const PantallaCrearCapsula({super.key});

  @override
  ConsumerState<PantallaCrearCapsula> createState() =>
      _EstadoPantallaCrearCapsula();
}

class _EstadoPantallaCrearCapsula extends ConsumerState<PantallaCrearCapsula> {
  final _titulo = TextEditingController();
  final _mensaje = TextEditingController();

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
    final primerDia = ValidadorCapsula.primerDiaSeleccionable(ahora);
    final actual = ref.read(proveedorControladorCrearCapsula).fechaApertura;
    final elegida = await showDatePicker(
      context: context,
      helpText: 'Fecha de apertura',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
      firstDate: primerDia,
      lastDate: DateTime(ahora.year + 100, 12, 31),
      initialDate: actual ?? DateTime(ahora.year + 1, ahora.month, ahora.day),
    );
    if (elegida == null || !mounted) return;
    // Se abre a las 8:00 (hora local) del día elegido.
    _controlador.elegirFecha(
      DateTime(elegida.year, elegida.month, elegida.day, 8),
    );
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final id = await _controlador.guardar(
      titulo: _titulo.text,
      mensaje: _mensaje.text,
    );
    if (id == null || !mounted) return;
    mostrarAvisoInformativo(context, 'Tu cápsula quedó guardada.');
    context.pushReplacement(RutasApp.detalleCapsulaDe(id));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva cápsula')),
      body: SafeArea(
        child: ListView(
          key: const Key('formulario-capsula'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const _Encabezado(),
            const SizedBox(height: 20),
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
            const SizedBox(height: 24),
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
            _CampoFecha(
              texto: fecha == null
                  ? 'Elige cuándo se abrirá'
                  : 'Se abrirá el ${formatearFechaCorta(fecha)}',
              alTocar: estado.guardando ? null : _elegirFecha,
            ),
            const SizedBox(height: 16),
            const _CampoDestinatario(),
            const SizedBox(height: 28),
            BotonPrincipal(
              etiqueta: 'Guardar cápsula',
              cargando: estado.guardando,
              alPresionar: _guardar,
            ),
          ],
        ),
      ),
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
      child: ListTile(
        key: const Key('campo-fecha'),
        leading: const Icon(Icons.lock_clock_outlined, color: ColoresApp.acento),
        title: Text(texto),
        trailing: const Icon(Icons.calendar_month_outlined),
        onTap: alTocar,
      ),
    );
  }
}

class _CampoDestinatario extends StatelessWidget {
  const _CampoDestinatario();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      key: Key('campo-destinatario'),
      enabled: false,
      decoration: InputDecoration(
        labelText: 'Destinatario',
        hintText: 'Correo o persona de Capsoul',
        prefixIcon: Icon(Icons.person_outline),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 8),
          child: Chip(
            label: Text('Próximamente'),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}
