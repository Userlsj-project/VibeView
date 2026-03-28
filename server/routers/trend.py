# C:\dev\vibeview\server\routers\trend.py

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from collections import Counter
from database import get_db
from models import AnalysisResult

router = APIRouter()


@router.get("")
async def get_trend(
    limit: int = Query(default=20, ge=1, le=100, description="조회할 최근 영상 수 (1~100)"),
    db: Session = Depends(get_db),
):
    """
    최근 분석된 영상들의 감정 트렌드를 반환합니다.

    - limit: 최근 몇 개 영상 기준으로 집계할지 (기본 20개)
    """

    # 최근 N개 분석 결과 조회 (최신순)
    records = (
        db.query(AnalysisResult)
        .order_by(AnalysisResult.created_at.desc())
        .limit(limit)
        .all()
    )

    if not records:
        return {
            "status": "no_data",
            "message": "아직 분석된 영상이 없습니다.",
            "total_analyzed": 0,
        }

    total = len(records)

    # ── 1. 등급 분포 ─────────────────────────────────────────────
    grade_counts = Counter(r.grade for r in records if r.grade)
    grade_distribution = {
        grade: round(count / total, 3)
        for grade, count in sorted(grade_counts.items())
    }

    # ── 2. 평균 바이럴 점수 ───────────────────────────────────────
    viral_scores = [r.viral_score for r in records if r.viral_score is not None]
    avg_viral_score = round(sum(viral_scores) / len(viral_scores), 4) if viral_scores else 0.0

    # ── 3. 평균 fused_valence ─────────────────────────────────────
    valences = [r.fused_valence for r in records if r.fused_valence is not None]
    avg_valence = round(sum(valences) / len(valences), 4) if valences else 0.0

    # ── 4. 감정 분포 ──────────────────────────────────────────────
    emotion_counts = Counter(r.fused_emotion for r in records if r.fused_emotion)
    emotion_distribution = {
        emotion: round(count / total, 3)
        for emotion, count in emotion_counts.most_common()
    }

    # ── 5. 분위기(vibe) 트렌드 ────────────────────────────────────
    vibe_counts = Counter(r.dominant_vibe for r in records if r.dominant_vibe)
    vibe_trend = {
        vibe: round(count / total, 3)
        for vibe, count in vibe_counts.most_common(5)  # 상위 5개
    }

    # ── 6. 콘텐츠 유형 분포 ───────────────────────────────────────
    content_counts = Counter(r.content_type for r in records if r.content_type)
    content_distribution = {
        ctype: round(count / total, 3)
        for ctype, count in content_counts.most_common()
    }

    # ── 7. 최고 바이럴 영상 TOP 3 ────────────────────────────────
    top_videos = (
        db.query(AnalysisResult)
        .filter(AnalysisResult.viral_score.isnot(None))
        .order_by(AnalysisResult.viral_score.desc())
        .limit(3)
        .all()
    )
    top_viral = [
        {
            "title":         r.title or r.video_url,
            "channel":       r.channel,
            "thumbnail_url": r.thumbnail_url,
            "viral_score":   r.viral_score,
            "grade":         r.grade,
            "view_count":    r.view_count,
            "fused_emotion": r.fused_emotion,
            "analyzed_at":   r.created_at.isoformat() if r.created_at else None,
        }
        for r in top_videos
    ]

    # ── 8. 최근 분석 영상 목록 ────────────────────────────────────
    recent_videos = [
        {
            "title":         r.title or r.video_url,
            "channel":       r.channel,
            "thumbnail_url": r.thumbnail_url,
            "viral_score":   r.viral_score,
            "grade":         r.grade,
            "fused_emotion": r.fused_emotion,
            "dominant_vibe": r.dominant_vibe,
            "analyzed_at":   r.created_at.isoformat() if r.created_at else None,
        }
        for r in records
    ]

    return {
        "status": "success",
        "total_analyzed": total,
        "avg_viral_score": avg_viral_score,
        "avg_valence": avg_valence,
        "grade_distribution": grade_distribution,
        "emotion_distribution": emotion_distribution,
        "vibe_trend": vibe_trend,
        "content_distribution": content_distribution,
        "top_viral": top_viral,
        "recent_videos": recent_videos,
    }
