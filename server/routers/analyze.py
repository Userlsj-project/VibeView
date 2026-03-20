# C:\dev\vibeview\server\routers\analyze.py

from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from pathlib import Path
from services.video_processor import VideoProcessor
from services.face_analyzer import FaceAnalyzer
from services.audio_analyzer import AudioAnalyzer

router = APIRouter()

# 분석기 인스턴스 (서버 시작 시 1회만 로드)
_face_analyzer = None
_audio_analyzer = None

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


class AnalyzeRequest(BaseModel):
    url: str
    fps: int = 2


class AnalyzeResponse(BaseModel):
    status: str
    video_info: dict
    face_summary: dict
    audio_summary: dict
    emotion_timeline: list


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_video(req: AnalyzeRequest, background_tasks: BackgroundTasks):
    """
    영상 URL → 다운로드 → 얼굴 감정 + 음성 감정 분석 → 타임라인 반환
    """
    processor = VideoProcessor(fps=req.fps)

    try:
        # 1. 영상 다운로드 + 프레임/오디오 추출
        result = processor.process(req.url)

        # 2. 얼굴 감정 분석
        face_results = get_face_analyzer().analyze_frames(result["frames"])
        face_summary = get_face_analyzer().summarize_timeline(face_results)

        # 3. 음성 감정 분석
        audio_result = get_audio_analyzer().analyze(result["audio_path"])

        # 4. 타임라인 병합 (초 단위)
        emotion_timeline = _merge_timeline(
            face_results,
            audio_result["feature_timeline"],
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
        face_summary={
            "emotion_distribution": face_summary["emotion_distribution"],
            "avg_valence": face_summary["avg_valence"],
            "peak_emotion": face_summary["peak_emotion"],
        },
        audio_summary=audio_result["summary"],
        emotion_timeline=emotion_timeline,
    )


def _merge_timeline(face_results: list[dict], audio_timeline: list[dict]) -> list[dict]:
    """
    얼굴(프레임 단위)과 음성(초 단위) 타임라인을 병합합니다.
    같은 초(timestamp) 기준으로 합쳐서 반환합니다.
    """
    # 음성을 timestamp 기준 dict로 변환
    audio_map = {a["timestamp"]: a for a in audio_timeline}

    merged = []
    for face in face_results:
        ts = face["timestamp"]
        # 가장 가까운 음성 타임스탬프 찾기
        closest_audio_ts = min(audio_map.keys(), key=lambda x: abs(x - ts), default=None)
        audio = audio_map.get(closest_audio_ts, {})

        merged.append({
            "timestamp": ts,
            "face_emotion": face["dominant_emotion"],
            "face_valence": face["dominant_valence"],
            "face_count": face["face_count"],
            "audio_emotion": audio.get("emotion", "unknown"),
            "audio_valence": audio.get("valence", 0.0),
            "audio_energy": audio.get("energy", 0.0),
        })

    return merged