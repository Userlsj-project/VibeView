# C:\dev\vibeview\server\routers\analyze.py

from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from services.video_processor import VideoProcessor
from services.face_analyzer import FaceAnalyzer
from services.audio_analyzer import AudioAnalyzer
from services.scene_analyzer import SceneAnalyzer
from services.fusion_engine import FusionEngine
from services.viral_predictor import ViralPredictor
from services.youtube_service import YouTubeService
from database import get_db
from models import AnalysisResult

router = APIRouter()

# 분석기 인스턴스 (서버 시작 시 1회만 로드)
_face_analyzer   = None
_audio_analyzer  = None
_scene_analyzer  = None
_fusion_engine   = FusionEngine()
_viral_predictor = ViralPredictor()
_youtube_service = YouTubeService()


def get_face_analyzer() -> FaceAnalyzer:
    global _face_analyzer
    if _face_analyzer is None:
        _face_analyzer = FaceAnalyzer()
    return _face_analyzer


def get_audio_analyzer() -> AudioAnalyzer:
    global _audio_analyzer
    if _audio_analyzer is None:
        _audio_analyzer = AudioAnalyzer(whisper_model="base")
    return _audio_analyzer


def get_scene_analyzer() -> SceneAnalyzer:
    global _scene_analyzer
    if _scene_analyzer is None:
        _scene_analyzer = SceneAnalyzer()
    return _scene_analyzer


class AnalyzeRequest(BaseModel):
    url: str
    fps: int = 2


class AnalyzeResponse(BaseModel):
    status: str
    video_info: dict
    youtube_stats: dict
    face_summary: dict
    audio_summary: dict
    scene_summary: dict
    fusion_result: dict
    viral_result: dict
    emotion_timeline: list


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_video(
    req: AnalyzeRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """
    영상 URL → 다운로드 → 얼굴/음성/장면 분석 → 멀티모달 융합 → 바이럴 예측 → DB 저장 → 반환
    """
    processor = VideoProcessor(fps=req.fps)

    try:
        # 1. YouTube 통계 조회
        youtube_stats = _fetch_youtube_stats(req.url)

        # 2. 영상 다운로드 + 프레임/오디오 추출
        result = processor.process(req.url)

        # 3. 얼굴 감정 분석
        face_analyzer = get_face_analyzer()
        face_results  = face_analyzer.analyze_frames(result["frames"])
        face_summary  = face_analyzer.summarize_timeline(face_results)

        # 4. 음성 감정 분석
        audio_result  = get_audio_analyzer().analyze(result["audio_path"])
        audio_summary = audio_result["summary"]

        # 5. 장면 분석 (YOLOv8 + CLIP)
        scene_result  = get_scene_analyzer().analyze_frames(result["frames"])
        scene_summary = scene_result["scene_summary"]

        # 6. 타임라인 병합 (frame_url 포함)
        emotion_timeline = _merge_timeline(
            face_results,
            audio_result["feature_timeline"],
            result["frames"],
        )

        # face_summary 직렬화
        face_summary_dict = {
            "emotion_distribution": face_summary["emotion_distribution"],
            "avg_valence":          face_summary["avg_valence"],
            "peak_emotion":         face_summary["peak_emotion"],
        }

        # 7. 멀티모달 융합
        fusion_result = _fusion_engine.fuse(
            face_summary=face_summary_dict,
            audio_summary=audio_summary,
            scene_summary=scene_summary,
            emotion_timeline=emotion_timeline,
        )

        # 8. 바이럴 점수 예측
        viral_result = _viral_predictor.predict(
            fusion_result=fusion_result,
            face_summary=face_summary_dict,
            audio_summary=audio_summary,
            scene_summary=scene_summary,
            video_info=result["info"],
        )

        # 9. DB 저장
        _save_to_db(
            db=db,
            url=req.url,
            video_info=result["info"],
            youtube_stats=youtube_stats,
            face_summary=face_summary_dict,
            audio_summary=audio_summary,
            scene_summary=scene_summary,
            fusion_result=fusion_result,
            viral_result=viral_result,
            emotion_timeline=emotion_timeline,
        )

    except RuntimeError as e:
        processor.cleanup()
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        processor.cleanup()
        raise HTTPException(status_code=500, detail=f"분석 중 오류: {str(e)}")

    background_tasks.add_task(processor.cleanup)

    return AnalyzeResponse(
        status="success",
        video_info=result["info"],
        youtube_stats=youtube_stats,
        face_summary=face_summary_dict,
        audio_summary=audio_summary,
        scene_summary=scene_summary,
        fusion_result=fusion_result,
        viral_result=viral_result,
        emotion_timeline=emotion_timeline,
    )


def _save_to_db(
    db: Session,
    url: str,
    video_info: dict,
    youtube_stats: dict,
    face_summary: dict,
    audio_summary: dict,
    scene_summary: dict,
    fusion_result: dict,
    viral_result: dict,
    emotion_timeline: list,
) -> None:
    """분석 결과를 DB에 저장합니다. 실패해도 API 응답에는 영향 없음."""
    try:
        record = AnalysisResult(
            video_url      = url,
            video_id       = youtube_stats.get("video_id"),
            title          = youtube_stats.get("title"),
            channel        = youtube_stats.get("channel"),
            thumbnail_url  = youtube_stats.get("thumbnail_url"),
            duration       = video_info.get("duration"),
            view_count     = youtube_stats.get("view_count"),
            like_count     = youtube_stats.get("like_count"),
            comment_count  = youtube_stats.get("comment_count"),
            views_per_day  = youtube_stats.get("views_per_day"),
            fused_emotion  = fusion_result.get("fused_emotion"),
            fused_valence  = fusion_result.get("fused_valence"),
            viral_score    = viral_result.get("viral_score"),
            grade          = viral_result.get("grade"),
            dominant_vibe  = scene_summary.get("dominant_vibe"),
            content_type   = scene_summary.get("content_type"),
            face_summary     = face_summary,
            audio_summary    = audio_summary,
            scene_summary    = scene_summary,
            fusion_result    = fusion_result,
            viral_result     = viral_result,
            youtube_stats    = youtube_stats,
            emotion_timeline = emotion_timeline,
        )
        db.add(record)
        db.commit()
    except Exception as e:
        db.rollback()
        import logging
        logging.getLogger(__name__).warning(f"DB 저장 실패 (분석 결과는 정상 반환됨): {e}")


def _fetch_youtube_stats(url: str) -> dict:
    """YouTube URL일 때만 통계를 가져옵니다."""
    if "youtube.com" not in url and "youtu.be" not in url:
        return {}
    try:
        return _youtube_service.get_stats(url)
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"YouTube 통계 조회 실패 (분석은 계속): {e}")
        return {"error": str(e)}


