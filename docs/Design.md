# Capsoul · Sistema de diseño

Guía visual de la app. Los tokens viven en código en `lib/nucleo/tema/`; este documento explica **cuándo** y **cómo** usarlos.

## Identidad

Capsoul guarda recuerdos como luces dentro de una cápsula de vidrio bajo un cielo nocturno. La UI combina:

- **Emoción:** frasco luminoso, luciérnagas, tipografía serif en títulos hero.
- **Claridad:** Material 3, contraste legible, tarjetas blancas sobre fondos suaves.
- **Español** en toda la interfaz.

Referencias visuales: `pantalla_inicio.dart`, `pantalla_detalle_capsula.dart`.

---

## Tokens de color

| Token | Hex | Uso |
|-------|-----|-----|
| `ColoresApp.primario` | `#1B2A4A` | AppBar, chips de icono, botones filled, texto principal |
| `ColoresApp.acento` | `#3D6B9A` | FAB, enlaces, degradados, indicador de navegación |
| `ColoresApp.superficie` | `#F5F7FA` | Fondo plano, final del degradado suave |
| `ColoresApp.sobrePrimario` | `#FFFFFF` | Texto sobre primario, tarjetas, campos |
| `ColoresApp.sobreSuperficie` | `#1A1A2E` | Texto sobre superficie clara |
| `ColoresApp.atenuado` | `#6B7280` | Subtítulos, metadatos |
| `ColoresApp.vidrioCupula` | `#33FFFFFF` | Efectos de vidrio |
| `ColoresApp.bordeCupula` | `#66FFFFFF` | Borde del frasco |

**Regla:** nunca escribir hex en widgets de funcionalidades; usar `ColoresApp` o `Theme.of(context)`.

---

## Radios y espaciado

Definidos en `TemaApp`:

| Token | Valor |
|-------|-------|
| `radioPequeno` | 12 px |
| `radioMediano` | 16 px |
| `radioGrande` | 20 px |

Espaciado habitual: **8**, **12**, **16**, **24** px.

Áreas táctiles mínimas: **48** px lógicos.

---

## Tipografía

- **UI general:** tema Material 3 (`Theme.of(context).textTheme`).
- **Títulos emocionales / hero:** `fontFamily: 'serif'`, peso 300–500; itálica opcional (ej. «Tu vida. Tus momentos. Tu legado.»).
- **Sobre cielo nocturno:** texto blanco (`ColoresApp.sobrePrimario`) con alpha 0.8–1.0 en secundarios.

---

## Fondos (3 niveles)

Implementados en `DegradadosCapsoul` y `FondoCapsoul`.

### 1. Nocturno (`FondoCapsoulTipo.nocturno`)

- Gradiente vertical: `primario → primario (55%) → acento`.
- Partículas: estrellas + luciérnagas (`CieloNocturno`).
- **Dónde:** cabeceras de detalle (cápsula), autenticación, zonas hero.

### 2. Suave (`FondoCapsoulTipo.suave`)

- Gradiente: `acento @ 18% → superficie`.
- Sin partículas (rendimiento).
- **Dónde:** Inicio, tabs (Momentos, Perfil, Legado), listas, formularios.

### 3. Plano (`FondoCapsoulTipo.plano`)

- Color sólido `superficie` o negro según contexto.
- **Dónde:** captura de cámara/audio, notas (UI funcional).

---

## Partículas (luciérnagas y estrellas)

Widget: `CieloNocturno` en `lib/nucleo/componentes/cielo_nocturno.dart`.

| Tipo | Aspecto | Animación |
|------|---------|-----------|
| Estrella | Círculo 0.6–1.8 px, alpha 0.2–0.7 | Parpadeo suave |
| Luciérnaga | Halo radial + cuerpo redondeado | Deriva ±4 px, pulso alpha 0.35–0.75, periodo 3–6 s |

**Alcance de animación:** solo pantallas **hero** y **autenticación**. No en listas, tabs ni cámara.

