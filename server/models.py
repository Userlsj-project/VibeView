# C:\dev\vibeview\server\models.py

from sqlalchemy import Column, Integer, Float, String, JSON, DateTime, Text
from sqlalchemy.sql import func
from database import Base


class AnalysisResult(Base):
    """
    영상 분석 결과 저장 테이블.
    /api/analyze 호출 시 결과를 저장합니다.
    """
    __tablename__ = "analysis_results"

    id             = Column(Integer, primary_key=True, index=True)
    video_url      = Column(String, nullable=False)
    video_id       = Column(String, nullable=True)        # YouTube 영상 ID
    title          = Column(String, nullable=True)        # 영상 제목
    channel        = Column(String, nullable=True)        # 채널명
    thumbnail_url  = Column(String, nullable=True)        # 썸네일 URL
    duration       = Column(Float, nullable=True)         # 영상 길이 (초)

    # YouTube 통계
    view_count     = Column(Integer, nullable=True)
    like_count     = Column(Integer, nullable=True)
    comment_count  = Column(Integer, nullable=True)
    views_per_day  = Column(Float, nullable=True)

    # 분석 결과 요약
    fused_emotion  = Column(String, nullable=True)        # 종합 감정
    fused_valence  = Column(Float, nullable=True)         # 종합 감정 극성
    viral_score    = Column(Float, nullable=True)         # 바이럴 점수
    grade          = Column(String, nullable=True)        # 등급 (S/A/B/C/D)
    dominant_vibe  = Column(String, nullable=True)        # 대표 분위기
    content_type   = Column(String, nullable=True)        # 콘텐츠 유형

    # 전체 분석 결과 (JSON)
    face_summary     = Column(JSON, nullable=True)
    audio_summary    = Column(JSON, nullable=True)
    scene_summary    = Column(JSON, nullable=True)
    fusion_result    = Column(JSON, nullable=True)
    viral_result     = Column(JSON, nullable=True)
    youtube_stats    = Column(JSON, nullable=True)
    emotion_timeline = Column(JSON, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
