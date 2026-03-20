from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from dotenv import load_dotenv
import os

load_dotenv()

from routers import analyze, coach, trend, user


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("✅ VibeView 서버 시작")
    yield
    print("🛑 VibeView 서버 종료")


app = FastAPI(
    title="VibeView API",
    description="영상 감정 AI 분석 플랫폼 API",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS 설정 (웹·모바일 앱에서 API 호출 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(analyze.router, prefix="/api",       tags=["분석"])
app.include_router(coach.router,   prefix="/api/coach", tags=["AI 코치"])
app.include_router(trend.router,   prefix="/api/trend", tags=["트렌드"])
app.include_router(user.router,    prefix="/api/user",  tags=["사용자"])


@app.get("/")
async def root():
    return {"message": "VibeView API 서버가 실행 중입니다 🎬"}


@app.get("/health")
async def health_check():
    return {"status": "ok"}
