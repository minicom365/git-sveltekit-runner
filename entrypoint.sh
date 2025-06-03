#!/bin/bash
set -e

if [ -z "$GIT_REPO" ]; then
  echo "❌ GIT_REPO environment variable is not set."
  exit 1
fi

if [ ! -d "/app/repo/.git" ]; then
  echo "📦 Cloning Git repository for the first time: $GIT_REPO"
  git clone "$GIT_REPO" /app/repo
fi

/app/pull_and_reload.sh

python3 /webhook_server.py
