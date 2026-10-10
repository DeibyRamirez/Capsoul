#!/usr/bin/env bash
# Aplica migraciones SQL en un VPS con dbmate.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SQL_DIR="$ROOT/infra/migraciones/sql"

"$ROOT/infra/scripts/sincronizar_migraciones.sh" 2>/dev/null || \
  powershell.exe -File "$ROOT/infra/scripts/sincronizar_migraciones.ps1" || true

if [ -z "${DATABASE_URL:-}" ]; then
  echo "Define DATABASE_URL antes de ejecutar este script."
  exit 1
fi

dbmate -d "$ROOT/infra/migraciones/db" up
echo "Migraciones aplicadas."
