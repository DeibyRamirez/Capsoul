# Arquitectura de Capsoul (ARQ-2)

> Documento vivo. Describe la arquitectura de la app Flutter y la infraestructura serverless de Firebase
> (proyecto `capsoul-ebea3`). Última actualización: 2026-09-26.

## 1. Vista general

Capsoul es una app Flutter (Android e iOS) sin servidor propio: toda la persistencia, autenticación,
lógica programada y notificaciones viven en Firebase. La app sigue una estructura por funcionalidades
(`lib/funcionalidades/<funcionalidad>/`) con cuatro capas y código compartido en `lib/nucleo/`.

```mermaid
flowchart TB
    subgraph Dispositivo["📱 App Flutter (Android / iOS)"]
        direction TB
        subgraph Presentacion["Capa de presentación"]
            Pantallas["Pantallas y componentes<br/>(PantallaInicio, PantallaIniciarSesion,<br/>PantallaPerfil, ContenedorNavegacion…)"]
            Enrutador["go_router<br/>(RutasApp, redirección por sesión,<br/>StatefulShellRoute)"]
        end
        subgraph Aplicacion["Capa de aplicación"]
            Proveedores["Riverpod<br/>(proveedores y controladores:<br/>ControladorInicioSesion, ControladorPerfil…)"]
        end
        subgraph Dominio["Capa de dominio"]
            Modelos["Modelos y contratos<br/>(UsuarioApp, PerfilUsuario,<br/>RepositorioAutenticacion, RepositorioUsuarios,<br/>FalloAutenticacion)"]
        end
        subgraph Datos["Capa de datos"]
            Repos["Repositorios Firebase<br/>(RepositorioAutenticacionFirebase,<br/>RepositorioUsuariosFirestore,<br/>futuro RepositorioCapsulas)"]
        end
        Pantallas --> Proveedores
        Enrutador --> Proveedores
        Proveedores --> Modelos
        Repos -. implementa .-> Modelos
        Proveedores --> Repos
    end

    subgraph Firebase["☁️ Firebase (capsoul-ebea3)"]
        direction TB
        Auth["Firebase Auth<br/>(correo y contraseña)"]
        Firestore["Cloud Firestore<br/>(usuarios/{uid}, capsulas/{id})<br/>+ Security Rules"]
        Storage["Firebase Storage<br/>(capsulas/{idCapsula}/{idMedio})<br/>+ Storage Rules"]
        Functions["Cloud Functions<br/>(función programada liberarCapsulas,<br/>disparadores de avisos)"]
        Scheduler["Cloud Scheduler<br/>(cron diario / horario)"]
        FCM["Firebase Cloud Messaging<br/>(notificaciones push)"]
    end

    Correo["✉️ Servicio de correo<br/>(plantillas de Firebase Auth para verificación<br/>y recuperación; extensión Trigger Email / SMTP<br/>para avisos de cápsulas)"]

    Repos -- "SDK firebase_auth" --> Auth
    Repos -- "SDK cloud_firestore" --> Firestore
    Repos -- "SDK firebase_storage" --> Storage
    Proveedores -- "firebase_messaging<br/>(token del dispositivo)" --> FCM

    Auth -- "verificación y recuperación<br/>de contraseña" --> Correo
    Scheduler -- "dispara" --> Functions
    Functions -- "Admin SDK: lee y actualiza cápsulas" --> Firestore
    Functions -- "Admin SDK: habilita medios" --> Storage
    Functions -- "envía push" --> FCM
    Functions -- "encola avisos" --> Correo
    FCM -- "notificación" --> Dispositivo
```

## 2. Flujo de liberación de una cápsula

La liberación nunca depende del reloj del teléfono: las Security Rules comparan `fechaLiberacion` con
`request.time` y una Cloud Function programada cambia el estado y avisa a los destinatarios.

