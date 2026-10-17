# Capsoul

App Flutter de **cápsulas del tiempo** y **legado digital** (Android e iOS).

- **Documentación técnica:** [`docs/README.md`](docs/README.md)
- **Estado del código:** [`Memory.md`](Memory.md)
- **Backend:** Supabase (Auth, Postgres, Edge Functions) + Cloudinary + Firebase (solo FCM)

## Desarrollo local

1. Copiar `env/dev.json.example` → `env/dev.json` (no commitear).
2. `flutter pub get`
3. `flutter run --dart-define-from-file=env/dev.json`

Antes de probar legado, retos o música en un entorno remoto, aplicar migraciones hasta `20261016000015` (ver [`docs/migraciones.md`](docs/migraciones.md)).

## Calidad

```bash
flutter analyze
flutter test
```
