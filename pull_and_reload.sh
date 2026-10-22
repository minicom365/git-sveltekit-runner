#!/bin/bash
# [EN] Fetch the target repo, rebuild it, restart the app. Token is supplied per-command via HTTP header only.
# [KO] 대상 저장소를 가져와 다시 빌드하고 앱을 재시작. 토큰은 명령마다 HTTP 헤더로만 전달(디스크 저장 없음).
set -e

cd /app/repo

PKG_MGR="${PKG_MGR:-npm}"
BRANCH="${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"

echo_msg() {
  if [ "${LANG_MSG}" = "en" ]; then echo "$2"; else echo "$1"; fi
}

auth_header() {
  if [ -n "${GIT_TOKEN:-}" ]; then
    printf 'AUTHORIZATION: basic %s' "$(printf '%s:%s' "${GIT_USER:-minicoms}" "$GIT_TOKEN" | base64 -w0)"
  fi
}

kill_port_process() {
  local port=$1
  if command -v fuser >/dev/null 2>&1; then
    fuser -k "${port}/tcp" 2>/dev/null || true
  else
    local pid
    pid=$(ss -ltnp 2>/dev/null | awk -v p=":${port}" '$4 ~ p {print $6}' | sed -E 's/.*pid=([0-9]+).*/\1/' | head -1)
    [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null || true
  fi
}

echo_msg "🔄 원격 저장소에서 최신 상태 가져오는 중..." "🔄 Fetching latest state from remote..."
if [ -n "${GIT_TOKEN:-}" ]; then
  git -c "http.extraHeader=$(auth_header)" fetch origin "$BRANCH" || echo_msg "⚠️ fetch 실패 — 기존 체크아웃으로 계속" "⚠️ fetch failed; continuing with existing checkout"
else
  git fetch origin "$BRANCH" || echo_msg "⚠️ fetch 실패 — 기존 체크아웃으로 계속" "⚠️ fetch failed; continuing with existing checkout"
fi
git reset --hard "origin/${BRANCH}" 2>/dev/null || echo_msg "⚠️ reset 건너뜀(로컬 체크아웃 유지)" "⚠️ reset skipped (keep local checkout)"

echo_msg "🔧 $PKG_MGR install..." "🔧 $PKG_MGR install..."
$PKG_MGR install --no-audit --no-fund

echo_msg "🔧 $PKG_MGR build..." "🔧 $PKG_MGR build..."
$PKG_MGR run build

echo_msg "🔁 서버 종료 중..." "🔁 Stopping server..."
kill_port_process 3000
pkill -f "node.*build" 2>/dev/null || true
pkill -f "$PKG_MGR.*start" 2>/dev/null || true
pkill -f "vite.*preview" 2>/dev/null || true
sleep 2
kill_port_process 3000

echo_msg "🔁 서버 재시작..." "🔁 Restarting server..."
nohup $PKG_MGR start >/tmp/app.log 2>&1 &
sleep 3

if curl -fs http://127.0.0.1:3000 >/dev/null 2>&1 || ss -tln 2>/dev/null | grep -q ':3000'; then
  echo_msg "🎉 서버 시작 확인" "🎉 Server is up"
else
  echo_msg "⚠️ 서버 상태 확인 불가 — /tmp/app.log 확인" "⚠️ Cannot verify server; check /tmp/app.log"
fi
