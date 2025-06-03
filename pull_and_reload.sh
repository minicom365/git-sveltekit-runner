#!/bin/bash
set -e

cd /app/repo

PKG_MGR=${PKG_MGR:-npm}

echo "🔄 git pull..."
git pull

echo "🔧 $PKG_MGR install..."
$PKG_MGR install

echo "🔧 $PKG_MGR build..."
$PKG_MGR run build

echo "🔁 restart SvelteKit server..."
pkill -f "$PKG_MGR start" || pkill -f "node build" || true
$PKG_MGR start &
