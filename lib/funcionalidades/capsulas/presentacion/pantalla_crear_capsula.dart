import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/componentes/frasco_luminoso.dart';
import '../../../nucleo/enrutador/rutas_app.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../elementos/dominio/elemento_borrador.dart';
import '../../elementos/dominio/limites_medios.dart';
import '../../elementos/dominio/tipo_elemento.dart';
import '../aplicacion/controlador_crear_capsula.dart';
import '../aplicacion/proveedores_capsulas.dart';
import '../dominio/apertura_capsula.dart';
import '../dominio/validador_capsula.dart';
import 'componentes/botones_agregar_elemento.dart';
import 'componentes/tarjeta_elemento_borrador.dart';

/// Formulario "Nueva cápsula": recuerdos (hasta 10), título, mensaje, fecha
/// de apertura futura y destinatario (próximamente).
class PantallaCrearCapsula extends ConsumerStatefulWidget {
  const PantallaCrearCapsula({super.key, this.elementoInicial});

  /// Elemento capturado desde el selector de Crear.
  final ElementoBorrador? elementoInicial;

  @override
  ConsumerState<PantallaCrearCapsula> createState() =>
      _EstadoPantallaCrearCapsula();
}

class _EstadoPantallaCrearCapsula extends ConsumerState<PantallaCrearCapsula> {
  final _titulo = TextEditingController();
  final _mensaje = TextEditingController();

  @override
  void initState() {
    super.initState();
    final inicial = widget.elementoInicial;
    if (inicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controlador.agregarElemento(inicial);
      });
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  ControladorCrearCapsula get _controlador =>
      ref.read(proveedorControladorCrearCapsula.notifier);

  static String _rutaCaptura(TipoElemento tipo) => switch (tipo) {
        TipoElemento.foto => RutasApp.crearFoto,
        TipoElemento.video => RutasApp.crearVideo,
        TipoElemento.audio => RutasApp.crearAudio,
        TipoElemento.texto => RutasApp.crearEscribir,
      };

  Future<void> _agregar(TipoElemento tipo) async {
    final elemento = await context.push<ElementoBorrador>(_rutaCaptura(tipo));
    if (elemento != null && mounted) _controlador.agregarElemento(elemento);
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
    final total = estado.elementos.length;

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
              'Recuerdos ($total/${LimitesMedios.elementosMaxPorCapsula})',
            ),
            const SizedBox(height: 8),
            for (final elemento in estado.elementos)
              TarjetaElementoBorrador(
                key: ValueKey(elemento.idLocal),
                elemento: elemento,
                alQuitar: estado.guardando
                    ? null
                    : () => _controlador.quitarElemento(elemento.idLocal),
              ),
            BotonesAgregarElemento(
              habilitado: !estado.llena && !estado.guardando,
              alElegir: _agregar,
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
            if (estado.guardando) ...[
              const SizedBox(height: 12),
              Text(
                'Guardando ${estado.guardados} de $total recuerdos…',
                textAlign: TextAlign.center,
                style: const TextStyle(color: ColoresApp.atenuado),
              ),
            ],
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
                'Agrega fotos, videos, notas de voz o notas.',
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
