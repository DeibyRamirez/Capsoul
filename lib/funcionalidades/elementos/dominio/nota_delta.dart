/// Utilidades puras para el Delta de las notas enriquecidas.
///
/// El dominio no depende de `flutter_quill`: el Delta se representa como la
/// lista JSON que produce `Delta.toJson()` y que se guarda en `contenido_rico`.
library;

/// Atributos inline permitidos en una nota.
const Set<String> atributosNotaPermitidos = {'bold', 'italic', 'underline'};

/// Convierte texto plano en un Delta válido de Quill.
List<Map<String, dynamic>> deltaDesdeTextoPlano(String texto) {
  final normalizado = texto.endsWith('\n') ? texto : '$texto\n';
  return [
    {'insert': normalizado},
  ];
}

/// Convierte el Markdown que generaba la app anterior a un Delta.
///
/// Solo interpreta los formatos que la pantalla anterior insertaba:
/// `**negrita**`, `__negrita__`, `_cursiva_`, `*cursiva*` y
/// `<u>subrayado</u>`. Cualquier otro marcador queda como texto.
List<Map<String, dynamic>> deltaDesdeMarkdownLegacy(String markdown) {
  var negrita = false;
  var cursiva = false;
  var subrayado = false;
  var i = 0;
  final buffer = StringBuffer();
  final salida = <Map<String, dynamic>>[];

  Map<String, dynamic> atributosActuales() => {
    if (negrita) 'bold': true,
    if (cursiva) 'italic': true,
    if (subrayado) 'underline': true,
  };

  void volcar() {
    if (buffer.isEmpty) return;
    final atributos = atributosActuales();
    salida.add({
      'insert': buffer.toString(),
      if (atributos.isNotEmpty) 'attributes': atributos,
    });
    buffer.clear();
  }

  while (i < markdown.length) {
    if (markdown.startsWith('**', i)) {
      volcar();
      negrita = !negrita;
      i += 2;
      continue;
    }
    if (markdown.startsWith('__', i)) {
      volcar();
      negrita = !negrita;
      i += 2;
      continue;
    }
    if (markdown.startsWith('<u>', i)) {
      volcar();
      subrayado = true;
      i += 3;
      continue;
    }
    if (markdown.startsWith('</u>', i)) {
      volcar();
      subrayado = false;
      i += 4;
      continue;
    }
    final caracter = markdown[i];
    if (caracter == '_' || caracter == '*') {
      volcar();
      cursiva = !cursiva;
      i++;
      continue;
    }
    buffer.write(caracter);
    i++;
  }
  volcar();

  if (salida.isEmpty) return deltaDesdeTextoPlano('');
  if (!_terminaEnSalto(salida)) {
    final ultimo = salida.last;
    ultimo['insert'] = '${ultimo['insert']}\n';
  }
  return salida;
}

/// Limpia un Delta de Quill para dejar solo texto y los tres formatos
/// soportados. Descarta enlaces, listas, encabezados, imágenes y atributos
/// externos. Garantiza el salto de línea final que exige Quill.
List<Map<String, dynamic>> sanitizarDelta(List<dynamic> delta) {
  final limpio = <Map<String, dynamic>>[];

  void agregar(String texto, Map<String, dynamic> atributos) {
    if (texto.isEmpty) return;
    final ultimo = limpio.isEmpty ? null : limpio.last;
    final mismosAtributos =
        ultimo != null &&
        _mapaIgual(
          (ultimo['attributes'] as Map<String, dynamic>?) ?? const {},
          atributos,
        );
    if (mismosAtributos) {
      ultimo['insert'] = '${ultimo['insert']}$texto';
      return;
    }
    limpio.add({
      'insert': texto,
      if (atributos.isNotEmpty) 'attributes': atributos,
    });
  }

  for (final operacion in delta) {
    if (operacion is! Map) continue;
    final insert = operacion['insert'];
    if (insert is! String) continue;
    final atributosRaw = operacion['attributes'];
    final atributos = <String, dynamic>{};
    if (atributosRaw is Map) {
      for (final clave in atributosNotaPermitidos) {
        if (atributosRaw[clave] == true) atributos[clave] = true;
      }
    }
    agregar(insert, atributos);
  }

  if (limpio.isEmpty) return deltaDesdeTextoPlano('');
  if (!_terminaEnSalto(limpio)) {
    final ultimo = limpio.last;
    final atributos = (ultimo['attributes'] as Map<String, dynamic>?) ?? {};
    agregar('\n', atributos);
  }
  return limpio;
}

/// Texto visible de un Delta, sin el salto de línea técnico final de Quill.
String textoPlanoDesdeDelta(List<dynamic> delta) {
  final buffer = StringBuffer();
  for (final operacion in delta) {
    if (operacion is Map && operacion['insert'] is String) {
      buffer.write(operacion['insert']);
    }
  }
  return buffer.toString().replaceFirst(RegExp(r'\n$'), '');
}

/// Delta a partir del formato que devuelve `Document.toDelta().toJson()`.
List<Map<String, dynamic>> deltaDesdeJson(Object? delta) {
  if (delta is List) return sanitizarDelta(delta);
  return deltaDesdeTextoPlano('');
}

bool _terminaEnSalto(List<Map<String, dynamic>> delta) {
  final ultimo = delta.isEmpty ? null : delta.last['insert'];
  return ultimo is String && ultimo.endsWith('\n');
}

bool _mapaIgual(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final entrada in a.entries) {
    if (b[entrada.key] != entrada.value) return false;
  }
  return true;
}
