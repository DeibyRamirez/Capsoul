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
| — | [08-musica-producto-y-licencias.md](08-musica-producto-y-licencias.md) | Música (Spotify/Deezer), producción y decisiones para el PO |
| — | [11-legado-y-retos.md](11-legado-y-retos.md) | Herencias, persona de confianza, retos globales |
| — | [10-permisos-dispositivo-y-privacidad.md](10-permisos-dispositivo-y-privacidad.md) | Cámara, micrófono, galería, copy de permisos |
| — | [contrato-api-legado.md](contrato-api-legado.md) | RPC y payloads de legado |
| — | [verificacion-avatar-perfil.md](verificacion-avatar-perfil.md) | Checklist avatar Cloudinary |
| 7 | [07-patrones-y-convenciones.md](07-patrones-y-convenciones.md) | Riverpod, go_router, nomenclatura, reglas de código |
| 8 | [modelo_er.md](modelo_er.md) | Modelo entidad-relación de Postgres (v1.4) |
| — | [migraciones.md](migraciones.md) | Orden y estado de migraciones `000001`–`000015` |

## Otros recursos

- **Memoria viva del código:** [`Memory.md`](../Memory.md) en la raíz del repo.
- **Skills de agentes:** [`.cursor/skills/`](../.cursor/skills/).
- **Migraciones SQL:** [`supabase/migrations/`](../supabase/migrations/).
- **Edge Functions:** [`supabase/functions/`](../supabase/functions/).

## Ilustraciones

Las acuarelas reales viven en `assets/illustrations/` (WebP, lado máximo 1024). Se decodifican con `ResizeImage` a 1024 px y el hero se precarga al arrancar para que no aparezca de golpe.

| Archivo | Dónde se usa |
|---|---|
| `hero_calm.webp` | Hero de Inicio y franja superior de autenticación. Fondo casi blanco que se funde en `superficie` (`#F4F8FC`). |
| `landscape_lake.webp` | Recorte sin el marco de papel. Cabecera de Mi legado y paso «Deja un legado» de la bienvenida. |

El resto de huecos sigue siendo PNG opcional (`assets/illustrations/<nombre>.png`). Si el archivo no está, la pantalla dibuja el icono o el arte en código. Nombres en `NombresIlustracion`:

`hero_jar`, `auth_night`, `onboarding_1`, `onboarding_2`, `onboarding_3`, `card_memories`, `card_moments`, `card_capsule`, `card_legacy`, `empty_memories`, `empty_moments`, `empty_capsules`, `empty_received`, `empty_legacy`, `empty_friends`, `capsule_sealed`, `capsule_opened`, `challenge_daily`, `challenge_weekly`, `challenge_special`, `challenge_done`, `error_offline`.

## Convenciones

- Los documentos están en español.
- Los diagramas usan [Mermaid](https://mermaid.js.org/).
- La arquitectura de infraestructura (ARQ-2) vive en `arquitectura.md`; el modelo de datos en `modelo_er.md`.
