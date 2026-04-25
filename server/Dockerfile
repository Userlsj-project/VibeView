# C:\dev\vibeview\server\Dockerfile

FROM python:3.11-slim

# 시스템 패키지 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    curl \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Node.js 설치 (yt-dlp EJS 런타임용)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# pip 업그레이드 + setuptools 설치
RUN pip install --upgrade pip setuptools wheel

WORKDIR /app

# whisper 먼저 별도 설치 (빌드 의존성 문제 방지)
RUN pip install --no-cache-dir openai-whisper

# 나머지 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스 복사
COPY . .

# 정적 파일 폴더 생성
RUN mkdir -p /app/static/frames

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
