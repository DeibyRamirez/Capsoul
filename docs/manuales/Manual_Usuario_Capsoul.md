# Capsoul

**Manual de Usuario**

Guía paso a paso para el usuario final — Versión de la app 1.0

| | |
|---|---|
| **Aplicación** | Capsoul para Android e iOS (versión 1.0.0) |
| **Dirigido a** | Personas que quieren guardar recuerdos y entregarlos en el tiempo |
| **Equipo** | Deiby Ramírez |
| **Versión del documento** | 1.0 — 1 de noviembre de 2026 |

## Contenido

1. Introducción
2. Requisitos
3. Instalación
4. Conceptos básicos
5. Mapa de navegación
6. Primeros pasos
7. Inicio
8. Recuerdos
9. Crear (botón +)
10. Momentos
11. Cápsulas
12. Mi legado
13. Retos
14. Yo, amigos y perfil
15. Música
16. Avisos
17. Limitaciones de la versión actual
18. Preguntas frecuentes
19. Glosario
20. Soporte

## 1. Introducción

Capsoul es una aplicación móvil para guardar lo que importa y abrirlo en el futuro: fotos, videos, notas de voz, cartas y canciones. Puedes sellar una **cápsula** para una fecha, armar un **momento** con recuerdos, dejar una **herencia** a quien amas o completar **retos** con amigos.

El lema de la app es *Pequeñas herencias, grandes recuerdos.*

Este manual explica cómo usar cada zona. Las descripciones salen de las pantallas reales (Flutter, Material 3, en español). Los recuadros `[CAPTURA DE PANTALLA]` marcan una imagen que puedes pegar al imprimir el documento.

## 2. Requisitos

| Requisito | Detalle |
|---|---|
| Dispositivo | Teléfono Android o iPhone compatible con la versión publicada de Capsoul. |
| Permisos | Cámara, micrófono y galería **solo** cuando tú capturas o eliges un archivo. Avisos (notificaciones) para enterarte de cápsulas y amistades. |
| Conexión | Internet para crear cuenta, guardar recuerdos, abrir cápsulas y buscar música. |
| Cuenta | Correo electrónico. Debes **confirmar el correo** antes de usar la app. |
| Contraseña | La que definas al registrarte; puedes recuperarla desde “¿Olvidaste tu contraseña?”. |

Capsoul no vende tus medios ni los usa para publicidad. Lo que subes queda ligado a tu cuenta.

## 3. Instalación

1. Instala Capsoul desde el archivo APK (Android) o el empaquetado iOS que te entregue el equipo, o desde la tienda cuando esté publicada. `[POR COMPLETAR: enlace de descarga oficial]`
2. En Android, si instalas un APK, permite orígenes desconocidos solo para esa instalación si el sistema lo pide.
3. Abre el icono de Capsoul.

`[CAPTURA DE PANTALLA: Icono de Capsoul en el teléfono]`

Figura: Icono de Capsoul en el teléfono

## 4. Conceptos básicos

- **Recuerdo:** un elemento que guardas (foto, video, audio, nota o canción). Vive en tu banco.
- **Cápsula:** un sello con fecha de apertura y destinatarios. Hasta esa fecha el contenido no se muestra a quien la recibe.
- **Momento:** una historia hecha con recuerdos, para compartir con tu círculo.
- **Herencia (legado):** lo que dejas para el futuro, con fecha, inactividad o confirmación de una persona de confianza.
- **Reto:** un desafío (diario, semanal o especial) que puedes completar.
- **Amistad:** red cercana. No hay un feed público tipo red social en Inicio.

## 5. Mapa de navegación

Hay un flujo de acceso (registro, confirmar correo, iniciar sesión) y un área principal con **cinco zonas** en la barra inferior.

```
[Registro / Correo / Login]
        |
        v
[Inicio]  [Momentos]  [ + Crear ]  [Mi legado]  [Yo]
              |                         |
         detalle momento          herencias / seguridad
```

El botón **+** no cambia de pestaña: abre el selector para grabar video, audio, escribir, tomar foto o buscar música.

`[CAPTURA DE PANTALLA: Barra de navegación inferior]`

Figura: Barra de navegación inferior

