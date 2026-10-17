# Capsoul — Sistema de diseño

Guía visual de la app. Los tokens viven en código en `lib/nucleo/tema/`; este documento explica **cuándo** y **cómo** usarlos.
Fuente de verdad visual: `docs/design_system_for_flutter.md` (modo claro, paleta pastel azul/gris).

## Identidad

Capsoul guarda recuerdos como luces dentro de una cápsula de vidrio. La UI combina:

- **Emoción:** frasco luminoso, luciérnagas (dentro de tarjetas medianoche), títulos en Playfair Display.
- **Claridad:** Material 3 en **modo claro**, fondo azul hielo, tarjetas blancas con borde sutil y sombra azul suave.
- **Español** en toda la interfaz.

---

## Tokens de color (`ColoresApp`)

| Token | Hex | Uso |
|-------|-----|-----|
| `primario` | `#1B316B` | Botones filled, navegación activa, logo, chips de icono (al 8 %), bordes |
| `acento` | `#3D6B9A` | Enlaces (`TextButton`), foco de campos |
| `superficie` / `fondoFin` | `#F4F8FC` | Fondo plano y final del degradado |
| `fondoInicio` | `#E2EDF8` | Inicio del degradado claro |
| `tarjeta` / `sobrePrimario` | `#FFFFFF` | Tarjetas, campos, texto sobre primario |
| `bordeTarjeta` | `#D6E4F0` | Borde de 1 px de tarjetas, campos, chips, divisores |
| `sombraTarjeta` | `#141B316B` | Sombra de tarjeta (azul real 8 %) |
| `textoPrincipal` / `sobreSuperficie` | `#111E38` | Títulos y texto principal |
| `textoSecundario` / `atenuado` | `#5A6E94` | Subtítulos, descripciones, metadatos |
| `navInactivo` | `#8FA1C2` | Iconos/etiquetas inactivas de la barra, hints |
| `dorado` / `doradoClaro` | `#F59E0B` / `#FDE68A` | Solo brillos, estrellas, corazones e iconos (no texto) |
| `medianoche` | `#132247` | Banners oscuros y cielo con luciérnagas |
| `pastelAzul` / `pastelVerde` / `pastelRosa` | `#B8D4E8` / `#C8E6C9` / `#F8BBD0` | Insignias del perfil |
| `spotify` / `appleMusic` / `youtube` | `#1DB954` / `#A238FF` / `#FF0000` | Marcas externas de música |
| `vidrioCupula` / `bordeCupula` | `#33FFFFFF` / `#66FFFFFF` | Vidrio del frasco (solo sobre fondo oscuro) |

**Regla:** nunca escribir hex en widgets de funcionalidades; usar `ColoresApp` o `Theme.of(context)`.
**Contraste:** texto blanco solo sobre `primario`, `medianoche`, fotos o cámara; sobre fondo claro usar `textoPrincipal`/`textoSecundario`.

---

## Radios, espaciado y sombras (`TemaApp`)

| Token | Valor |
|-------|-------|
| `radioPequeno` | 12 px (campos, chips de icono) |
| `radioMediano` | 16 px |
| `radioGrande` | 20 px (tarjetas, diálogos, hojas) |
| `radioPildora` | 30 px (botones: `StadiumBorder`) |
| `altoBoton` | 48 px |
| `sombraTarjeta` | `#141B316B`, blur 16, offset (0, 6) |
| `decoracionTarjeta()` | blanco + borde `bordeTarjeta` + sombra + radio 20 |

Padding horizontal de pantalla 16–20 px; padding de tarjeta 16 px; separación de rejilla 16 px. Áreas táctiles mínimas: **48** px.

---

## Tipografía (assets en `assets/fonts`, OFL)

- **UI general:** `Poppins` (400, 500, 600, 700) — global en `ThemeData.fontFamily` (`TemaApp.fuenteUi`).
- **Marca / hero:** `PlayfairDisplay` (variable 400–900) — `TemaApp.fuenteTitulos`.
- Logo: Playfair 700, ~28, `primario`, letterSpacing 1.2. Título de tarjeta: Poppins 600 16 `textoPrincipal`.
  Cuerpo: Poppins 400 12–14 `textoSecundario`. Botón: Poppins 500 14 blanco.

---

## Fondos

Implementados en `DegradadosCapsoul` y `FondoCapsoul`.

