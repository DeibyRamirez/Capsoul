---
name: capsoul-supabase-auth-rls
description: >-
  Usar cuando se trabaje con Supabase Auth en Flutter (registro, inicio de
  sesión, sesión, verificación de correo, recuperación) o con Row Level Security
  y la integridad de datos sensibles de Capsoul (cápsulas selladas, herencias).
---
# Capsoul · Supabase Auth y RLS

Reemplaza a `capsoul-firebase-integrity`. Usar al tocar autenticación, políticas RLS, liberación de cápsulas,
privacidad o cualquier ruta de datos sensible.

## Modelo de amenazas (MVP)
- El cliente es hostil: la `anon key` es pública y cualquiera puede llamar a la API REST con ella.
- El contenido sellado (cápsulas antes de `fecha_apertura`, herencias) no debe filtrarse antes de tiempo.
- Destinatarios y personas de confianza solo ven lo que la privacidad permite.

## Reglas duras
1. **RLS habilitado en todas las tablas de `public`**, sin excepción, en la misma migración que crea la tabla.
   Sin políticas = nadie accede (denegar por defecto).
2. Políticas por dueño con `(select auth.uid()) = usuario_id` (el `select` hace que se evalúe una vez) y
   especificando el rol: `to authenticated`. Separar políticas por operación (`select`, `insert`, `update`,
   `delete`) y usar `with check` en `insert`/`update`.
3. Indexar las columnas que usan las políticas (`usuario_id`, `capsula_id`).
4. **Nunca** usar la `service_role key` ni secretos en la app Flutter: solo `SUPABASE_URL` y `SUPABASE_ANON_KEY`
   por `--dart-define`. Lo privilegiado va en Edge Functions o funciones `security definer`.
5. Funciones `security definer`: `set search_path = ''`, nombres totalmente calificados (`public.usuarios`),
   comprobar `auth.uid()` dentro si actúan en nombre del usuario, vivir en un esquema no expuesto cuando sean
   ayudantes de políticas y `revoke execute` a los roles que no deben llamarlas.
6. El tiempo lo decide la base: comparar `fecha_apertura <= now()` en la política, nunca un booleano
   `liberada` enviado por el cliente.
7. Los datos de `raw_user_meta_data` los controla el usuario: usarlos solo para datos iniciales inocuos
   (p. ej. `nombre_visible`), nunca para roles o permisos.

## Auth en Flutter (supabase_flutter)
1. Inicializar una vez en el arranque: `Supabase.initialize(url:, anonKey:)` con valores de
   `String.fromEnvironment`; si faltan, mostrar la pantalla de error de arranque.
2. La sesión se persiste sola; la fuente de verdad es `auth.onAuthStateChange` (emite `initialSession` al
   suscribirse). El enrutador redirige según ese flujo.
3. Registro: `signUp(email:, password:, data: {'nombre_visible': …})`; un trigger `after insert on auth.users`
   crea la fila en `public.usuarios`. Si el proyecto exige confirmar el correo, `signUp` no devuelve sesión:
   mostrar "revisa tu correo" y volver a iniciar sesión. Si el correo ya existe, Supabase responde igual
   (sin revelar la cuenta): mantener el mensaje neutro.
4. Inicio de sesión `signInWithPassword`; recuperación `resetPasswordForEmail(email, redirectTo:)` con
   confirmación neutra; reenvío `resend(type: OtpType.signup, email:)`; verificado = `user.emailConfirmedAt != null`.
5. Errores: mapear `AuthException.code` (no el texto) a mensajes en español: `invalid_credentials`,
   `email_not_confirmed`, `user_already_exists`/`email_exists`, `over_request_rate_limit`/
   `over_email_send_rate_limit` (o `statusCode` 429), `weak_password`, `AuthRetryableFetchException` (sin red).
6. Enlaces de recuperación/confirmación en móvil requieren deep link (`io.supabase.capsoul://…`) registrado en
   Auth → URL Configuration y en Android/iOS: es un cambio de plataforma y de entorno, **pedir aprobación**.

## Lista de revisión
- RLS habilitado y probado con dos usuarios distintos (uno no ve lo del otro)
- Ninguna clave privilegiada en el repo ni en el binario
- Políticas con `to authenticated`, `(select auth.uid())` e índices
- Contenido sellado no legible antes de `fecha_apertura`, ni por la API ni por Cloudinary (ver `capsoul-cloudinary-medios`)

## Fuentes
- Supabase, "Row Level Security": https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase, "RLS performance": https://supabase.com/docs/guides/database/postgres/row-level-security-performance
- Supabase Agent Skills, `security-rls-performance`: https://github.com/supabase/agent-skills/blob/main/skills/supabase-postgres-best-practices/references/security-rls-performance.md
- Supabase, "User management" (trigger `handle_new_user`, `security definer set search_path = ''`): https://supabase.com/docs/guides/auth/managing-user-data
- Supabase, "Auth error codes": https://supabase.com/docs/guides/auth/debugging/error-codes
- Supabase, referencia Dart (`signUp`, `signInWithPassword`, `resetPasswordForEmail`, `resend`, `onAuthStateChange`): https://supabase.com/docs/reference/dart/introduction
- Supabase, "Native mobile deep linking": https://supabase.com/docs/guides/auth/native-mobile-deep-linking
- Supabase, "API keys": https://supabase.com/docs/guides/api/api-keys
