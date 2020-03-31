#!/bin/sh
if [ -z "$POSTGRES_URL" ] && [ -z "$DATABASE_URL" ]; then
  if [ -z "$DB_PORT_5432_TCP_ADDR" ]; then
    echo "Set \$POSTGRES_URL or add db link"
    exit 1
  fi
  export POSTGRES_URL="postgres://postgres:@$DB_PORT_5432_TCP_ADDR:$DB_PORT_5432_TCP_PORT/detexify"
fi && rackup --host 0.0.0.0 --port $PORT
