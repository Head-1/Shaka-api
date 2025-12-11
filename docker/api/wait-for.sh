#!/bin/sh
# wait-for.sh - Aguardar serviços estarem prontos

set -e

host="$1"
shift
cmd="$@"

until nc -z "$host" 5432; do
  >&2 echo "PostgreSQL não está pronto - aguardando..."
  sleep 1
done

>&2 echo "PostgreSQL está pronto - executando comando"
exec $cmd
