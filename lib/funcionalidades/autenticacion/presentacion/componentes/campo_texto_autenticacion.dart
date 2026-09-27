import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';

/// Campo de formulario con el tema de Capsoul. Los campos de contraseña
/// incluyen un botón para mostrar u ocultar el texto.
class CampoTextoAutenticacion extends StatefulWidget {
  const CampoTextoAutenticacion({
    super.key,
    required this.controlador,
    required this.etiqueta,
    required this.icono,
    this.validador,
    this.tipoTeclado,
    this.accionTeclado = TextInputAction.next,
    this.esContrasena = false,
    this.habilitado = true,
    this.pistasAutocompletado,
    this.capitalizacion = TextCapitalization.none,
    this.alEnviar,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final IconData icono;
  final FormFieldValidator<String>? validador;
  final TextInputType? tipoTeclado;
  final TextInputAction accionTeclado;
  final bool esContrasena;
  final bool habilitado;
  final Iterable<String>? pistasAutocompletado;
  final TextCapitalization capitalizacion;
  final ValueChanged<String>? alEnviar;

  @override
  State<CampoTextoAutenticacion> createState() =>
      _EstadoCampoTextoAutenticacion();
}

class _EstadoCampoTextoAutenticacion extends State<CampoTextoAutenticacion> {
  late bool _oculto = widget.esContrasena;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      validator: widget.validador,
      keyboardType: widget.tipoTeclado,
      textInputAction: widget.accionTeclado,
      obscureText: _oculto,
      enableSuggestions: !widget.esContrasena,
      autocorrect: false,
      enabled: widget.habilitado,
      autofillHints: widget.pistasAutocompletado,
      textCapitalization: widget.capitalizacion,
      onFieldSubmitted: widget.alEnviar,
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        prefixIcon: Icon(widget.icono, color: ColoresApp.acento),
        suffixIcon: widget.esContrasena
            ? IconButton(
                tooltip: _oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(
                  _oculto
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: ColoresApp.atenuado,
                ),
                onPressed: () => setState(() => _oculto = !_oculto),
              )
            : null,
      ),
    );
  }
}
