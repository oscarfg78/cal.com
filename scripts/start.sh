#!/bin/sh
set -x

# Replace the statically built BUILT_NEXT_PUBLIC_WEBAPP_URL with run-time NEXT_PUBLIC_WEBAPP_URL
# NOTE: if these values are the same, this will be skipped.
scripts/replace-placeholder.sh "$BUILT_NEXT_PUBLIC_WEBAPP_URL" "$NEXT_PUBLIC_WEBAPP_URL"

# Railway provides DATABASE_URL, but Prisma in this schema needs DATABASE_DIRECT_URL too.
# If it's missing, we default it to DATABASE_URL.
if [ -z "$DATABASE_DIRECT_URL" ]; then
  export DATABASE_DIRECT_URL="$DATABASE_URL"
fi

if [ -n "$DATABASE_HOST" ]; then
  scripts/wait-for-it.sh ${DATABASE_HOST} -- echo "database is up"
fi

# Sincronizar el esquema de base de datos
npx prisma db push --accept-data-loss --schema /calcom/packages/prisma/schema.prisma

# Iniciar la aplicación. Railway asigna un puerto dinámico en la variable PORT.
# Usamos -- para pasar el argumento -p al script subyacente (next start).
yarn start -- -p ${PORT:-3000}
