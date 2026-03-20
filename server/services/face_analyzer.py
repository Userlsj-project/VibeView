# C:\dev\vibeview\server\services\face_analyzer.py

import cv2
import numpy as np
import mediapipe as mp
from pathlib import Path
from typing import Optional


# MediaPipe 랜드마크 인덱스 (FaceMesh 468개 중 핵심 부위)
_LANDMARKS = {
    "left_eye":    [33, 160, 158, 133, 153, 144],   # 눈 개폐 비율
    "right_eye":   [362, 385, 387, 263, 373, 380],
    "mouth_outer": [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 308],
    "mouth_inner": [78, 191, 80, 81, 82, 13, 312, 311, 310, 415, 308, 324],
    "left_brow":   [70, 63, 105, 66, 107],
    "right_brow":  [336, 296, 334, 293, 300],
    "nose_tip":    [1],
    "chin":        [152],
}


def _eye_aspect_ratio(landmarks, indices: list[int], img_w: int, img_h: int) -> float:
    """눈 종횡비 (EAR) — 졸림/놀람 판별에 사용"""
    pts = [(landmarks[i].x * img_w, landmarks[i].y * img_h) for i in indices]
    vertical1 = np.linalg.norm(np.array(pts[1]) - np.array(pts[5]))
    vertical2 = np.linalg.norm(np.array(pts[2]) - np.array(pts[4]))
    horizontal = np.linalg.norm(np.array(pts[0]) - np.array(pts[3]))
    return (vertical1 + vertical2) / (2.0 * horizontal + 1e-6)


def _mouth_aspect_ratio(landmarks, outer: list[int], inner: list[int], img_w: int, img_h: int) -> float:
    """입 종횡비 — 놀람/행복 판별"""
    def pts(indices):
        return [(landmarks[i].x * img_w, landmarks[i].y * img_h) for i in indices]

    outer_pts = pts(outer)
    top = outer_pts[0]
    bottom = outer_pts[6]
    left = outer_pts[11]
    right = outer_pts[5]

    vertical = np.linalg.norm(np.array(top) - np.array(bottom))
    horizontal = np.linalg.norm(np.array(left) - np.array(right))
    return vertical / (horizontal + 1e-6)


def _brow_raise_ratio(landmarks, brow_indices: list[int], eye_indices: list[int],
                      img_h: int) -> float:
    """눈썹 위치 — 놀람/분노 판별 (낮을수록 눈썹이 올라감)"""
    brow_y = np.mean([landmarks[i].y * img_h for i in brow_indices])
    eye_y = np.mean([landmarks[i].y * img_h for i in eye_indices])
    return (eye_y - brow_y) / (img_h + 1e-6)


def classify_emotion(ear: float, mar: float, brow: float) -> dict:
    """
    EAR / MAR / brow 수치로 기본 감정 분류 + 신뢰도 점수 반환

    Returns:
        {"emotion": str, "scores": {emotion: float}, "valence": float}
        valence: -1(부정) ~ +1(긍정)
    """
    scores = {
        "happy":    0.0,
        "surprised": 0.0,
        "angry":    0.0,
        "sad":      0.0,
        "neutral":  0.0,
    }

    # 입이 벌어짐 + 눈 크게 뜸 → 놀람
    if mar > 0.45 and ear > 0.28:
        scores["surprised"] += 0.7
        scores["happy"] += 0.2

    # 입 크게 벌림(웃음) + 눈 정상
    elif mar > 0.35:
        scores["happy"] += 0.6
        scores["surprised"] += 0.2

    # 눈썹 낮음(찌푸림) + 눈 좁아짐
    if brow < 0.045 and ear < 0.24:
        scores["angry"] += 0.5

    # 눈 많이 감김 + 입 다문 → 슬픔
    if ear < 0.22 and mar < 0.2:
        scores["sad"] += 0.4

    # 나머지를 neutral로
    total = sum(scores.values())
    if total < 0.3:
        scores["neutral"] = 1.0
    else:
        # 정규화
        for k in scores:
            scores[k] = round(scores[k] / max(total, 1.0), 3)

    emotion = max(scores, key=scores.get)

    valence_map = {"happy": 0.8, "surprised": 0.1, "angry": -0.7, "sad": -0.6, "neutral": 0.0}
    valence = valence_map[emotion]

    return {"emotion": emotion, "scores": scores, "valence": valence}


