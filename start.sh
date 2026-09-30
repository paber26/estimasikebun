#!/bin/bash
set -e

# Salin .env jika belum ada
if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
fi

# Generate key jika belum ada di environment
if [ -z "$APP_KEY" ]; then
    php artisan key:generate --force --no-interaction 2>/dev/null || true
fi

# Pastikan cache dan route siap
php artisan config:clear || true

# Jalankan server Laravel pada PORT Railway
echo "🚀 Memulai server pada port ${PORT:-8080}..."
exec php artisan serve --host=0.0.0.0 --port="${PORT:-8080}"
