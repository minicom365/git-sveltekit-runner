#!/bin/bash
set -e

cd /app/repo

PKG_MGR=${PKG_MGR:-npm}

# 다국어 메시지 함수
echo_msg() {
  local ko_msg="$1"
  local en_msg="$2"
  if [ "$LANG_MSG" = "en" ]; then
    echo "$en_msg"
  else
    echo "$ko_msg"
  fi
}

echo_msg "🔄 원격 저장소에서 최신 상태 가져오는 중..." "🔄 Fetching latest state from remote repository..."
git fetch --all
git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)

echo_msg "🔧 $PKG_MGR install..." "🔧 $PKG_MGR install..."
$PKG_MGR install

echo_msg "🔧 $PKG_MGR build..." "🔧 $PKG_MGR build..."
$PKG_MGR run build

# 기존 프로세스 종료
echo_msg "🔁 SvelteKit 서버 종료 중..." "🔁 Stopping SvelteKit server..."
pgrep -f "$PKG_MGR start" | xargs -r kill -9 || true
pgrep -f "node build" | xargs -r kill -9 || true

# 새로운 서버 시작
echo_msg "🔁 SvelteKit 서버 재시작..." "🔁 Restarting SvelteKit server..."
$PKG_MGR start &
