# C:\dev\vibeview\server\services\fusion_engine.py

from __future__ import annotations

import logging
import math
from typing import Optional

logger = logging.getLogger(__name__)


class FusionEngine:
    """
    얼굴(MediaPipe) + 음성(Whisper/librosa) + 장면(YOLOv8/CLIP) 결과를
    하나의 종합 감정 지표로 융합합니다.

    기본 가중치: face 40% / audio 35% / scene 25%
    - 얼굴이 감지되지 않으면 audio 55% / scene 45% 로 자동 재배분
    - 결과는 viral_predictor의 핵심 입력으로 사용됩니다.
    """

    # 기본 가중치
    _W_FACE  = 0.40
    _W_AUDIO = 0.35
    _W_SCENE = 0.25

    # 얼굴 없을 때 대체 가중치
    _W_AUDIO_NO_FACE = 0.55
    _W_SCENE_NO_FACE = 0.45

    # scene vibe → valence 매핑
    _VIBE_VALENCE: dict[str, float] = {
        "활기찬":       0.80,
        "평온한":       0.20,
        "슬픈":        -0.60,
        "긴장감 있는":  -0.20,
        "재미있는":     0.70,
        "로맨틱한":     0.50,
        "무서운":      -0.70,
        "귀여운":       0.65,
        "알 수 없음":   0.00,
    }

    # highlight 추출 개수
    _MAX_HIGHLIGHTS = 3

    def fuse(
        self,
        face_summary: dict,
        audio_summary: dict,
        scene_summary: dict,
        emotion_timeline: list[dict],
    ) -> dict:
        """
        세 모달리티 결과를 융합합니다.

        Parameters
        ----------
        face_summary : FaceAnalyzer.summarize_timeline() 결과
            keys: emotion_distribution, avg_valence, peak_emotion
        audio_summary : AudioAnalyzer.analyze()["summary"] 결과
            keys: avg_valence, dominant_emotion, tempo, language, full_text
        scene_summary : SceneAnalyzer.analyze_frames()["scene_summary"] 결과
            keys: dominant_vibe, vibe_distribution, object_stats, content_type
        emotion_timeline : analyze.py _merge_timeline() 결과
            [{"timestamp", "face_valence", "audio_valence", ...}, ...]

        Returns
        -------
        dict:
            fused_valence    : float  -1 ~ +1  종합 감정 극성
            fused_emotion    : str    대표 감정 레이블 (한글)
            confidence       : float  0 ~ 1    분석 신뢰도
            modality_scores  : dict   모달리티별 valence
            highlight_moments: list   감정 강도 상위 순간
            vibe_tags        : list   장면 분위기 태그 (상위 2개)
            engagement_hint  : float  0 ~ 1    바이럴 예측 사전 지표
        """

        # ── 1. 모달리티별 valence 추출 ──────────────────────────────
        face_valence  = float(face_summary.get("avg_valence", 0.0))
        audio_valence = float(audio_summary.get("avg_valence", 0.0))
        scene_valence = self._scene_to_valence(scene_summary)

        face_detected = self._has_face(face_summary)

        # ── 2. 가중 평균 valence ────────────────────────────────────
        if face_detected:
            fused_valence = (
                face_valence  * self._W_FACE +
                audio_valence * self._W_AUDIO +
                scene_valence * self._W_SCENE
            )
        else:
            # 얼굴 없음 → audio + scene 만으로 계산
            fused_valence = (
                audio_valence * self._W_AUDIO_NO_FACE +
                scene_valence * self._W_SCENE_NO_FACE
            )

        fused_valence = round(max(-1.0, min(1.0, fused_valence)), 4)

        # ── 3. 대표 감정 레이블 ─────────────────────────────────────
        fused_emotion = self._valence_to_emotion(fused_valence)

        # ── 4. 신뢰도 (세 valence 일치도) ──────────────────────────
        confidence = self._calc_confidence(
            face_valence, audio_valence, scene_valence, face_detected
        )

        # ── 5. 하이라이트 순간 추출 ─────────────────────────────────
        highlight_moments = self._extract_highlights(emotion_timeline)

        # ── 6. vibe 태그 (상위 2개) ─────────────────────────────────
        vibe_dist: dict = scene_summary.get("vibe_distribution", {})
        vibe_tags = sorted(vibe_dist, key=vibe_dist.get, reverse=True)[:2]

        # ── 7. engagement_hint ──────────────────────────────────────
        tempo = float(audio_summary.get("tempo", 100.0))
        engagement_hint = self._calc_engagement(fused_valence, confidence, tempo)

        return {
            "fused_valence": fused_valence,
            "fused_emotion": fused_emotion,
            "confidence": confidence,
            "modality_scores": {
                "face":  round(face_valence, 4),
                "audio": round(audio_valence, 4),
                "scene": round(scene_valence, 4),
            },
            "highlight_moments": highlight_moments,
            "vibe_tags": vibe_tags,
            "engagement_hint": engagement_hint,
        }

    # ── 내부 헬퍼 ──────────────────────────────────────────────────

    def _has_face(self, face_summary: dict) -> bool:
        """얼굴이 실제로 감지됐는지 확인."""
        dist: dict = face_summary.get("emotion_distribution", {})
        # neutral 100%이고 avg_valence=0이면 얼굴 미감지로 간주
        if not dist:
            return False
        if list(dist.keys()) == ["neutral"] and face_summary.get("avg_valence", 0.0) == 0.0:
            return False
        return True

    def _scene_to_valence(self, scene_summary: dict) -> float:
        """
        vibe_distribution을 가중 평균 valence로 변환.
        ex) {"활기찬": 0.6, "귀여운": 0.4} → 0.6*0.8 + 0.4*0.65 = 0.74
        """
        vibe_dist: dict = scene_summary.get("vibe_distribution", {})
        if not vibe_dist:
            dominant = scene_summary.get("dominant_vibe", "알 수 없음")
            return self._VIBE_VALENCE.get(dominant, 0.0)

        total_weight = sum(vibe_dist.values())
        if total_weight == 0:
            return 0.0

        weighted = sum(
            self._VIBE_VALENCE.get(label, 0.0) * weight
            for label, weight in vibe_dist.items()
        )
        return round(weighted / total_weight, 4)

    def _valence_to_emotion(self, valence: float) -> str:
        """fused_valence → 대표 감정 한글 레이블."""
        if valence >= 0.6:
            return "매우 긍정적"
        elif valence >= 0.3:
            return "긍정적"
        elif valence >= 0.05:
            return "약간 긍정적"
        elif valence > -0.05:
            return "중립"
        elif valence > -0.3:
            return "약간 부정적"
        elif valence > -0.6:
            return "부정적"
        else:
            return "매우 부정적"

    def _calc_confidence(
        self,
        face_v: float,
        audio_v: float,
        scene_v: float,
        face_detected: bool,
    ) -> float:
        """
        세 모달리티 valence 표준편차 역수 기반 신뢰도.
        값이 일치할수록 confidence 높음. 0~1 범위.
        """
        if face_detected:
            values = [face_v, audio_v, scene_v]
        else:
            values = [audio_v, scene_v]

        if len(values) < 2:
            return 0.5

        mean = sum(values) / len(values)
        variance = sum((v - mean) ** 2 for v in values) / len(values)
        std = math.sqrt(variance)

        # std=0이면 완전 일치 → confidence 1.0
        # std=1이면 최대 분산 → confidence ~0.5
        confidence = 1.0 / (1.0 + std * 2)
        return round(max(0.0, min(1.0, confidence)), 4)

    def _extract_highlights(self, emotion_timeline: list[dict]) -> list[dict]:
        """
        emotion_timeline에서 face_valence + audio_valence 합의 절댓값이
        가장 큰 상위 N개 순간을 하이라이트로 반환.
        """
        if not emotion_timeline:
            return []

        scored = []
        for entry in emotion_timeline:
            face_v  = float(entry.get("face_valence", 0.0))
            audio_v = float(entry.get("audio_valence", 0.0))
            intensity = abs(face_v * 0.6 + audio_v * 0.4)

            # 두 모달리티 감정 부호 일치 여부
            same_sign = (face_v >= 0) == (audio_v >= 0)
            reason = "얼굴+음성 감정 일치" if same_sign else "얼굴+음성 감정 대비"

            scored.append({
                "timestamp": entry.get("timestamp", 0.0),
                "intensity": round(intensity, 4),
                "reason": reason,
            })

        # intensity 내림차순 정렬 후 상위 N개
        scored.sort(key=lambda x: x["intensity"], reverse=True)
        return scored[: self._MAX_HIGHLIGHTS]

    def _calc_engagement(
        self, fused_valence: float, confidence: float, tempo: float
    ) -> float:
        """
        바이럴 가능성 사전 지표 (0~1).

        계산 방식:
        - valence 절댓값: 강한 감정(긍/부정 모두)이 반응을 유도
        - confidence: 분석 신뢰도가 높을수록 실제 감정 반영
        - tempo 보정: 빠른 템포(>120 BPM)는 에너지감 증가
        """
        valence_abs = abs(fused_valence)

        # tempo 보정: 60~180 BPM 범위를 0.8~1.2로 선형 매핑
        tempo_clamped = max(60.0, min(180.0, tempo))
        tempo_factor = 0.8 + (tempo_clamped - 60.0) / (180.0 - 60.0) * 0.4

        raw = valence_abs * confidence * tempo_factor
        return round(max(0.0, min(1.0, raw)), 4)
