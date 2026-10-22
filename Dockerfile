# [EN] Slim Node.js-based runner image: no Python, no nginx. Runs as non-root (uid 1000), health-checked webhook.
# [KO] Python·nginx 없는 슬림 Node.js 러너 이미지. 비루트(uid 1000) 실행, webhook 헬스체크 포함.
FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates curl bash psmisc \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash runner 2>/dev/null || true

WORKDIR /app
COPY server.js entrypoint.sh pull_and_reload.sh ./
RUN chmod +x entrypoint.sh pull_and_reload.sh \
    && mkdir -p /app/repo \
    && chown -R node:node /app

USER node

ENV GIT_REPO="" \
    GIT_USER="minicoms" \
    GIT_BRANCH="" \
    PKG_MGR="npm" \
    PORT="4000"

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
    CMD curl -fs http://127.0.0.1:4000/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
