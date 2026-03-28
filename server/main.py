# C:\dev\vibeview\server\main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from dotenv import load_dotenv
from pathlib import Path
import os

load_dotenv()

from routers import analyze, coach, trend, user
from database import engine, Base
import models  # 테이블 정의 로드 (import 만으로 Base에 등록됨)

# 프레임 정적 파일 폴더 자동 생성
_FRAMES_ROOT = Path(__file__).parent / "static" / "frames"
_FRAMES_ROOT.mkdir(parents=True, exist_ok=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 서버 시작 시 테이블 자동 생성
    Base.metadata.create_all(bind=engine)
    print("✅ VibeView 서버 시작 - DB 테이블 확인 완료")
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

# 프레임 이미지 정적 파일 서빙
# http://localhost:8000/frames/{video_id}/{filename}.jpg 로 접근 가능
app.mount("/frames", StaticFiles(directory=str(_FRAMES_ROOT)), name="frames")

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
