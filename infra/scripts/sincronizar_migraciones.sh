#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ORIGEN="$ROOT/supabase/migrations"
DESTINO="$ROOT/infra/migraciones/sql"

mkdir -p "$DESTINO"
cp -f "$ORIGEN"/*.sql "$DESTINO"/
echo "Migraciones sincronizadas en $DESTINO"