Respetar `MediaQuery.disableAnimations` → pintor estático.

---

## Componentes canónicos

| Widget | Ruta | Rol |
|--------|------|-----|
| `FrascoLuminoso` | `nucleo/componentes/frasco_luminoso.dart` | Cápsula de vidrio con luces internas |
| `EscenaFrascoInicio` | `inicio/.../escena_frasco_inicio.dart` | Hero de Inicio con frasco y texto manuscrito |
| `CieloNocturno` | `nucleo/componentes/cielo_nocturno.dart` | Fondo nocturno animado |
| `CabeceraCapsula` | `capsulas/.../cabecera_capsula.dart` | Cabecera de detalle con cielo + frasco |
| `CabeceraDetalleCapsoul` | `nucleo/componentes/cabecera_detalle_capsoul.dart` | Cabecera compacta para otros detalles |
| `FondoCapsoul` | `nucleo/componentes/fondo_capsoul.dart` | Envoltorio de degradado |
| `PantallaCapsoul` | `nucleo/componentes/pantalla_capsoul.dart` | Scaffold estándar con fondo |
| `TarjetaCapsoul` | `nucleo/componentes/tarjeta_capsoul.dart` | Tarjeta blanca con chip de icono |
| `TarjetaSeccionInicio` | `inicio/.../tarjeta_seccion_inicio.dart` | Tarjeta de sección con conteo e ilustración |

---

## Patrones de pantalla

### Lista con refresco

```dart
PantallaCapsoul(
  tipoFondo: FondoCapsoulTipo.suave,
  cuerpo: RefreshIndicator(
    onRefresh: ...,
    child: ListView(...),
  ),
)
```

### Inicio (zona hero)

- Los primeros ~320 px combinan `FondoCapsoul.suave` con una capa `CieloNocturno` (brillo ~0.35, animado).
- **EncabezadoInicio** y **EscenaFrascoInicio** (texto manuscrito) usan `sobrePrimario` (alpha 0.85–0.95), no `primario` ni `acento`: el texto vive sobre el cielo oscuro.
- A partir del botón "Guardar algo hoy" y la rejilla 2×2 el fondo es claro; ahí sí aplican `primario` y `atenuado`.

### Detalle con cabecera hero

- Cabecera: `CieloNocturno` + título serif + metadatos.
- Cuerpo: fondo `superficie`, tarjetas `TarjetaCapsoul` o contenido específico.

### Autenticación

- Fondo: `CieloNocturno` animado a pantalla completa.
- Formulario: panel blanco (`sobrePrimario`) con `radioGrande`, centrado en `EstructuraAutenticacion`.

### Navegación inferior

5 zonas: **Inicio | Momentos | + | Mi legado | Yo**. `NavigationBar` blanca, indicador `acento @ 20%`.

---

## Tarjetas de contenido

- Fondo: `ColoresApp.sobrePrimario`.
- Radio: `TemaApp.radioGrande` (secciones) o `radioMediano` (rejillas).
- Borde opcional: `atenuado @ 12%` para tarjetas en rejilla.
- Icono en chip cuadrado `primario` + icono blanco (patrón `TarjetaCapsoul`).

---

## Anti-patrones

- Hexadecimales en widgets de funcionalidades.
- Feed estilo Instagram como pantalla de inicio.
- Partículas animadas en listas o cámara (impacto en rendimiento y legibilidad).
- Fondos que compiten con el contenido (evitar degradados fuertes bajo texto largo).
- Omitir estados vacío, cargando y error en listas o detalles.

---

## Fuentes en código

- Colores: `lib/nucleo/tema/colores_app.dart`
- Tema Material: `lib/nucleo/tema/tema_app.dart`
- Degradados: `lib/nucleo/tema/degradados_capsoul.dart`
- Skill del agente: `.cursor/skills/capsoul-ui-design-system/SKILL.md`