## 6. Primeros pasos

### 6.1 Crear cuenta

1. En la pantalla de registro escribe tu nombre visible, correo y contraseña.
2. Elige un **nombre de usuario** (@) si la pantalla lo pide.
3. Toca **Crear cuenta**.
4. Abre el correo de Capsoul y confirma el enlace.

Si no confirmas el correo, no entra la sesión. Revisa también la carpeta de spam.

`[CAPTURA DE PANTALLA: Pantalla Crear cuenta]`

Figura: Pantalla Crear cuenta

| Mensaje | Qué hacer |
|---|---|
| Escribe un correo válido | Revisa que lleve @. |
| Confirma tu correo | Abre el enlace que te enviamos. |
| Ese correo ya está registrado | Usa **Iniciar sesión**. |

### 6.2 Iniciar sesión

1. Escribe correo y contraseña.
2. Toca **Iniciar sesión**.
3. Si olvidaste la clave, usa **¿Olvidaste tu contraseña?** y sigue el correo.

`[CAPTURA DE PANTALLA: Pantalla Iniciar sesión]`

Figura: Pantalla Iniciar sesión

### 6.3 Revisar el correo

Después del registro verás *Revisa tu correo*. Cuando confirmes, vuelve a la app e inicia sesión. Puedes pedir que reenvíen el mensaje.

## 7. Inicio

Muestra la cúpula de vidrio, el botón **Guardar algo hoy**, cuatro tarjetas (Recuerdos, Retos, Cápsulas, Pequeñas herencias) con el conteo de cada una, y la frase de Capsoul.

- **Guardar algo hoy** abre el mismo selector que el **+**.
- Tocar una tarjeta lleva a esa sección (Mi legado cambia de pestaña).
- La campana abre los **avisos**.

`[CAPTURA DE PANTALLA: Pantalla Inicio]`

Figura: Pantalla Inicio

## 8. Recuerdos

Tu banco privado. Filtra por tipo (fotos, videos, notas, música…) y por fecha.

1. Entra desde Inicio o desde Crear.
2. Toca un recuerdo para verlo a pantalla completa.
3. Desde el menú del visor puedes editar o borrar (si no está sellado en una cápsula).

Para **guardar** uno nuevo, usa Crear (+) o *Guardar algo hoy*: captura o elige el archivo, ponle título y fecha, y toca **Guardar recuerdo**.

`[CAPTURA DE PANTALLA: Banco de recuerdos]`

Figura: Banco de recuerdos

## 9. Crear (botón +)

El selector ofrece Video, Audio, Escribir, Foto y Música (según la versión).

1. Toca **+** o **Guardar algo hoy**.
2. Elige el tipo.
3. Captura o escribe.
4. En **Guardar recuerdo** revisa título y fecha y confirma.

Las notas permiten formato: selecciona un fragmento y aplica Normal, Negrita, Cursiva o Subrayado. Máximo 5000 caracteres.

`[CAPTURA DE PANTALLA: Selector Crear]`

Figura: Selector Crear

## 10. Momentos

Agrupa recuerdos en una historia (nombre y descripción) y elige cuáles incluir.

1. Abre la pestaña **Momentos** o crea uno nuevo.
2. Pon nombre, elige recuerdos y guarda.
3. En el detalle puedes ver la historia. El autor puede borrarla.

Los momentos son para tu círculo, no un muro público.

`[CAPTURA DE PANTALLA: Nuevo momento]`

Figura: Nuevo momento

## 11. Cápsulas

Una cápsula guarda recuerdos para abrirlos **después**.

1. Desde Crear elige **Cápsula del tiempo**, o entra a **Cápsulas** desde Inicio.
2. Elige recuerdos ya guardados o captura uno nuevo.
3. Pon fecha de apertura (en el futuro) y destinatarios (tú y/o amigos).
4. Guarda. Hasta la fecha, quien la recibe no ve el contenido.

Pestañas típicas: *Mis cápsulas*, *Para mí mismo*, *Para mí* (las que te enviaron).

`[CAPTURA DE PANTALLA: Nueva cápsula]`

Figura: Nueva cápsula

Cuando llega el día, la cápsula se **libera**. Ábrela, mira los recuerdos y márcala como abierta si la app lo pide.

