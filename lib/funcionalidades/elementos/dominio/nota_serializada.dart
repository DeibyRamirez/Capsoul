import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';
import 'nota_delta.dart';

const _inicioFrontMatter = '---capsoul\n';
const _finFrontMatter = '\n---\n';

/// Metadatos visuales de una nota (fondo y fuente).
class EstiloNota {
  const EstiloNota({this.fondo = 'pastelAzul', this.fuente = 'poppins'});

  final String fondo;
  final String fuente;

  Color colorFondo() {
    return switch (fondo) {
      'pastelRosa' => ColoresApp.pastelRosa,
      'pastelVerde' => ColoresApp.pastelVerde,
      'pastelLila' => ColoresApp.pastelRosa,
      'pastelArena' => ColoresApp.pastelVerde,
      _ => ColoresApp.pastelAzul,
    };
  }

  bool esPlayfair() => fuente == 'playfair';

  Map<String, String> aMapa() => {'fondo': fondo, 'fuente': fuente};

  static EstiloNota desdeMapa(Map<String, dynamic> mapa) {
    return EstiloNota(
      fondo: mapa['fondo'] is String ? mapa['fondo'] as String : 'pastelAzul',
      fuente: mapa['fuente'] is String ? mapa['fuente'] as String : 'poppins',
    );
  }
}

/// Nota con cuerpo visible, estilo y, si es enriquecida, un Delta de Quill.
///
/// `cuerpo` siempre es texto plano para las notas nuevas. Las notas antiguas
/// pueden traer Markdown en el cuerpo; se siguen mostrando con el renderer
/// anterior y se convierten a Delta cuando se editan.
class NotaSerializada {
  const NotaSerializada({
    required this.estilo,
    required this.cuerpo,
    this.delta,
  });

  final EstiloNota estilo;
  final String cuerpo;
  final List<Map<String, dynamic>>? delta;

  bool get esRica => delta != null;

  /// Representación JSONB que se guarda en `elementos.contenido_rico`.
  Map<String, dynamic>? get contenidoRico {
    final delta = this.delta;
    if (delta == null) return null;
    return {'version': 1, 'estilo': estilo.aMapa(), 'delta': delta};
  }

  /// Columnas de `elementos` para persistir la nota.
  Map<String, dynamic> aColumnas() => {
    'contenido_texto': cuerpo,
    if (contenidoRico != null) 'contenido_rico': contenidoRico,
  };

  /// Texto listo para guardar temporalmente en el flujo de crear/editar.
  String serializar() {
    final meta = jsonEncode({
      'v': 2,
      'fondo': estilo.fondo,
      'fuente': estilo.fuente,
      if (delta != null) 'delta': delta,
    });
    return '$_inicioFrontMatter$meta$_finFrontMatter$cuerpo';
  }

  /// Lee el payload temporal que devuelve la pantalla de nota.
  static NotaSerializada parse(String? almacenado) {
    final texto = almacenado ?? '';
    if (!texto.startsWith(_inicioFrontMatter)) {
      return NotaSerializada(estilo: const EstiloNota(), cuerpo: texto);
    }
    final fin = texto.indexOf(_finFrontMatter);
    if (fin < 0) {
      return NotaSerializada(estilo: const EstiloNota(), cuerpo: texto);
    }
    final jsonRaw = texto.substring(_inicioFrontMatter.length, fin);
    final cuerpo = texto.substring(fin + _finFrontMatter.length);
    try {
      final mapa = jsonDecode(jsonRaw) as Map<String, dynamic>;
      final deltaRaw = mapa['delta'];
      return NotaSerializada(
        estilo: EstiloNota.desdeMapa(mapa),
        cuerpo: cuerpo,
        delta: deltaRaw is List && deltaRaw.isNotEmpty
            ? deltaDesdeJson(deltaRaw)
            : null,
      );
    } catch (_) {
      return NotaSerializada(estilo: const EstiloNota(), cuerpo: cuerpo);
    }
  }

  /// Lee una fila de `elementos`: texto plano + JSONB enriquecido.
  factory NotaSerializada.desdeColumnas({
    String? contenidoTexto,
    Object? contenidoRico,
  }) {
    if (contenidoRico is Map) {
      final mapa = Map<String, dynamic>.from(contenidoRico);
      final deltaRaw = mapa['delta'];
      if (deltaRaw is List && deltaRaw.isNotEmpty) {
        final estiloRaw = mapa['estilo'];
        final estilo = estiloRaw is Map
            ? EstiloNota.desdeMapa(Map<String, dynamic>.from(estiloRaw))
            : const EstiloNota();
        final delta = deltaDesdeJson(deltaRaw);
        return NotaSerializada(
          estilo: estilo,
          cuerpo: contenidoTexto ?? textoPlanoDesdeDelta(delta),
          delta: delta,
        );
      }
    }
    if (contenidoRico is List && contenidoRico.isNotEmpty) {
      final delta = deltaDesdeJson(contenidoRico);
      return NotaSerializada(
        estilo: const EstiloNota(),
        cuerpo: contenidoTexto ?? textoPlanoDesdeDelta(delta),
        delta: delta,
      );
    }
    return parse(contenidoTexto);
  }

  /// Longitud del cuerpo visible (límite SQL).
  static int longitudCuerpoVisible(String? almacenado) =>
      parse(almacenado).cuerpo.length;

  /// Quita marcadores markdown habituales para etiquetas y una línea de título.
  static String markdownAPlano(String markdown) {
    var texto = markdown;
    texto = _sustituirGrupo(texto, RegExp(r'\[([^\]]+)\]\([^)]+\)'));
    texto = _sustituirGrupo(texto, RegExp(r'\*\*([^*]+)\*\*'));
    texto = _sustituirGrupo(texto, RegExp(r'__([^_]+)__'));
    texto = _sustituirGrupo(texto, RegExp(r'\*([^*]+)\*'));
    texto = _sustituirGrupo(texto, RegExp(r'_([^_]+)_'));
    texto = _sustituirGrupo(texto, RegExp(r'`([^`]+)`'));
    texto = texto.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    return texto;
  }

  static String _sustituirGrupo(String texto, RegExp patron) =>
      texto.replaceAllMapped(patron, (coincidencia) => coincidencia.group(1)!);
}
