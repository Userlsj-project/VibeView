# C:\dev\vibeview\web\Dockerfile

# 1단계: 빌드
FROM node:20-slim AS builder

WORKDIR /app

# 의존성 먼저 복사 (레이어 캐시 활용)
COPY package.json package-lock.json* ./
RUN npm install --legacy-peer-deps

# 소스 복사 및 빌드
COPY . .

# 백엔드 API 주소를 환경변수로 주입
ARG REACT_APP_API_BASE=http://localhost:8000
ENV REACT_APP_API_BASE=$REACT_APP_API_BASE

RUN npm run build

# 2단계: Nginx로 정적 파일 서빙
FROM nginx:alpine

# 빌드 결과물 복사
COPY --from=builder /app/build /usr/share/nginx/html

# Nginx 설정
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
