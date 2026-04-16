#!/bin/bash

# =========================================
# 🚀 NU XT SSR DEPLOY SYSTEM (BOOTSTRAP)
# =========================================
# 💡 Эта система:
# - создаёт новый релиз (каталог)
# - клонирует код
# - передаёт управление релизному deploy.sh
# =========================================

set -e

APP_DIR="/var/www/github-ci-cd"
RELEASES_DIR="$APP_DIR/releases"
SHARED_DIR="$APP_DIR/shared"

REPO_URL="$1"

# 🕒 уникальный ID релиза (гарантирует отсутствие конфликтов)
RELEASE=$(date +%Y%m%d_%H%M%S)

echo "======================================"
echo "🚀 BOOTSTRAP DEPLOY START: $RELEASE"
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

# 3. копируем .env в релиз
echo "📄 Copying .env to release..."

cp "$SHARED_DIR/.env" "$RELEASES_DIR/$RELEASE/.env"

echo "✅ .env copied"

# 4. выдаём права на выполнение релизному deploy.sh
echo "🔐 Setting execute permission on release deploy.sh..."

chmod +x "$RELEASES_DIR/$RELEASE/deploy.sh"

echo "✅ Execute permission set"

# 5. передаём управление релизному deploy.sh
# 💡 весь деплой (сборка, переключение, очистка) теперь в коде проекта
echo "🚀 Handing over to release deploy.sh..."

exec "$RELEASES_DIR/$RELEASE/deploy.sh" "$RELEASE"
