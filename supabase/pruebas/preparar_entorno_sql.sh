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

pg_config_bin="$(command -v pg_config)"
compartido="$("$pg_config_bin" --sharedir)/extension"
# El .so puede quedar instalado sin pg_net--0.14.0.sql: el Makefile arma
# DATA con un comodín antes de generar ese script, y CREATE EXTENSION
# entonces no encuentra la versión 0.14.0.
if ! [ -f /usr/lib/postgresql/16/lib/pg_net.so ] || ! [ -f "$compartido/pg_net--0.14.0.sql" ]; then
  tmp="$(mktemp -d)"
  git clone --depth 1 --branch v0.14.0 https://github.com/supabase/pg_net.git "$tmp/pg_net"
  cp "$tmp/pg_net/sql/pg_net.sql" "$tmp/pg_net/sql/pg_net--0.14.0.sql"
  # El Postgres de Ubuntu trae LLVM y el bitcode llama a clang de la misma
  # versión con la que se compiló (en el runner, /usr/bin/clang-19). pg_net no
  # necesita JIT: with_llvm=no omite ese paso y el job no depende de ese clang.
  sudo make -C "$tmp/pg_net" with_llvm=no PG_CONFIG="$pg_config_bin" install
  sudo install -m 644 "$tmp/pg_net/sql/pg_net--0.14.0.sql" "$compartido/pg_net--0.14.0.sql"
  rm -rf "$tmp"
fi

# En el runner el paquete ya está instalado, pero el clúster no arranca solo.
if ! sudo pg_isready -q; then
  if ! sudo pg_lsclusters --no-header | grep -q '^16[[:space:]]\+main'; then
    sudo pg_createcluster 16 main --start
  else
    sudo pg_ctlcluster 16 main start
  fi
fi
sudo pg_isready -q

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
