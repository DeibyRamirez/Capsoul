# Capsoul · Visión y objetivos

## Producto

**Capsoul** es una aplicación móvil (Flutter, Android/iOS) para guardar recuerdos multimedia y entregarlos en el tiempo: cápsulas selladas, momentos compartidos con cercanos, herencias digitales y retos entre amigos.

- **Slogan:** *Pequeñas herencias, grandes recuerdos.*
- **Paquete:** `com.capsoul` · Dart: `capsoul`
- **Repo:** https://github.com/DeibyRamirez/Capsoul

## Objetivos del producto

1. **Preservar** fotos, videos, audios y notas de forma privada y segura.
2. **Programar** la entrega de cápsulas a destinatarios en una fecha futura.
3. **Dejar legado** mediante herencias activadas por fecha, inactividad o confirmación de una persona de confianza.
4. **Compartir** momentos con el círculo cercano (red reservada, no feed público estilo Instagram en Inicio).
5. **Recordar** con retos periódicos entre amigos.

## Metas técnicas del sprint actual

| Meta | Estado |
|---|---|
| Auth con Supabase (correo confirmado obligatorio) | Hecho |
| Banco de recuerdos con subida a Cloudinary | Hecho |
| Crear y listar momentos | Hecho |
| Perfil con rejilla de momentos y stats | Hecho |
| Feed de momentos con carrusel horizontal | Hecho |
| Cápsulas: crear, listar, detalle con candado | En progreso |
| FCM: token sin bloquear arranque | Hecho |
| Registrar token en `dispositivos_push` | Pendiente |
| Edge Function `enviar-avisos` | Pendiente |

## Decisiones del PO (resumen)

| ID | Decisión | Efecto |
|---|---|---|
| D1 | Plan Free de Supabase | Riesgo de pausa del proyecto; `pg_cron` no corre si está pausado |
| D2 | Medios `authenticated` en Cloudinary | Solo `public_id` en Postgres; URLs firmadas vía `firmar-medio` |
| D3 | SMTP con Resend | Correos de Auth y avisos a externos |
| D4 | Firebase solo FCM (plan Spark) | Sin Auth/Firestore/Storage en Firebase |
| D5 | Confirmación de correo obligatoria | Toda sesión implica correo verificado |

## Definition of Done (DoD)

Antes de cerrar una historia:

- `flutter analyze` sin issues.
- `flutter test` en verde.
- Pantalla con estados vacío, carga y error.
- Sin llamadas directas a Supabase/Cloudinary en widgets.
- Textos de UI en español.
- Skill `capsoul-sprint-dod` revisada si aplica.

## Público de esta documentación

- Desarrolladores del equipo (pasantía / fábrica de software).
- Agentes de IA con skills en `.cursor/skills/`.
- Product Owner para decisiones de arquitectura y entornos.
