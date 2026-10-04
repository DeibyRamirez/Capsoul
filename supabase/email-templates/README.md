# Plantillas de correo · Supabase Auth

HTML en español con la identidad visual de Capsoul ([`docs/Design.md`](../../docs/Design.md)).
Variables Go template en inglés, tal como las espera Supabase.

## Cómo cargarlas en Supabase

1. Abre **Supabase Dashboard** → **Authentication** → **Email Templates**.
2. Para cada plantilla, copia el **asunto** y el **contenido HTML** del archivo correspondiente.
3. Pega el HTML completo del archivo `.html` (incluye `<!DOCTYPE html>` … `</html>`).
4. Guarda y, si es posible, envía un correo de prueba desde el panel.

SMTP configurado vía Resend (`send.cheiviz.com`); ver [`docs/06-integraciones.md`](../../docs/06-integraciones.md).

## Mapeo archivo → plantilla Supabase

| Archivo | Plantilla en Supabase | Asunto sugerido |
|---------|----------------------|-----------------|
| [`confirmar-correo.html`](confirmar-correo.html) | **Confirm signup** | Confirma tu correo electrónico |
| [`invitacion.html`](invitacion.html) | **Invite user** | Te han invitado a Capsoul |
| [`enlace-inicio-sesion.html`](enlace-inicio-sesion.html) | **Magic Link** | Tu enlace de inicio de sesión |
| [`confirmar-nuevo-correo.html`](confirmar-nuevo-correo.html) | **Change Email Address** | Confirma tu nuevo correo electrónico |
| [`restablecer-contrasena.html`](restablecer-contrasena.html) | **Reset Password** | Restablece tu contraseña |
| [`codigo-verificacion.html`](codigo-verificacion.html) | **Reauthentication** (o OTP si aplica) | `{{ .Token }}` es tu código de verificación |

## Variables usadas

| Variable | Plantillas |
|----------|------------|
| `{{ .ConfirmationURL }}` | confirmar-correo, invitacion, enlace-inicio-sesion, confirmar-nuevo-correo, restablecer-contrasena |
| `{{ .NewEmail }}` | confirmar-nuevo-correo |
| `{{ .Token }}` | codigo-verificacion (cuerpo y asunto) |

No traduzcas ni modifiques el nombre de las variables; solo el texto visible en español.

## Diseño

- **Cabecera:** gradiente cielo nocturno (`#1B2A4A` → `#3D6B9A`).
- **Marca:** Capsoul en serif; eslogan *Pequeñas herencias, grandes recuerdos*.
- **Cuerpo:** tarjeta blanca, radios 20 px, texto `#1A1A2E`.
- **CTA:** botón `#1B2A4A`, texto blanco, radio 16 px.
- **OTP:** bloque monospace sobre fondo `#F5F7FA`.

Layout por tablas e estilos inline para compatibilidad con clientes de correo.

## Vista previa local

Abre cualquier `.html` en el navegador. Las variables `{{ .… }}` se verán literales hasta que Supabase las sustituya al enviar.
