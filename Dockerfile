FROM node:latest

# 시스템 패키지 설치 (Flask 용 Python 포함)
RUN apt update && apt install -y \
    python3 \
    python3-pip \
    python3.11-venv \
    git \
    curl \
    nginx \
    dos2unix \
    && apt clean
RUN python3 -m venv /venv
# 환경변수 설정
ENV PATH="/venv/bin:$PATH"
# Flask 설치
RUN pip install flask

WORKDIR /app

COPY entrypoint.sh ./entrypoint.sh
COPY webhook_server.py ./webhook_server.py
COPY pull_and_reload.sh ./pull_and_reload.sh
RUN chmod +x ./entrypoint.sh ./pull_and_reload.sh
RUN dos2unix ./entrypoint.sh ./pull_and_reload.sh


ENV GIT_REPO=""
ENV PKG_MGR=""
ENTRYPOINT ["/app/entrypoint.sh"]
