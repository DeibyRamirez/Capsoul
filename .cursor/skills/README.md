# Skills del proyecto Capsoul

Esta carpeta contiene las skills de agente específicas del proyecto Capsoul. Cada skill vive en su propia
carpeta con un archivo `SKILL.md` que Cursor (y otros agentes compatibles) cargan como contexto cuando la tarea
coincide con su descripción. Todas están en español y citan sus fuentes al final.

## Skills del proyecto

| Skill | Propósito |
| --- | --- |
| [`capsoul-flutter-architecture`](capsoul-flutter-architecture/SKILL.md) | Estructura por funcionalidades, enrutamiento y capas de la app Flutter (todo en español). |
| [`capsoul-flutter-clean-code`](capsoul-flutter-clean-code/SKILL.md) | Principios, patrones y buenas prácticas de Dart/Flutter. |
| [`capsoul-ui-design-system`](capsoul-ui-design-system/SKILL.md) | Marca congelada (`#1B2A4A`, `#3D6B9A`, cúpula), tema y barra de 5 zonas. |
| [`capsoul-supabase-postgres-sql`](capsoul-supabase-postgres-sql/SKILL.md) | Diseño SQL, ACID, normalización, índices y migraciones en `supabase/migrations`. |
| [`capsoul-supabase-auth-rls`](capsoul-supabase-auth-rls/SKILL.md) | Supabase Auth en Flutter, sesión, verificación y RLS por `auth.uid()` (reemplaza `capsoul-firebase-integrity`). |
| [`capsoul-supabase-datos`](capsoul-supabase-datos/SKILL.md) | Repositorios con Supabase, mapeo de filas y errores (reemplaza `capsoul-firestore-storage`). |
| [`capsoul-cloudinary-medios`](capsoul-cloudinary-medios/SKILL.md) | Subidas firmadas, carpetas por usuario, transformaciones y metadatos de medios. |
| [`capsoul-mcp`](capsoul-mcp/SKILL.md) | Uso de servidores MCP y la regla de aprobación del PO antes de cambiar entornos. |
| [`capsoul-sprint-dod`](capsoul-sprint-dod/SKILL.md) | Forma de las historias y Definition of Done. |

## Skills oficiales recomendadas (skills.sh)

> **Estado: pendiente.** No están instaladas en el repositorio. Instalarlas añade archivos al repo: hacerlo solo
> con aprobación del PO y revisar lo agregado antes del commit.

| Paquete | Uso previsto |
| --- | --- |
| `supabase/agent-skills` (`supabase`, `supabase-postgres-best-practices`) | Skills oficiales de Supabase y Postgres. |
| `flutter/agent-plugins` | Skills oficiales de Flutter/Dart. |

```bash
npx skills add supabase/agent-skills
npx skills add flutter/agent-plugins
```
