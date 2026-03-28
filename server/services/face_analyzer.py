# C:\dev\vibeview\server\services\face_analyzer.py

import cv2
import os
from pathlib import Path
from collections import Counter

# TensorFlow 로그 억제
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

from fer import FER


# 감정 극성 매핑 (-1 ~ +1)
_VALENCE_MAP = {
    "happy":    0.8,
    "surprise": 0.1,
    "neutral":  0.0,
    "sad":     -0.6,
    "fear":    -0.7,
    "angry":   -0.7,
    "disgust": -0.5,
}

# FER 감정명 → 내부 통일 키 (기존 코드와 호환)
_EMOTION_NORMALIZE = {
    "happy":    "happy",
    "surprise": "surprised",
    "neutral":  "neutral",
    "sad":      "sad",
    "fear":     "fearful",
    "angry":    "angry",
    "disgust":  "disgusted",
}


class FaceAnalyzer:
    """
    FER(Facial Expression Recognition) 기반 얼굴 감정 분석기
    - 딥러닝 CNN 모델로 감정 분류 (MediaPipe 랜드마크 방식 대비 정확도 향상)
    - 분장/메이크업 영상에서도 더 나은 결과
    - 인터페이스는 기존 버전과 동일 (다른 파일 수정 불필요)
    """

    def __init__(self, max_faces: int = 4, min_detection_confidence: float = 0.5):
        self.max_faces = max_faces
        # mtcnn=True: MTCNN 얼굴 감지 (더 정확, 분장 영상에 강함)
        self._detector = FER(mtcnn=True)

    # ------------------------------------------------------------------
    # 단일 프레임 분석
    # ------------------------------------------------------------------
    def analyze_frame(self, frame_path: Path) -> dict:
        img = cv2.imread(str(frame_path))
        if img is None:
            return self._empty_result()

        # BGR → RGB 변환 (FER은 RGB 입력)
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        try:
            results = self._detector.detect_emotions(img_rgb)
        except Exception:
            return self._empty_result()

        if not results:
            return self._empty_result()

        faces = []
        for face_id, res in enumerate(results[:self.max_faces]):
            raw_scores = res.get('emotions', {})
            if not raw_scores:
                continue

            raw_emotion = max(raw_scores, key=raw_scores.get)
            emotion = _EMOTION_NORMALIZE.get(raw_emotion, raw_emotion)
            valence = _VALENCE_MAP.get(raw_emotion, 0.0)

            total = sum(raw_scores.values()) or 1.0
            scores = {
                _EMOTION_NORMALIZE.get(k, k): round(v / total, 3)
                for k, v in raw_scores.items()
            }

            faces.append({
                "face_id": face_id,
                "emotion": emotion,
                "scores":  scores,
                "valence": valence,
            })

        if not faces:
            return self._empty_result()

        dominant = max(faces, key=lambda f: abs(f["valence"]))

        return {
            "faces":            faces,
            "face_count":       len(faces),
            "dominant_emotion": dominant["emotion"],
            "dominant_valence": dominant["valence"],
        }

    # ------------------------------------------------------------------
    # 프레임 리스트 배치 처리
    # ------------------------------------------------------------------
    def analyze_frames(self, frames: list[dict]) -> list[dict]:
        results = []
        for frame in frames:
            result = self.analyze_frame(frame["frame_path"])
            result["timestamp"] = frame["timestamp"]
            results.append(result)
        return results

    # ------------------------------------------------------------------
    # 타임라인 요약
    # ------------------------------------------------------------------
    def summarize_timeline(self, frame_results: list[dict]) -> dict:
        timeline = [
            {
                "timestamp": r["timestamp"],
                "emotion":   r["dominant_emotion"],
                "valence":   r["dominant_valence"],
            }
            for r in frame_results
        ]

        if not timeline:
            return {
                "timeline":             [],
                "emotion_distribution": {},
                "avg_valence":          0.0,
                "peak_emotion":         None,
            }

        counts = Counter(t["emotion"] for t in timeline)
        total  = len(timeline)
        distribution = {k: round(v / total, 3) for k, v in counts.items()}
        avg_valence  = round(sum(t["valence"] for t in timeline) / total, 3)
        peak         = max(timeline, key=lambda t: abs(t["valence"]))

        return {
            "timeline":             timeline,
            "emotion_distribution": distribution,
            "avg_valence":          avg_valence,
            "peak_emotion":         peak,
        }

    # ------------------------------------------------------------------
    def _empty_result(self) -> dict:
        return {
            "faces":            [],
            "face_count":       0,
            "dominant_emotion": "neutral",
            "dominant_valence": 0.0,
        }
