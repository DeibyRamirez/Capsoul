#!/usr/bin/env bash
# Aplica todas las migraciones y corre supabase/pruebas contra Postgres local.
# Falla si una aserción lanza excepción. No usa el Supabase remoto.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PSQL=(sudo -u postgres psql -v ON_ERROR_STOP=1 -d postgres -X)

echo "Reiniciando esquemas locales"
"${PSQL[@]}" -f "$ROOT/supabase/pruebas/preparar_reinicio.sql"
"${PSQL[@]}" -f "$ROOT/supabase/pruebas/preparar_auth_local.sql"

for migracion in "$ROOT"/supabase/migrations/*.sql; do
  echo "Aplicando $(basename "$migracion")"
  "${PSQL[@]}" -f "$migracion"
done

for prueba in "$ROOT"/supabase/pruebas/pruebas_*.sql; do
  echo "Prueba $(basename "$prueba")"
  "${PSQL[@]}" -f "$prueba"
done

echo "Pruebas SQL en verde"
