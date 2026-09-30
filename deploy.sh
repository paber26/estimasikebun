#!/bin/bash
# 🚀 Deploy estimasi -> SERVER DOCKER (203.145.35.13)
# Subdomain: estimasikebun.kuydinas.id
set -e

SERVER_HOST="203.145.35.13"
SERVER_USER="tmc"
APP_PATH="/var/www/estimasikebun.kuydinas.id"
REPO_URL="https://github.com/paber26/estimasikebun.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/.env.deploy" ]; then
  set -a
  . "${SCRIPT_DIR}/.env.deploy"
  set +a
fi
: "${DEPLOY_SUDO_PASS:?DEPLOY_SUDO_PASS belum diset. Buat .env.deploy dari .env.deploy.example}"

echo "🚀 Menghubungkan ke server $SERVER_HOST (Deploy estimasikebun.kuydinas.id)..."

SSH_PREFIX=()
if command -v sshpass >/dev/null 2>&1 && [ -n "${DEPLOY_SUDO_PASS}" ]; then
  SSH_PREFIX=(sshpass -p "${DEPLOY_SUDO_PASS}")
fi

"${SSH_PREFIX[@]}" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no ${SERVER_USER}@${SERVER_HOST} "echo '${DEPLOY_SUDO_PASS}' | sudo -S bash -c '
set -e

echo \"➡️ [1/5] Memastikan direktori target $APP_PATH...\"
if [ ! -d \"$APP_PATH/.git\" ]; then
  echo \"   Cloning repository baru dari $REPO_URL...\"
  git clone $REPO_URL $APP_PATH
  cd $APP_PATH
else
  cd $APP_PATH
  echo \"   Pulling pembaruan dari Git...\"
  git stash 2>/dev/null || true
  git pull origin main
fi

echo \"➡️ [2/5] Konfigurasi .env server...\"
if [ ! -f .env ]; then
  cp .env.example .env
  sed -i \"s|APP_URL=http://localhost|APP_URL=https://estimasikebun.kuydinas.id|g\" .env
  sed -i \"s|DB_CONNECTION=.*|DB_CONNECTION=sqlite|g\" .env
fi

echo \"➡️ [3/5] Persiapan Database SQLite & Permissions...\"
touch database/database.sqlite
if [ -f kebun_simulasi.sqlite ] && [ ! -s database/database.sqlite ]; then
  cp kebun_simulasi.sqlite database/database.sqlite
fi
chown -R www-data:www-data storage bootstrap/cache database 2>/dev/null || chown -R tmc:tmc storage bootstrap/cache database 2>/dev/null || true
chmod -R 775 storage bootstrap/cache database 2>/dev/null || true

echo \"➡️ [4/5] Memasang konfigurasi Nginx vhost...\"
mkdir -p /srv/tmc/nginx/conf.d
cp -f docker/nginx/estimasikebun.conf /srv/tmc/nginx/conf.d/estimasikebun.conf 2>/dev/null || cp -f docker/nginx/estimasikebun.conf /srv/tmc/nginx/estimasikebun.conf 2>/dev/null || true

echo \"➡️ [5/5] Reload Nginx...\"
docker exec tmc-nginx nginx -s reload 2>/dev/null || true

echo \"🎉 Selesai! Subdomain estimasikebun.kuydinas.id telah dikonfigurasi.\"
'"