## 12. Mi legado

Prepara lo que dejas: herencias con recuerdos y, si quieres, cápsulas vinculadas.

1. Abre **Mi legado**.
2. Revisa **Todo está protegido** (seguridad y persona de confianza).
3. Toca **Nueva** para el asistente de herencia: a quién, qué recuerdos, cuándo se activa.
4. La persona de confianza debe ser un **amigo**; puede confirmar cuando corresponda.

`[CAPTURA DE PANTALLA: Mi legado]`

Figura: Mi legado

## 13. Retos

Lista de retos activos, completados y favoritos (diario, semanal, especial).

1. Entra desde Inicio o el menú de retos.
2. Lee el título y los pasos.
3. Completa el reto según las instrucciones de la pantalla.

`[CAPTURA DE PANTALLA: Retos]`

Figura: Retos

## 14. Yo, amigos y perfil

La pestaña **Yo** muestra tu perfil, foto, estadísticas y momentos.

- Edita nombre y foto desde el perfil.
- **Amigos:** busca por @ exacto, envía solicitud, acepta o rechaza las que te llegan.
- **Cerrar sesión** está en el perfil.

Sin amigos no podrás elegir destinatarios de cápsula ni persona de confianza de legado.

`[CAPTURA DE PANTALLA: Perfil]`

Figura: Perfil

## 15. Música

Puedes guardar una canción como recuerdo o añadirla a una foto.

1. En Crear elige música, o **Añadir música** al guardar una foto.
2. Escribe artista o canción. Los resultados vienen de Deezer.
3. Escucha el **preview de 30 s** y elige la pista.
4. Para la canción completa usa *Abrir en Deezer* u otras búsquedas (Spotify, YouTube).

Aparece el crédito “Música de Deezer”. El clip corto no sustituye a la app de música.

`[CAPTURA DE PANTALLA: Buscar música]`

Figura: Buscar música

## 16. Avisos

La campana de Inicio lista avisos (cápsula recibida, solicitud de amistad, legado, etc.).

Activa las notificaciones del sistema si quieres enterarte con el teléfono bloqueado. En Android 13+ Capsoul pide permiso de avisos.

## 17. Limitaciones de la versión actual

- Hace falta internet para guardar y para abrir medios del servidor.
- El correo debe estar confirmado.
- La música completa se escucha en Deezer u otra app, no dentro de Capsoul.
- Un recuerdo que ya está en una cápsula sellada no se puede borrar.
- Esta versión no sustituye un testamento notarial: el legado digital es el acuerdo entre tú y quien reciba Capsoul.

## 18. Preguntas frecuentes

**¿Por qué no entra después de registrarme?**  
Confirma el correo y vuelve a iniciar sesión.

**¿Quién ve mis recuerdos?**  
Tú. En una cápsula, los destinatarios **después** de la fecha. En un momento o herencia, según a quién hayas elegido.

**¿Puedo usar Capsoul sin cámara?**  
Sí: elige archivos de la galería o escribe una nota.

**¿Qué pasa si pierdo el teléfono?**  
Entras con el mismo correo en otro dispositivo. Los recuerdos están en tu cuenta, no solo en el aparato.

**¿Los avisos no llegan?**  
Revisa el permiso de notificaciones y que tengas sesión iniciada.

## 19. Glosario

| Término | Significado |
|---|---|
| Cápsula | Paquete sellado con fecha de apertura |
| Recuerdo | Foto, video, audio, nota o canción guardada |
| Momento | Historia con varios recuerdos |
| Herencia | Legado digital para el futuro |
| Persona de confianza | Amigo que puede confirmar tu legado |
| Preview | Fragmento de 30 s de una canción (Deezer) |
| @ | Nombre de usuario para buscar amigos |

## 20. Soporte

Escribe a quien te entregó la app (equipo Capsoul / Deiby Ramírez) indicando:

- Qué pantalla estabas usando
- El mensaje de error, si lo hubo
- Modelo del teléfono y si es Android o iOS

No envíes tu contraseña por correo.

---

*Capsoul — Manual de Usuario 1.0 — Deiby Ramírez — 1 de noviembre de 2026*
