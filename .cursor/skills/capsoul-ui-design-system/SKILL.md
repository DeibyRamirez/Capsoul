---
name: capsoul-ui-design-system
description: >-
  Usar cuando se construyan o revisen pantallas, tema, barra de navegación o la
  coherencia visual de Capsoul.
---
# Capsoul · Sistema de diseño de UI

## Marca (congelada)
- Primario azul marino: `#1B2A4A`
- Acento: `#3D6B9A`
- Radios: 12–20
- Idioma de la UI: español
- Inicio: la cúpula de vidrio como visual característico
- Barra inferior (5 zonas): Inicio | Momentos | + | Mi legado | Yo
- No usar un feed estilo Instagram como inicio

## Tema
1. Colores en `lib/nucleo/tema/colores_app.dart` (`ColoresApp`) y `ThemeData` en `tema_app.dart` (`TemaApp`).
2. Nunca hexadecimales en los widgets de funcionalidades: `ColoresApp` o `Theme.of(context)`.
3. Preferir `NavigationBar` / `FilledButton` / `Card` de Material 3 con los colores de marca.

## Hábitos de diseño
1. Áreas seguras siempre.
2. Objetivos táctiles ≥ 48 px lógicos.
3. Estados vacío, cargando y error en toda lista o detalle.
4. Los marcadores de sprints tempranos respetan espaciado y barra para que la demo se vea intencional.

## Flujo de Crear
El selector de Crear se abre desde el `+` elevado; no reemplaza el contenedor de inicio.

## Preguntas de revisión
- ¿La pantalla se siente Capsoul (cúpula, azul marino, español)?
- ¿Un ingeniero nuevo sabría qué tokens del tema reutilizar?

## Fuentes
- Material 3 para Flutter: https://docs.flutter.dev/ui/design/material
