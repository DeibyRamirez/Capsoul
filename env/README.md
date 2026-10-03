# Configuración por entorno (`--dart-define-from-file`)

Capsoul lee la configuración de Supabase en compilación con
`String.fromEnvironment`. Las claves **nunca** se escriben en el código ni se
suben al repositorio: `env/*.json` está en `.gitignore` (solo se versiona
`dev.json.example`).

## Pasos

1. Copia el ejemplo: `Copy-Item env/dev.json.example env/dev.json`
   (o `cp env/dev.json.example env/dev.json`).
2. En `env/dev.json` pega la **anon key** (o la nueva *publishable key*
   `sb_publishable_...`) del proyecto `capsoul` en
   Supabase → Project Settings → API Keys. **Nunca** la `service_role` ni una
   clave secreta `sb_secret_...`.
3. Ejecuta o compila con:

   ```bash
   flutter run --dart-define-from-file=env/dev.json
   flutter build apk --debug --dart-define-from-file=env/dev.json
   ```

| Variable | Obligatoria | Uso |
|---|---|---|
| `SUPABASE_URL` | Sí | `https://mslcdvcmfuqopfwojxvt.supabase.co` |
| `SUPABASE_ANON_KEY` | Sí | Clave pública del cliente (protegida por RLS) |

Los deep links de los correos ya no se configuran aquí: son fijos en
`lib/nucleo/supabase/configuracion_supabase.dart` —
`capsoul://auth/confirmar` (confirmación de registro) y
`capsoul://auth/recuperar` (recuperar contraseña)— y deben estar en
*Authentication → URL Configuration → Redirect URLs* de Supabase. La antigua
variable `SUPABASE_URL_REDIRECCION` ya no se usa (puedes quitarla de tu
`env/dev.json`).

Si falta `SUPABASE_URL` o `SUPABASE_ANON_KEY`, la app no se cae: muestra la
pantalla de error de arranque e indica qué variable falta.
