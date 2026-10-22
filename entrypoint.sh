#!/bin/bash
# [EN] Container entrypoint: clone the target repository once (token passed via HTTP header, never baked into .git/config),
#      run one pull/build, then serve the webhook forever.
# [KO] 컨테이너 진입점: 대상 저장소를 최초 1회 clone(토큰은 HTTP 헤더로만 전달, .git/config에 남기지 않음),
#      pull/build 1회 수행 후 webhook 서버를 계속 실행.
set -e

: "${GIT_REPO:?GIT_REPO is required}"
REPO_DIR=/app/repo
BRANCH="${GIT_BRANCH:-main}"

auth_header() {
  if [ -n "${GIT_TOKEN:-}" ]; then
    printf 'AUTHORIZATION: basic %s' "$(printf '%s:%s' "${GIT_USER:-minicoms}" "$GIT_TOKEN" | base64 -w0)"
  fi
}

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[entrypoint] cloning $GIT_REPO ($BRANCH)"
  if [ -n "${GIT_TOKEN:-}" ]; then
    git -c "http.extraHeader=$(auth_header)" clone --branch "$BRANCH" "$GIT_REPO" "$REPO_DIR"
  else
    git clone --branch "$BRANCH" "$GIT_REPO" "$REPO_DIR"
  fi
fi

/app/pull_and_reload.sh || echo "[entrypoint] initial pull/build failed; webhook stays up"

exec node /app/server.js
