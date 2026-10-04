# Capsoul · Flujos críticos

## 1. Arranque de la app

```mermaid
sequenceDiagram
    participant Main as main.dart
    participant FB as inicializarFirebase
    participant FCM as servicio_notificaciones_push
    participant SB as inicializarSupabase
    participant App as AppCapsoul

    Main->>FB: await
    alt Firebase OK
        Main->>FCM: inicializarNotificacionesPush()
        Note over FCM: Solo Android/iOS, try/catch
    end
    Main->>SB: await
    alt error Supabase
        Main->>App: AppErrorArranque
    else OK
        Main->>App: ProviderScope + AppCapsoul
    end
```

**Archivos:** `lib/main.dart`, `lib/nucleo/firebase/`, `lib/nucleo/supabase/arranque_supabase.dart`

## 2. Autenticación y sesión

```mermaid
sequenceDiagram
    actor U as Usuario
    participant UI as Pantalla login
    participant Auth as RepositorioAutenticacion
    participant SB as Supabase Auth
    participant Router as go_router

    U->>UI: correo + contraseña
    UI->>Auth: iniciarSesion()
    Auth->>SB: signInWithPassword
    SB-->>Auth: JWT + sesión
    Auth-->>Router: onAuthStateChange
    Router->>UI: redirige a /inicio
    Note over SB: Trigger crea fila en usuarios
```

- Sin sesión → rutas de auth (`/iniciar-sesion`, `/registro`, …).
- Con sesión → shell principal (`/inicio`, …).
- **Archivos:** `funcionalidades/autenticacion/`, `nucleo/enrutador/enrutador_app.dart`

## 3. Subida de un medio (recuerdo)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant App as Flutter
    participant EF as firmar-subida
    participant CDN as Cloudinary
    participant PG as Postgres

    U->>App: Captura foto/video/audio o escribe nota
    App->>EF: invoke(tipo, JWT)
    EF-->>App: firma + public_id
    App->>CDN: POST upload firmado
    CDN-->>App: metadatos
    App->>PG: INSERT elementos
```

**Archivos:** `funcionalidades/elementos/`, `funcionalidades/recuerdos/`, `supabase/functions/firmar-subida/`

## 4. Apertura de cápsula (destinatario)

1. `rpc capsulas_recibidas()` — feed sin título hasta liberar.
2. Tras `fecha_apertura`, estado `liberada`.
3. `select` cápsula + elementos (RLS).
4. `firmar-medio` → URL temporal → reproducción.
5. `rpc marcar_capsula_abierta(id)`.

Ver diagrama completo en [arquitectura.md](arquitectura.md) sección 4.

## 5. Crear un momento

```mermaid
sequenceDiagram
    actor U as Usuario
    participant UI as PantallaNuevoMomento
    participant Repo as RepositorioMomentos
    participant PG as Postgres

    U->>UI: título, recuerdos elegidos, portada
    UI->>Repo: crear(NuevoMomento)
    Repo->>PG: INSERT momentos
    Repo->>PG: INSERT momento_elementos
    Repo->>PG: UPDATE portada_elemento_id
    Repo-->>UI: id del momento
```

**Archivos:** `funcionalidades/momentos/`, tabla `momentos` + `momento_elementos`

## 6. Perfil vs pestaña Momentos (UI)

| Pantalla | Comportamiento |
|---|---|
| **Yo (Perfil)** | Cabecera Instagram + destacados + búsqueda/filtros + rejilla 2 columnas de momentos |
| **Momentos** | Feed vertical: cada tarjeta = un momento con carrusel horizontal de recuerdos |

Ambas leen `proveedorMomentos`; el filtro en memoria (`proveedorFiltroMomentos`) solo aplica en Perfil.