```mermaid
sequenceDiagram
    autonumber
    actor Autor as Autor (app)
    participant App as App Flutter
    participant FS as Cloud Firestore
    participant ST as Firebase Storage
    participant SCH as Cloud Scheduler
    participant CF as Cloud Function liberarCapsulas
    participant FCM as FCM
    participant MAIL as Servicio de correo
    actor Dest as Destinatario

    Autor->>App: Crea cápsula (medios + fechaLiberacion + destinatarios)
    App->>ST: Sube medios a capsulas/{id}/{idMedio}
    App->>FS: Crea capsulas/{id} con estado "sellada"
    Note over FS,ST: Las reglas niegan leer contenido y medios<br/>si request.time < fechaLiberacion

    loop Cada hora (cron)
        SCH->>CF: Dispara la función programada
        CF->>FS: Consulta cápsulas "sellada" con fechaLiberacion <= ahora
        alt Hay cápsulas vencidas
            CF->>FS: Transacción: estado = "liberada", liberadaEn = serverTimestamp
            CF->>FCM: Envía push a los tokens de los destinatarios
            CF->>MAIL: Encola correo "Tienes una cápsula nueva"
        else No hay cápsulas vencidas
            CF-->>SCH: Termina sin cambios
        end
    end

    FCM-->>Dest: Notificación push
    MAIL-->>Dest: Correo de aviso
    Dest->>App: Abre la cápsula
    App->>FS: Lee capsulas/{id} (reglas: liberada y es destinatario)
    App->>ST: Descarga medios (reglas: misma condición)
```

## 3. Componentes

| Componente | Responsabilidad |
|---|---|
| **Capa de presentación** (`presentacion/`) | Pantallas y componentes en español con el tema de marca (`TemaApp`, `ColoresApp`). No llama a Firebase: solo lee y dispara acciones de los proveedores. |
| **go_router** (`lib/nucleo/enrutador/`) | Rutas en español (`/inicio`, `/momentos`, `/crear`, `/legado`, `/yo`, `/iniciar-sesion`, `/registro`, `/recuperar`). `StatefulShellRoute` conserva el estado de cada pestaña; la redirección envía a `/iniciar-sesion` sin sesión y al contenedor principal con sesión. El `+` hace *push* de `/crear`. |
| **Capa de aplicación** (`aplicacion/`) | Proveedores y controladores de Riverpod (`Notifier` con estados cargando / datos / error). Orquestan casos de uso: registrar usuario y crear su perfil, iniciar sesión, recuperar contraseña, editar perfil. |
| **Capa de dominio** (`dominio/`) | Modelos inmutables (`UsuarioApp`, `PerfilUsuario`), contratos abstractos (`RepositorioAutenticacion`, `RepositorioUsuarios`) y fallos con mensaje en español (`FalloAutenticacion`, `FalloPerfilUsuario`). No depende de Firebase. |
| **Capa de datos** (`datos/`) | Implementaciones de los contratos con los SDK de Firebase. Traducen excepciones de Firebase a fallos de dominio. Se inyectan por proveedores para poder simularlas en pruebas. |
| **Firebase Auth** | Cuentas con correo y contraseña, sesión persistente (`authStateChanges`), verificación de correo y restablecimiento de contraseña. |
| **Cloud Firestore** | Datos estructurados con campos en español: `usuarios/{uid}` (`nombreVisible`, `correo`, `fotoUrl`, `creadoEn`) y, desde el S4, `capsulas/{id}` (`idDueno`, `idsDestinatarios`, `fechaLiberacion`, `estado`, `privacidad`). Las Security Rules son la fuente de verdad (deny by default). |
| **Firebase Storage** | Medios de las cápsulas (video, audio, foto) en `capsulas/{idCapsula}/{idMedio}`, protegidos con la misma condición de liberación que Firestore. |
| **Cloud Functions** | Lógica privilegiada con Admin SDK: función programada `liberarCapsulas` (vía Cloud Scheduler) que marca como liberadas las cápsulas vencidas y dispara los avisos; limpieza de medios al borrar cápsulas. Nunca se incrustan credenciales de administrador en la app. |
| **FCM** | Notificaciones push a los destinatarios cuando una cápsula se libera (tokens por usuario, sin temas globales que filtren datos). |
| **Servicio de correo** | Correos de verificación y recuperación con las plantillas de Firebase Auth (en español); avisos de cápsulas liberadas mediante la extensión *Trigger Email* o un proveedor SMTP llamado desde Cloud Functions. |

## 4. Estado actual (Sprint 2)

- Implementado: capas de presentación, aplicación, dominio y datos para autenticación y perfil;
  Firebase Auth; Firestore `usuarios/{uid}` con reglas de dueño.
- Pendiente (S4 en adelante): `capsulas/{id}`, Storage con reglas de liberación, Cloud Functions
  (`functions/`), FCM y avisos por correo.
