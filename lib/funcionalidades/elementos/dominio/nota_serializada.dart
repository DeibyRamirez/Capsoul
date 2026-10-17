import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores_app.dart';

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

/// Nota con cuerpo markdown y estilo embebido en `contenido_texto`.
class NotaSerializada {
  const NotaSerializada({required this.estilo, required this.cuerpo});

  final EstiloNota estilo;
  final String cuerpo;

  /// Texto listo para guardar en `contenido_texto`.
  String serializar() {
    final meta = jsonEncode(estilo.aMapa());
    return '$_inicioFrontMatter$meta$_finFrontMatter$cuerpo';
  }

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
      return NotaSerializada(estilo: EstiloNota.desdeMapa(mapa), cuerpo: cuerpo);
    } catch (_) {
      return NotaSerializada(estilo: const EstiloNota(), cuerpo: cuerpo);
    }
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
