#!/bin/bash
# [EN] Entrypoint: clone the target repository once, run one pull/build, then serve the webhook forever.
#      Supports both HTTPS (token via HTTP header, never written to disk) and SSH (deploy key) remotes.
# [KO] 진입점: 대상 저장소를 최초 1회 clone, pull/build 1회 수행 후 webhook 서버를 계속 실행.
#      HTTPS(토큰은 HTTP 헤더로만, 디스크 미저장)와 SSH(배포 키) 원격을 모두 지원.
set -e

: "${GIT_REPO:?GIT_REPO is required}"
REPO_DIR=/app/repo
BRANCH="${GIT_BRANCH:-main}"

setup_ssh() {
  case "$GIT_REPO" in
    ssh://*|git@*)
      export GIT_SSH_COMMAND="ssh -i ${GIT_SSH_KEY:-/app/.ssh/id_ed25519} -o IdentitiesOnly=yes -o UserKnownHostsFile=${GIT_SSH_KNOWN_HOSTS:-/app/.ssh/known_hosts} -o StrictHostKeyChecking=yes"
      ;;
  esac
}

auth_header() {
  if [ -n "${GIT_TOKEN:-}" ]; then
    printf 'AUTHORIZATION: basic %s' "$(printf '%s:%s' "${GIT_USER:-minicoms}" "$GIT_TOKEN" | base64 -w0)"
  fi
}

setup_ssh

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
