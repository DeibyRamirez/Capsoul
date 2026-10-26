#!/usr/bin/env bash
# Prepara Postgres 16 con pg_cron y pg_net en la máquina local o en CI.
# No imprime secretos y no habla con Supabase remoto.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y \
  postgresql-16 \
  postgresql-16-cron \
  postgresql-contrib \
  postgresql-server-dev-16 \
  libcurl4-openssl-dev \
  build-essential \
  git \
  ca-certificates

if ! [ -f /usr/lib/postgresql/16/lib/pg_net.so ]; then
  tmp="$(mktemp -d)"
  git clone --depth 1 --branch v0.14.0 https://github.com/supabase/pg_net.git "$tmp/pg_net"
  make -C "$tmp/pg_net" install
  rm -rf "$tmp"
fi

conf="$(sudo -u postgres psql -Atqc 'show config_file')"
if ! sudo grep -q "^shared_preload_libraries" "$conf"; then
  echo "shared_preload_libraries = 'pg_cron,pg_net'" | sudo tee -a "$conf" >/dev/null
else
  sudo sed -i "s/^shared_preload_libraries.*/shared_preload_libraries = 'pg_cron,pg_net'/" "$conf"
fi
if ! sudo grep -q "^cron.database_name" "$conf"; then
  echo "cron.database_name = 'postgres'" | sudo tee -a "$conf" >/dev/null
fi

hba="$(sudo -u postgres psql -Atqc 'show hba_file')"
if ! sudo grep -q "127.0.0.1/32 trust" "$hba"; then
  echo "host all postgres 127.0.0.1/32 trust" | sudo tee -a "$hba" >/dev/null
fi

sudo pg_ctlcluster 16 main restart || sudo service postgresql restart