def _merge_timeline(
    face_results: list[dict],
    audio_timeline: list[dict],
    frames: list[dict],
) -> list[dict]:
    """얼굴(프레임 단위)과 음성(초 단위) 타임라인을 병합합니다. frame_url 포함."""

    # 타임스탬프 → frame_url 맵
    frame_url_map = {f["timestamp"]: f.get("frame_url", "") for f in frames}

    if not audio_timeline:
        return [
            {
                "timestamp":     r["timestamp"],
                "face_emotion":  r["dominant_emotion"],
                "face_valence":  r["dominant_valence"],
                "face_count":    r["face_count"],
                "audio_emotion": "unknown",
                "audio_valence": 0.0,
                "audio_energy":  0.0,
                "frame_url":     frame_url_map.get(r["timestamp"], ""),
            }
            for r in face_results
        ]

    audio_map = {a["timestamp"]: a for a in audio_timeline}

    merged = []
    for face in face_results:
        ts = face["timestamp"]
        closest_ts = min(audio_map.keys(), key=lambda x: abs(x - ts))
        audio = audio_map[closest_ts]

        merged.append({
            "timestamp":     ts,
            "face_emotion":  face["dominant_emotion"],
            "face_valence":  face["dominant_valence"],
            "face_count":    face["face_count"],
            "audio_emotion": audio.get("emotion", "unknown"),
            "audio_valence": audio.get("valence", 0.0),
            "audio_energy":  audio.get("energy", 0.0),
            "frame_url":     frame_url_map.get(ts, ""),
        })

    return merged
