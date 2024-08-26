#!/bin/bash
set -ex

LITE_OPT=false
PGVECTOR_VERSION=0.7.4

while getopts "v:i:g:o:e:l" opt; do
    case $opt in
    v) PG_VERSION=$OPTARG ;;
    e) PGVECTOR_VERSION=$OPTARG ;;
    \?) exit 1 ;;
    esac
done

if [ -z "$PG_VERSION" ] ; then
  echo "Postgres version parameter is required!" && exit 1;
fi
if echo "$PG_VERSION" | grep -q '^9\.' && [ "$LITE_OPT" = true ] ; then
  echo "Lite option is supported only for PostgreSQL 10 or later!" && exit 1;
fi

echo "Starting building postgres binaries"

wget -O postgresql.tar.bz2 "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2"
mkdir -p /opt/local/postgresql
tar -xf postgresql.tar.bz2 -C /opt/local/postgresql --strip-components 1
cd /opt/local/postgresql
./configure \
    CFLAGS="-Os" \
    LDFLAGS="-static" \
    --prefix=/usr/local/pg-build \
    --without-icu \
    --without-readline \
    --without-zlib
make -j$(sysctl -n hw.physicalcpu) world
make install-world
make -C contrib install

mkdir -p /opt/local/pgvector
curl -sL "https://github.com/pgvector/pgvector/archive/refs/tags/v$PGVECTOR_VERSION.tar.gz" | tar -xzf - -C /opt/local/pgvector --strip-components 1
cd /opt/local/pgvector
make -j$(sysctl -n hw.physicalcpu) OPTFLAGS=""
PG_CONFIG=/usr/local/pg-build/bin/pg_config make install
