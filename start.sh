#!/bin/sh

# Sincronizar el esquema de base de datos sin migraciones manuales
echo "Running prisma db push..."
npx prisma db push --accept-data-loss

# Iniciar la aplicación
echo "Starting application..."
node server.js
