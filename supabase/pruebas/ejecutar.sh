#!/usr/bin/env bash
# Aplica todas las migraciones y corre supabase/pruebas contra Postgres local.
# Falla si una aserción lanza excepción. No usa el Supabase remoto.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# psql corre como el usuario postgres. En el runner, /home/runner no se puede
# atravesar (Permission denied al abrir el .sql). /tmp sí.
trabajo="$(mktemp -d)"
chmod 755 "$trabajo"
cp -a "$ROOT/supabase/migrations" "$trabajo/migrations"
cp -a "$ROOT/supabase/pruebas" "$trabajo/pruebas"
chmod -R a+rX "$trabajo"
trap 'rm -rf "$trabajo"' EXIT

PSQL=(sudo -u postgres psql -v ON_ERROR_STOP=1 -d postgres -X)

echo "Reiniciando esquemas locales"
"${PSQL[@]}" -f "$trabajo/pruebas/preparar_reinicio.sql"
"${PSQL[@]}" -f "$trabajo/pruebas/preparar_auth_local.sql"

for migracion in "$trabajo"/migrations/*.sql; do
  echo "Aplicando $(basename "$migracion")"
  "${PSQL[@]}" -f "$migracion"
done

for prueba in "$trabajo"/pruebas/pruebas_*.sql; do
  echo "Prueba $(basename "$prueba")"
  "${PSQL[@]}" -f "$prueba"
done

echo "Pruebas SQL en verde"
