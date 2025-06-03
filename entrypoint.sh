#!/bin/bash
set -e

if [ -z "$GIT_REPO" ]; then
  echo "❌ GIT_REPO 환경변수가 설정되지 않았습니다."
  exit 1
fi

if [ ! -d "/app/repo/.git" ]; then
  echo "📦 Git 저장소 최초 클론: $GIT_REPO"
  git clone "$GIT_REPO" /app/repo
fi

/app/pull_and_reload.sh

python3 /webhook_server.py
