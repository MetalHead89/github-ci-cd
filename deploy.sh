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

REPO_URL="$1"

# 🕒 уникальный ID релиза (гарантирует отсутствие конфликтов)
RELEASE=$(date +%Y%m%d_%H%M%S)

echo "======================================"
echo "🚀 DEPLOY START: $RELEASE"
echo "======================================"

# 1. создаём папку нового релиза
mkdir -p "$RELEASES_DIR/$RELEASE"

echo "📦 Creating release folder..."

# 2. клонируем код в релиз
# 💡 каждый релиз = полный снимок проекта
git clone "$REPO_URL" "$RELEASES_DIR/$RELEASE"

echo "⬇️ Code cloned into release"

# 3. пересборка Docker контейнера
# 💡 Nuxt SSR теперь собирается из новой версии кода
cd "$RELEASES_DIR/$RELEASE"

docker compose -f docker-compose.prod.yml up -d --build --remove-orphans

echo "🐳 Docker rebuilt and restarted"

# 4. атомарно переключаем current
# 💡 ln -sfn = без промежуточного состояния
ln -sfn "$RELEASES_DIR/$RELEASE" "$CURRENT_LINK"

echo "🔗 Switched current -> $RELEASE"

# 5. очистка старых релизов (оставляем только 3)
echo "🧹 Cleaning old releases..."

cd "$RELEASES_DIR"

ls -1dt */ | tail -n +4 | while read dir; do
  echo "🗑 Removing: $dir"
  rm -rf "$dir"
done

echo "======================================"
echo "✅ DEPLOY FINISHED"
echo "======================================"