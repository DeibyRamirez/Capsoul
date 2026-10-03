import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../nucleo/componentes/avisos_emergentes.dart';
import '../../../nucleo/componentes/boton_principal.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../dominio/elemento_borrador.dart';
import '../dominio/limites_medios.dart';
import '../dominio/tipo_elemento.dart';
import '../dominio/validador_medios.dart';

/// Nota de texto (hasta 5000 caracteres). Devuelve un [ElementoBorrador]
/// con `Navigator.pop`.
class PantallaEscribirNota extends StatefulWidget {
  const PantallaEscribirNota({super.key});

  @override
  State<PantallaEscribirNota> createState() => _EstadoPantallaEscribirNota();
}

class _EstadoPantallaEscribirNota extends State<PantallaEscribirNota> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _guardar() {
    final texto = _texto.text.trim();
    final fallo = ValidadorMedios.validarNota(texto);
    if (fallo != null) {
      mostrarAvisoError(context, fallo);
      return;
    }
    Navigator.of(context).pop(
      ElementoBorrador(
        idLocal: ElementoBorrador.nuevoIdLocal(),
        tipo: TipoElemento.texto,
        texto: texto,
        bytes: utf8.encode(texto).length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nota')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('campo-nota'),
                  controller: _texto,
                  autofocus: true,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: const [LimitadorCaracteres()],
                  decoration: const InputDecoration(
                    hintText: 'Escribe una nota o una carta para el futuro…',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _texto,
                builder: (context, valor, _) => Text(
                  '${contarCaracteres(valor.text)} / '
                  '${LimitesMedios.caracteresMaxNota}',
                  textAlign: TextAlign.end,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: ColoresApp.atenuado),
                ),
              ),
              const SizedBox(height: 12),
              BotonPrincipal(etiqueta: 'Guardar nota', alPresionar: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}

/// Corta el texto en [LimitesMedios.caracteresMaxNota] caracteres contados
/// como Postgres (`char_length`).
class LimitadorCaracteres extends TextInputFormatter {
  const LimitadorCaracteres();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    if (contarCaracteres(nuevo.text) <= LimitesMedios.caracteresMaxNota) {
      return nuevo;
    }
    final recortado = String.fromCharCodes(
      nuevo.text.runes.take(LimitesMedios.caracteresMaxNota),
    );
    return TextEditingValue(
      text: recortado,
      selection: TextSelection.collapsed(offset: recortado.length),
    );
  }
}
