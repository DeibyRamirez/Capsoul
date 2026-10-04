# Capsoul · Documentación técnica

Índice de la documentación del proyecto **Capsoul** (app Flutter de cápsulas del tiempo y legado digital).

## Lectura recomendada

| Orden | Documento | Para qué sirve |
|---|---|---|
| 1 | [01-vision-y-objetivos.md](01-vision-y-objetivos.md) | Qué es Capsoul, metas, decisiones del PO |
| 2 | [arquitectura.md](arquitectura.md) | Vista general, componentes, flujos de infraestructura |
| 3 | [03-estructura-proyecto.md](03-estructura-proyecto.md) | Dónde está cada capa, pantalla y servicio en `lib/` |
| 4 | [04-flujos-criticos.md](04-flujos-criticos.md) | Arranque, auth, medios, cápsulas, momentos |
| 5 | [05-casos-de-uso.md](05-casos-de-uso.md) | Actor → caso de uso → pantalla → repositorio |
| 6 | [06-integraciones.md](06-integraciones.md) | Supabase, Cloudinary, FCM, Resend, secretos |
| 7 | [07-patrones-y-convenciones.md](07-patrones-y-convenciones.md) | Riverpod, go_router, nomenclatura, reglas de código |
| 8 | [modelo_er.md](modelo_er.md) | Modelo entidad-relación de Postgres (v1.3) |

## Otros recursos

- **Memoria viva del código:** [`Memory.md`](../Memory.md) en la raíz del repo.
- **Skills de agentes:** [`.cursor/skills/`](../.cursor/skills/).
- **Migraciones SQL:** [`supabase/migrations/`](../supabase/migrations/).
- **Edge Functions:** [`supabase/functions/`](../supabase/functions/).

## Convenciones

- Los documentos están en español.
- Los diagramas usan [Mermaid](https://mermaid.js.org/).
- La arquitectura de infraestructura (ARQ-2) vive en `arquitectura.md`; el modelo de datos en `modelo_er.md`.