1. **Suave** (`FondoCapsoulTipo.suave`, **default** de `PantallaCapsoul`): `#E2EDF8 → #F4F8FC`.
2. **Plano** (`FondoCapsoulTipo.plano`): sólido `superficie`.
3. **Nocturno** (`DegradadosCapsoul.nocturno`, `medianoche → primario`): **solo dentro de tarjetas/banners oscuros** con `CieloNocturno`; nunca a pantalla completa.
4. **Banner** (`DegradadosCapsoul.banner`): horizontal `medianoche → primario` (frase de Inicio).

---

## Partículas (luciérnagas y estrellas)

Widget: `CieloNocturno` en `lib/nucleo/componentes/cielo_nocturno.dart` (no modificar su lógica).
Se muestra siempre dentro de un contenedor medianoche recortado con `radioGrande`:

- Inicio: tarjeta con `EscenaFrascoInicio` (frasco + texto manuscrito).
- Autenticación: banner de 96 px sobre el panel blanco.
- Detalle de cápsula: tarjeta con frasco, título y fecha (`CabeceraCapsula`).

Respetar `MediaQuery.disableAnimations` → pintor estático. No en listas, tabs ni cámara.

---

## Componentes canónicos

| Widget | Ruta | Rol |
|--------|------|-----|
| `FrascoLuminoso` | `nucleo/componentes/frasco_luminoso.dart` | Cápsula de vidrio (usar sobre fondo oscuro) |
| `EscenaFrascoInicio` | `inicio/.../escena_frasco_inicio.dart` | Tarjeta medianoche de Inicio con luciérnagas |
| `CieloNocturno` | `nucleo/componentes/cielo_nocturno.dart` | Cielo animado |
| `CabeceraCapsula` | `capsulas/.../cabecera_capsula.dart` | Cabecera clara + tarjeta medianoche |
| `CabeceraDetalleCapsoul` | `nucleo/componentes/cabecera_detalle_capsoul.dart` | Cabecera clara con título Playfair |
| `FondoCapsoul` | `nucleo/componentes/fondo_capsoul.dart` | Envoltorio de degradado |
| `PantallaCapsoul` | `nucleo/componentes/pantalla_capsoul.dart` | Scaffold estándar (fondo suave) |
| `TarjetaCapsoul` | `nucleo/componentes/tarjeta_capsoul.dart` | Tarjeta blanca con borde, sombra y chip de icono |
| `TarjetaSeccionInicio` | `inicio/.../tarjeta_seccion_inicio.dart` | Tarjeta de la rejilla 2×2 |

---

## Patrones de pantalla

- **Inicio:** encabezado claro (logo Playfair `primario`, slogan `textoSecundario`, campana `primario`), tarjeta medianoche con frasco, botón píldora "Guardar algo hoy", rejilla 2×2 (separación 16) y banner medianoche.
- **Detalle:** cabecera clara (`CabeceraDetalleCapsoul`) o `CabeceraCapsula`; cuerpo sobre `superficie` con `TarjetaCapsoul`.
- **Autenticación:** fondo suave, banner con luciérnagas y panel `decoracionTarjeta()` centrado.
- **Navegación inferior:** Inicio | Momentos | + | Mi legado | Yo. `NavigationBar` blanca, activo `primario`, inactivo `navInactivo`, indicador `primario @ 10%`; `+` circular `primario` con sombra.
- **AppBar:** transparente, texto/iconos `textoPrincipal`.

---

## Tarjetas de contenido

- Fondo `tarjeta`, borde 1 px `bordeTarjeta`, `sombraTarjeta`, radio `radioGrande`, padding 16.
- Chip de icono: fondo `primario @ 8%`, icono `primario`.

---

## Anti-patrones

- Hexadecimales en widgets de funcionalidades.
- Texto blanco sobre fondo claro; dorado como color de texto.
- Cielo nocturno a pantalla completa o partículas en listas/cámara.
- Fondos que compiten con el contenido.
- Omitir estados vacío, cargando y error en listas o detalles.

---

## Fuentes en código

- Colores: `lib/nucleo/tema/colores_app.dart`
- Tema Material: `lib/nucleo/tema/tema_app.dart`
- Degradados: `lib/nucleo/tema/degradados_capsoul.dart`
- Fuentes: `assets/fonts/` (declaradas en `pubspec.yaml`)
- Skill del agente: `.cursor/skills/capsoul-ui-design-system/SKILL.md`
