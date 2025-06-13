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

# 포트 기반 프로세스 종료 함수
kill_port_process() {
  local port=$1
  local pid=$(lsof -t -i:$port 2>/dev/null || true)
  if [ -n "$pid" ]; then
    echo_msg "🔫 포트 $port 사용 중인 프로세스($pid) 종료 중..." "🔫 Killing process($pid) using port $port..."
    kill -9 $pid || true
    sleep 2
  fi
}

# 더 정확한 프로세스 종료 함수
kill_sveltekit_processes() {
  echo_msg "🔁 SvelteKit 서버 종료 중..." "🔁 Stopping SvelteKit server..."
  
  # 포트 기반 종료 (가장 확실함)
  kill_port_process 3000
  
  # 패턴 기반 종료 (더 넓은 범위)
  pkill -f "node.*build" || true
  pkill -f "$PKG_MGR.*start" || true
  pkill -f "vite.*preview" || true
  pkill -f "svelte.*kit" || true
  
  # 잠깐 대기 후 강제 종료 확인
  sleep 3
  
  # 아직도 살아있으면 강제 종료
  local remaining_pid=$(lsof -t -i:3000 2>/dev/null || true)
  if [ -n "$remaining_pid" ]; then
    echo_msg "⚡ 강제 종료 실행..." "⚡ Force killing remaining processes..."
    kill -9 $remaining_pid || true
  fi
  
  echo_msg "✅ 서버 종료 완료!" "✅ Server shutdown complete!"
}

echo_msg "🔄 원격 저장소에서 최신 상태 가져오는 중..." "🔄 Fetching latest state from remote repository..."
git fetch --all
git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)

echo_msg "🔧 $PKG_MGR install..." "🔧 $PKG_MGR install..."
$PKG_MGR install

echo_msg "🔧 $PKG_MGR build..." "🔧 $PKG_MGR build..."
$PKG_MGR run build

# 개선된 서버 종료
kill_sveltekit_processes

# 새로운 서버 시작
echo_msg "🔁 SvelteKit 서버 재시작..." "🔁 Restarting SvelteKit server..."
$PKG_MGR start &

# 서버 시작 확인
sleep 5
if lsof -i:3000 >/dev/null 2>&1; then
  echo_msg "🎉 서버가 성공적으로 시작됐어!" "🎉 Server started successfully!"
else
  echo_msg "❌ 서버 시작에 실패했어..." "❌ Failed to start server..."
fi