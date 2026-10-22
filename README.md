# git-sveltekit-runner

SvelteKit 배포용 초경량 러너입니다. Git 저장소를 주기적으로 pull → `npm run build` → 서버 재시작하고,
Gitea webhook을 받으면 즉시 같은 작업을 수행합니다.

## 이전 버전에서 바뀐 점

- Flask/Python/nginx 제거 → **Node.js 표준 라이브러리만** 사용 (이미지 축소)
- **비루트(uid 1000)** 실행
- webhook **HMAC-SHA256 서명 검증** 지원 (`WEBHOOK_SECRET`)
- 토큰을 `.git/config`에 남기지 않음 (HTTP 헤더로만 전달)
- `/health` 헬스체크, `restart: unless-stopped`

## 환경변수

| 변수 | 필수 | 설명 |
|---|---|---|
| `GIT_REPO` | 예 | 대상 저장소 URL (토큰 포함하지 말 것) |
| `GIT_TOKEN` | 권장 | Gitea 액세스 토큰 (비공개 저장소인 경우) |
| `GIT_USER` | 아니오 | 토큰 사용자명 (기본 `minicoms`) |
| `GIT_BRANCH` | 아니오 | 배포 브랜치 (기본: 현재 브랜치, 최초 clone은 `main`) |
| `WEBHOOK_SECRET` | 권장 | Gitea webhook secret. 설정 시 서명 불일치 요청은 401 |
| `PKG_MGR` | 아니오 | 패키지 매니저 (기본 `npm`) |
| `PORT` | 아니오 | webhook 포트 (기본 `4000`) |

## 실행

```bash
docker build -t minicom365/git-sveltekit-runner:latest .
docker run -d --name git-sveltekit-runner -p 4000:4000 \
  -e GIT_REPO=https://gitea.example.com/owner/repo.git \
  -e GIT_TOKEN=*** -e WEBHOOK_SECRET=*** \
  minicom365/git-sveltekit-runner:latest
```

## Gitea webhook 설정

1. Gitea 저장소 → 설정 → 웹훅 → 웹훅 추가
2. 대상 URL: `http://<runner-host>:4000/webhook`
3. 시크릿: `WEBHOOK_SECRET`과 동일한 값
4. 이벤트: push

## 엔드포인트

- `GET /health` → `ok`
- `POST /webhook` → 서명 검증 후 `pull_and_reload.sh` 실행, `200 pulled and reloaded`

## English

Minimal SvelteKit deploy runner: pulls a git repo, runs `npm run build`, restarts the app, and triggers the same flow
from a Gitea webhook. Node stdlib only (no Flask/nginx), runs as non-root, verifies `X-Gitea-Signature` when
`WEBHOOK_SECRET` is set, and never writes the access token to disk.
