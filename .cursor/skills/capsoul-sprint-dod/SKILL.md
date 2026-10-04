---
name: capsoul-sprint-dod
description: >-
  Usar cuando se empiece una historia de Capsoul, se divida el trabajo del
  sprint o se revise la Definition of Done antes de la demo.
---
# Capsoul · Historias y Definition of Done

## Roles
- Product Owner (THE CHEIVIZ): valor, aceptación y **aprobación de cualquier cambio en entornos**
- Scrum Master / director (agente Capsoul): prioriza, aclara historias, revisa la DoD
- Flutter senior + ingenieros: implementan

## Forma de la historia
1. Historia de usuario con criterios de aceptación en español de producto
2. Notas técnicas solo donde desbloquean (tablas, políticas RLS, paquetes)
3. Fuera de alcance explícito (en especial fase 2: legal, marketplace, mapa)

## Definition of Done (general)
- Criterios cumplidos en dispositivo o emulador real
- `flutter analyze` sin issues y `flutter test` en verde
- `flutter build apk --debug` exitoso si cambian dependencias o archivos nativos
- Navegación sin rutas rotas ni pantallas que fallen
- Tema y barra siguen la skill de UI
- Datos sensibles revisados: RLS en todas las tablas, sin secretos en el cliente
- Migraciones como archivos versionados; aplicarlas solo con aprobación del PO
- Código y commits en español
- Notas de demo listas

## Sprint 1 (cimientos) — cerrado
Estructura, tema, barra de 5 zonas con `+` hacia Crear, pantallas base, `firebase_core` inicializado.

## Sprint 2 (identidad) — en develop, migrando a Supabase Auth
Registro, inicio de sesión, recuperar contraseña, sesión persistente, perfil en `usuarios`.

## Entrega
Cuando la DoD se cumple, avisar a Capsoul para la revisión y el siguiente foco del sprint.

## Fuentes
- Scrum Guide 2020 (Definition of Done): https://scrumguides.org/scrum-guide.html
