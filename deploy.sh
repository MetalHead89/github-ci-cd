#!/bin/bash

# =========================================
# 🚀 NU XT SSR DEPLOY SYSTEM (RELEASE MODE)
# =========================================
# 💡 Эта система:
# - пересобирает Docker
# - переключает current атомарно
# - чистит старые релизы (оставляет 3)
# =========================================

set -e

APP_DIR="/var/www/github-ci-cd"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"

RELEASE="$1"

echo "======================================"
echo "🚀 RELEASE DEPLOY START: $RELEASE"
echo "======================================"

cd "$RELEASES_DIR/$RELEASE"

# 1. пересборка Docker контейнера
# 💡 Nuxt SSR теперь собирается из новой версии кода
docker compose -f docker-compose.prod.yml up -d --build --remove-orphans

echo "🐳 Docker rebuilt and restarted"

# 2. атомарно переключаем current
# 💡 ln -sfn = без промежуточного состояния
ln -sfn "$RELEASES_DIR/$RELEASE" "$CURRENT_LINK"

echo "🔗 Switched current -> $RELEASE"

# 3. очистка старых релизов (оставляем только 3)
echo "🧹 Cleaning old releases..."

cd "$RELEASES_DIR"

ls -1dt */ | tail -n +4 | while read dir; do
echo "🗑 Removing: $dir"
rm -rf "$dir"
done

echo "======================================"
echo "✅ RELEASE DEPLOY FINISHED"
echo "======================================"