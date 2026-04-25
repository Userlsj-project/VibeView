# C:\dev\vibeview\server\services\face_analyzer.py

import cv2
import os
import base64
from pathlib import Path
from collections import Counter

# TensorFlow 로그 억제
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

from fer import FER
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# 감정 극성 매핑 (-1 ~ +1)
_VALENCE_MAP = {
    "happy":     0.8,
    "surprise":  0.1,
    "neutral":   0.0,
    "sad":      -0.6,
    "fear":     -0.7,
    "angry":    -0.7,
    "disgust":  -0.5,
}

# FER 감정명 → 내부 통일 키
_EMOTION_NORMALIZE = {
    "happy":    "happy",
    "surprise": "surprised",
    "neutral":  "neutral",
    "sad":      "sad",
    "fear":     "fearful",
    "angry":    "angry",
    "disgust":  "disgusted",
}

# Gemini → 내부 통일 키
_GEMINI_EMOTION_MAP = {
    "happy":     "happy",
    "surprised": "surprised",
    "neutral":   "neutral",
    "sad":       "sad",
    "fearful":   "fearful",
    "angry":     "angry",
    "disgusted": "disgusted",
    "excited":   "happy",
    "joy":       "happy",
    "fear":      "fearful",
    "disgust":   "disgusted",
    "anger":     "angry",
    "sorrow":    "sad",
    "surprise":  "surprised",
}


class FaceAnalyzer:
    """
    FER(Facial Expression Recognition) + Gemini Vision 보정 기반 얼굴 감정 분석기
    - FER CNN: 기본 감정 감지 (프레임별 전체 처리)
    - Gemini Vision: 피크 감정 프레임에 대해 보정/검증 (정확도 향상)
    """

    def __init__(self, max_faces: int = 4, min_detection_confidence: float = 0.5):
        self.max_faces = max_faces
        self._detector = FER(mtcnn=True)
        self._gemini = genai.GenerativeModel("gemini-2.5-flash")

    # ------------------------------------------------------------------
    # 단일 프레임 분석 (FER)
    # ------------------------------------------------------------------
    def analyze_frame(self, frame_path: Path) -> dict:
        img = cv2.imread(str(frame_path))
        if img is None:
            return self._empty_result()

        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        try:
            results = self._detector.detect_emotions(img_rgb)
        except Exception:
            return self._empty_result()

        if not results:
            return self._empty_result()

        faces = []
        for face_id, res in enumerate(results[:self.max_faces]):
            raw_scores = res.get("emotions", {})
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
    # Gemini Vision 보정 (피크 감정 프레임에만 적용)
    # ------------------------------------------------------------------
    def _correct_with_gemini(self, frame_path: Path, fer_emotion: str, fer_valence: float) -> dict:
        """
        FER 결과를 Gemini Vision으로 검증/보정합니다.
        실패 시 FER 결과를 그대로 반환합니다.
        """
        try:
            with open(frame_path, "rb") as f:
                image_data = base64.b64encode(f.read()).decode("utf-8")

            prompt = f"""이 이미지에서 사람의 얼굴 표정을 분석해주세요.

FER 모델 감지 결과: {fer_emotion} (valence: {fer_valence:.2f})

아래 형식으로만 답해주세요 (다른 설명 없이):
emotion: [happy/sad/angry/surprised/fearful/disgusted/neutral 중 하나]
valence: [−1.0 ~ 1.0 사이 숫자]
confidence: [0.0 ~ 1.0 사이 숫자]
corrected: [true/false - FER 결과를 보정했으면 true]"""

            response = self._gemini.generate_content([
                {"mime_type": "image/jpeg", "data": image_data},
                prompt,
            ])

            text = response.text.strip()
            lines = {
                line.split(":")[0].strip(): line.split(":", 1)[1].strip()
                for line in text.splitlines()
                if ":" in line
            }

            raw_emotion = lines.get("emotion", fer_emotion).lower()
            emotion = _GEMINI_EMOTION_MAP.get(raw_emotion, fer_emotion)
            valence = float(lines.get("valence", fer_valence))
            confidence = float(lines.get("confidence", 0.7))
            corrected = lines.get("corrected", "false").lower() == "true"

            return {
                "emotion":    emotion,
                "valence":    round(valence, 3),
                "confidence": round(confidence, 3),
                "corrected":  corrected,
                "source":     "gemini",
            }

        except Exception:
            return {
                "emotion":    fer_emotion,
                "valence":    fer_valence,
                "confidence": 0.5,
                "corrected":  False,
                "source":     "fer_fallback",
            }

    # ------------------------------------------------------------------
    # 프레임 리스트 배치 처리
    # ------------------------------------------------------------------
    def analyze_frames(self, frames: list[dict]) -> list[dict]:
        results = []
        for frame in frames:
            result = self.analyze_frame(frame["frame_path"])
            result["timestamp"] = frame["timestamp"]
            result["frame_path"] = frame["frame_path"]
            results.append(result)
        return results

    # ------------------------------------------------------------------
    # 타임라인 요약 (피크 프레임에 Gemini 보정 적용)
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

        # 피크 프레임 선정 (valence 절댓값 상위 3개)
        sorted_frames = sorted(frame_results, key=lambda r: abs(r["dominant_valence"]), reverse=True)
        peak_frames = sorted_frames[:3]

        # 피크 프레임에 Gemini 보정 적용
        gemini_corrections = {}
        for frame in peak_frames:
            fp = frame.get("frame_path")
            if fp and Path(fp).exists():
                corrected = self._correct_with_gemini(
                    Path(fp),
                    frame["dominant_emotion"],
                    frame["dominant_valence"],
                )
                if corrected["corrected"]:
                    gemini_corrections[frame["timestamp"]] = corrected

        # 보정된 감정을 타임라인에 반영
        for t in timeline:
            if t["timestamp"] in gemini_corrections:
                c = gemini_corrections[t["timestamp"]]
                t["emotion"] = c["emotion"]
                t["valence"] = c["valence"]
                t["gemini_corrected"] = True

        counts = Counter(t["emotion"] for t in timeline)
        total = len(timeline)
        distribution = {k: round(v / total, 3) for k, v in counts.items()}
        avg_valence = round(sum(t["valence"] for t in timeline) / total, 3)
        peak = max(timeline, key=lambda t: abs(t["valence"]))

        return {
            "timeline":             timeline,
            "emotion_distribution": distribution,
            "avg_valence":          avg_valence,
            "peak_emotion":         peak,
            "gemini_corrections":   len(gemini_corrections),
        }

    # ------------------------------------------------------------------
    def _empty_result(self) -> dict:
        return {
            "faces":            [],
            "face_count":       0,
            "dominant_emotion": "neutral",
            "dominant_valence": 0.0,
        }
