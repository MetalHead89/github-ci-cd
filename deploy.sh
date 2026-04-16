#!/bin/bash

# =========================================
# 🚀 NU XT SSR DEPLOY SYSTEM (RELASE MODE)
# =========================================
# 💡 Эта система:
# - создаёт новый релиз (каталог)
# - переключает current атомарно
# - пересобирает Docker
# - чистит старые релизы (оставляет 3)
# =========================================

set -e

APP_DIR="/var/www/github-ci-cd"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"
SHARED_DIR="$APP_DIR/shared"

REPO_URL="$1"

# 🕒 уникальный ID релиза (гарантирует отсутствие конфликтов)
RELEASE=$(date +%Y%m%d_%H%M%S)

echo "======================================"
echo "🚀 DEPLOY START: $RELEASE"
echo "======================================"

# 0. Проверяем наличие .env в shared
if [ ! -f "$SHARED_DIR/.env" ]; then
    echo "⚠️  Warning: $SHARED_DIR/.env not found!"
    echo "Please create it first:"
    echo "  mkdir -p $SHARED_DIR"
    echo "  cp .env $SHARED_DIR/.env"
    exit 1
fi

# 1. создаём папку нового релиза
mkdir -p "$RELEASES_DIR/$RELEASE"

echo "📦 Creating release folder..."

# 2. клонируем код в релиз
# 💡 каждый релиз = полный снимок проекта
git clone "$REPO_URL" "$RELEASES_DIR/$RELEASE"

echo "⬇️ Code cloned into release"

# 2.1 копируем .env в релиз
echo "📄 Copying .env to release..."

cp "$SHARED_DIR/.env" "$RELEASES_DIR/$RELEASE/.env"

echo "✅ .env copied"

# =========================================
# 🆕 3. ОБНОВЛЯЕМ deploy.sh
# =========================================
# 💡 берём свежую версию deploy.sh из репозитория
# и кладём её в корень приложения

if [ -f "$RELEASES_DIR/$RELEASE/deploy.sh" ]; then
    echo "🔄 Updating deploy.sh..."

    cp "$RELEASES_DIR/$RELEASE/deploy.sh" "$APP_DIR/deploy.sh"

    # даём права на выполнение
    chmod +x "$APP_DIR/deploy.sh"

    echo "✅ deploy.sh updated"
else
    echo "⚠️ deploy.sh not found in repo, skipping update"
fi

# 4. пересборка Docker контейнера
# 💡 Nuxt SSR теперь собирается из новой версии кода
cd "$RELEASES_DIR/$RELEASE"

docker compose -f docker-compose.prod.yml up -d --build --remove-orphans

echo "🐳 Docker rebuilt and restarted"

# 5. атомарно переключаем current
# 💡 ln -sfn = без промежуточного состояния
ln -sfn "$RELEASES_DIR/$RELEASE" "$CURRENT_LINK"

echo "🔗 Switched current -> $RELEASE"

# 6. очистка старых релизов (оставляем только 3)
echo "🧹 Cleaning old releases..."

cd "$RELEASES_DIR"

ls -1dt */ | tail -n +4 | while read dir; do
  echo "🗑 Removing: $dir"
  rm -rf "$dir"
done

echo "======================================"
echo "✅ DEPLOY FINISHED"
echo "======================================"