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

# wget -O patchelf.tar.gz "https://nixos.org/releases/patchelf/patchelf-0.9/patchelf-0.9.tar.gz"
# mkdir -p /Users/runner/local/patchelf
# tar -xf patchelf.tar.gz -C /Users/runner/local/patchelf --strip-components 1
# cd /Users/runner/local/patchelf
# wget -O config.guess "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=b8ee5f79949d1d40e8820a774d813660e1be52d3"
# wget -O config.sub "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=b8ee5f79949d1d40e8820a774d813660e1be52d3"
# ./configure --prefix=/usr/local
# make -j$(sysctl -n hw.physicalcpu)
# make install
brew install patchelf

wget -O postgresql.tar.bz2 "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2"
mkdir -p /Users/runner/local/postgresql
tar -xf postgresql.tar.bz2 -C /Users/runner/local/postgresql --strip-components 1
cd /Users/runner/local/postgresql
./configure \
    CFLAGS="-Os" \
    --prefix=/Users/runner/build/pg-build \
    --without-icu \
    --without-readline
make -j$(sysctl -n hw.physicalcpu) world-bin
make install-world-bin
make -C contrib install

mkdir -p /Users/runner/local/pgvector
curl -sL "https://github.com/pgvector/pgvector/archive/refs/tags/v$PGVECTOR_VERSION.tar.gz" | tar -xzf - -C /Users/runner/local/pgvector --strip-components 1
cd /Users/runner/local/pgvector
make -j$(sysctl -n hw.physicalcpu) OPTFLAGS=""
PG_CONFIG=/Users/runner/build/pg-build/bin/pg_config make install
