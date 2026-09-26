# Skills del proyecto Capsoul

Esta carpeta contiene las skills de agente específicas del proyecto Capsoul. Cada skill vive en su propia carpeta con un archivo `SKILL.md` que Cursor (y otros agentes compatibles) cargan como contexto cuando la tarea coincide con su descripción.

## Skills del proyecto

| Skill | Propósito |
| --- | --- |
| [`capsoul-flutter-architecture`](capsoul-flutter-architecture/SKILL.md) | Estructura feature-first, enrutamiento y separación de capas de la app Flutter. |
| [`capsoul-ui-design-system`](capsoul-ui-design-system/SKILL.md) | Marca congelada (navy `#1B2A4A`, acento `#3D6B9A`, cúpula), tema centralizado y navegación inferior de 5 zonas. |
| [`capsoul-firebase-integrity`](capsoul-firebase-integrity/SKILL.md) | Modelo de amenazas, Auth y Security Rules para que el contenido sellado no se filtre antes de `unlockDate`. |
| [`capsoul-firestore-storage`](capsoul-firestore-storage/SKILL.md) | Repositorios de Cloud Firestore y Firebase Storage: rutas, consultas, subidas y manejo de errores. |
| [`capsoul-flutter-clean-code`](capsoul-flutter-clean-code/SKILL.md) | Principios, patrones y buenas prácticas de Dart/Flutter para escribir y revisar código mantenible. |
| [`capsoul-sprint-dod`](capsoul-sprint-dod/SKILL.md) | Forma de las historias de usuario y Definition of Done general y del Sprint 1. |

## Skills oficiales recomendadas (skills.sh)

> **Estado: pendiente (S1-07).** Todavía no están instaladas en el repositorio; se instalarán como parte de la tarea S1-07.

| Paquete | Uso previsto |
| --- | --- |
| `flutter/agent-plugins` | Skills oficiales de Flutter/Dart (buenas prácticas, widgets, pruebas). |
| `firebase/agent-skills` | Skills oficiales de Firebase (Auth, Firestore, Storage, Security Rules). |
| `dhruvanbhalara/skills` (skill `flutter-firebase`) | Integración Flutter + Firebase (FlutterFire, inicialización y patrones comunes). |

### Cómo instalarlas

Desde la raíz del repositorio:

```bash
npx skills add flutter/agent-plugins
npx skills add firebase/agent-skills
npx skills add dhruvanbhalara/skills
```

Después de instalarlas, revisa los archivos agregados antes de hacer commit y confirma que no incluyan secretos.