class FaceAnalyzer:
    """
    MediaPipe FaceMesh 기반 얼굴 감정 분석기
    - 프레임 단위 또는 프레임 리스트 배치 처리
    """

    def __init__(self, max_faces: int = 4, min_detection_confidence: float = 0.5):
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=max_faces,
            refine_landmarks=True,
            min_detection_confidence=min_detection_confidence,
        )

    # ------------------------------------------------------------------
    # 단일 프레임 분석
    # ------------------------------------------------------------------
    def analyze_frame(self, frame_path: Path) -> dict:
        """
        단일 프레임 이미지를 분석합니다.

        Args:
            frame_path: 프레임 이미지 경로 (.jpg/.png)

        Returns:
            {
                "timestamp": float (frame_path에서 추출 불가시 0.0),
                "faces": [
                    {
                        "face_id": int,
                        "emotion": str,
                        "scores": {emotion: float},
                        "valence": float,
                        "ear": float,
                        "mar": float,
                        "brow": float,
                    }
                ],
                "face_count": int,
                "dominant_emotion": str,
                "dominant_valence": float,
            }
        """
        img = cv2.imread(str(frame_path))
        if img is None:
            return self._empty_result()

        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        h, w = img_rgb.shape[:2]

        results = self.face_mesh.process(img_rgb)

        faces = []
        if results.multi_face_landmarks:
            for face_id, lm in enumerate(results.multi_face_landmarks):
                lms = lm.landmark

                ear_l = _eye_aspect_ratio(lms, _LANDMARKS["left_eye"], w, h)
                ear_r = _eye_aspect_ratio(lms, _LANDMARKS["right_eye"], w, h)
                ear = (ear_l + ear_r) / 2

                mar = _mouth_aspect_ratio(
                    lms,
                    _LANDMARKS["mouth_outer"],
                    _LANDMARKS["mouth_inner"],
                    w, h,
                )

                brow_l = _brow_raise_ratio(lms, _LANDMARKS["left_brow"], _LANDMARKS["left_eye"], h)
                brow_r = _brow_raise_ratio(lms, _LANDMARKS["right_brow"], _LANDMARKS["right_eye"], h)
                brow = (brow_l + brow_r) / 2

                emo = classify_emotion(ear, mar, brow)

                faces.append({
                    "face_id": face_id,
                    "emotion": emo["emotion"],
                    "scores": emo["scores"],
                    "valence": emo["valence"],
                    "ear": round(ear, 4),
                    "mar": round(mar, 4),
                    "brow": round(brow, 4),
                })

        dominant_emotion = "neutral"
        dominant_valence = 0.0
        if faces:
            # valence 절댓값이 가장 큰 얼굴을 대표로
            dominant = max(faces, key=lambda f: abs(f["valence"]))
            dominant_emotion = dominant["emotion"]
            dominant_valence = dominant["valence"]

        return {
            "faces": faces,
            "face_count": len(faces),
            "dominant_emotion": dominant_emotion,
            "dominant_valence": dominant_valence,
        }

    # ------------------------------------------------------------------
    # 프레임 리스트 배치 처리
    # ------------------------------------------------------------------
    def analyze_frames(self, frames: list[dict]) -> list[dict]:
        """
        video_processor.process()의 frames 리스트를 받아 일괄 분석합니다.

        Args:
            frames: [{"timestamp": float, "frame_path": Path}, ...]

        Returns:
            [{"timestamp": float, ...analyze_frame() 결과}, ...]
        """
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
        """
        프레임별 결과를 받아 초 단위 감정 타임라인 + 전체 요약 반환

        Returns:
            {
                "timeline": [{"timestamp": float, "emotion": str, "valence": float}],
                "emotion_distribution": {emotion: float},   # 비율
                "avg_valence": float,
                "peak_emotion": {"timestamp": float, "emotion": str, "valence": float},
            }
        """
        timeline = [
            {
                "timestamp": r["timestamp"],
                "emotion": r["dominant_emotion"],
                "valence": r["dominant_valence"],
            }
            for r in frame_results
        ]

        if not timeline:
            return {
                "timeline": [],
                "emotion_distribution": {},
                "avg_valence": 0.0,
                "peak_emotion": None,
            }

        # 감정 분포
        from collections import Counter
        counts = Counter(t["emotion"] for t in timeline)
        total = len(timeline)
        distribution = {k: round(v / total, 3) for k, v in counts.items()}

        # 평균 valence
        avg_valence = round(sum(t["valence"] for t in timeline) / total, 3)

        # 피크 (valence 절댓값 최대)
        peak = max(timeline, key=lambda t: abs(t["valence"]))

        return {
            "timeline": timeline,
            "emotion_distribution": distribution,
            "avg_valence": avg_valence,
            "peak_emotion": peak,
        }

    # ------------------------------------------------------------------
    def _empty_result(self) -> dict:
        return {
            "faces": [],
            "face_count": 0,
            "dominant_emotion": "neutral",
            "dominant_valence": 0.0,
        }

    def __del__(self):
        try:
            self.face_mesh.close()
        except Exception:
            pass