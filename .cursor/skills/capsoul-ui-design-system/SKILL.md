---
name: capsoul-ui-design-system
description: >-
  Use when building or reviewing Capsoul screens, theme, nav chrome, or visual
  consistency.
---
# Capsoul UI design system

Use when building or reviewing Capsoul screens, theme, nav, or visual consistency with the frozen home-dome line.

## Brand (frozen)
- Primary navy: `#1B2A4A`
- Accent: `#3D6B9A`
- Corner radius: 12–20
- UI language: Spanish
- Home: glass dome / cúpula as the signature visual
- Bottom nav (5 zones): Inicio | Momentos | + | Mi legado | Yo
- Do not ship an Instagram-style feed as the home shell

## Theme
1. Centralize colors in `core/theme/app_colors.dart` and `ThemeData` in `app_theme.dart`.
2. Never hardcode brand hex in feature widgets; use `AppColors` or `Theme.of(context)`.
3. Prefer Material 3 `NavigationBar` / `FilledButton` / `Card` with brand colors over one-off decoration.

## Layout habits
1. Safe areas and notches always.
2. Touch targets ≥ 48 logical pixels.
3. Empty, loading, and error states for every list/detail screen.
4. Placeholders in early sprints should still match spacing and nav chrome so demos look intentional.

## Create flow UI
The Create selector is media-first in spirit but must open from the elevated `+`, not replace the home shell.

## Review questions
- Does this screen still feel like Capsoul (dome, navy, Spanish)?
- Would a new engineer know which theme tokens to reuse?
