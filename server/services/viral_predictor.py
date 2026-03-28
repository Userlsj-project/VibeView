# C:\dev\vibeview\server\services\viral_predictor.py

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# content_type 별 기본 appeal 점수
_CONTENT_APPEAL: dict[str, float] = {
    "person":  0.80,
    "mixed":   0.75,
    "animal":  0.70,
    "none":    0.45,
}

# vibe_tag 별 보너스 점수 (최대 2개 적용)
_VIBE_BONUS: dict[str, float] = {
    "활기찬":      0.10,
    "재미있는":    0.10,
    "귀여운":      0.08,
    "로맨틱한":    0.06,
    "평온한":      0.02,
    "긴장감 있는": 0.04,
    "슬픈":       -0.02,
    "무서운":     -0.04,
    "알 수 없음":  0.00,
}

_OPTIMAL_DURATION_MIN = 15.0
_OPTIMAL_DURATION_MAX = 45.0


class ViralPredictor:
    """
    멀티모달 융합 결과를 바탕으로 바이럴 가능성 점수를 예측합니다.

    규칙 기반(rule-based) 채점으로 구현.
    (Phase 2 완성 후 실제 조회수 데이터 수집 시 ML 모델로 고도화 예정)
    """

    def predict(
        self,
        fusion_result: dict,
        face_summary: dict,
        audio_summary: dict,
        scene_summary: dict,
        video_info: dict,
    ) -> dict:
        """
        바이럴 점수를 예측합니다.

        Returns
        -------
        dict:
            viral_score      : float  0~1   종합 바이럴 점수
            grade            : str          S / A / B / C / D
            factors          : dict         5개 세부 채점 항목
            strong_points    : list[str]    잘된 점
            weak_points      : list[str]    개선 필요 점
            recommendation   : str          핵심 개선 제안 1줄
        """

        # ── 1. 세부 요소 채점 ──────────────────────────────────────
        emotional_intensity   = self._score_emotional_intensity(fusion_result)
        emotional_consistency = self._score_emotional_consistency(fusion_result)
        content_appeal        = self._score_content_appeal(scene_summary, fusion_result)
        pacing                = self._score_pacing(audio_summary, video_info)
        highlight_density     = self._score_highlight_density(fusion_result)

        factors = {
            "emotional_intensity":   round(emotional_intensity, 4),
            "emotional_consistency": round(emotional_consistency, 4),
            "content_appeal":        round(content_appeal, 4),
            "pacing":                round(pacing, 4),
            "highlight_density":     round(highlight_density, 4),
        }

        # ── 2. 가중 합산 ──────────────────────────────────────────
        viral_score = (
            emotional_intensity   * 0.30 +
            emotional_consistency * 0.20 +
            content_appeal        * 0.20 +
            pacing                * 0.15 +
            highlight_density     * 0.15
        )
        viral_score = round(max(0.0, min(1.0, viral_score)), 4)

        # ── 3. 등급 ───────────────────────────────────────────────
        grade = self._to_grade(viral_score)

        # ── 4. 강점 / 약점 분석 ───────────────────────────────────
        strong_points, weak_points = self._analyze_points(
            factors, scene_summary, video_info
        )

        # ── 5. 핵심 개선 제안 ─────────────────────────────────────
        recommendation = self._make_recommendation(weak_points, factors, video_info)

        return {
            "viral_score":    viral_score,
            "grade":          grade,
            "factors":        factors,
            "strong_points":  strong_points,
            "weak_points":    weak_points,
            "recommendation": recommendation,
        }

    # ── 세부 채점 ─────────────────────────────────────────────────

    def _score_emotional_intensity(self, fusion_result: dict) -> float:
        valence    = abs(float(fusion_result.get("fused_valence", 0.0)))
        confidence = float(fusion_result.get("confidence", 0.5))
        return valence * confidence

    def _score_emotional_consistency(self, fusion_result: dict) -> float:
        return float(fusion_result.get("confidence", 0.5))

    def _score_content_appeal(self, scene_summary: dict, fusion_result: dict) -> float:
        content_type = scene_summary.get("content_type", "none")
        base = _CONTENT_APPEAL.get(content_type, 0.45)
        vibe_tags: list = fusion_result.get("vibe_tags", [])
        bonus = sum(_VIBE_BONUS.get(tag, 0.0) for tag in vibe_tags[:2])
        return max(0.0, min(1.0, base + bonus))

    def _score_pacing(self, audio_summary: dict, video_info: dict) -> float:
        duration = float(video_info.get("duration", 30.0))
        tempo    = float(audio_summary.get("tempo", 100.0))

        if _OPTIMAL_DURATION_MIN <= duration <= _OPTIMAL_DURATION_MAX:
            duration_score = 1.0
        elif duration < _OPTIMAL_DURATION_MIN:
            duration_score = max(0.5, duration / _OPTIMAL_DURATION_MIN)
        else:
            duration_score = max(0.4, _OPTIMAL_DURATION_MAX / duration)

        if 100 <= tempo <= 140:
            tempo_score = 1.0
        elif tempo < 100:
            tempo_score = max(0.5, tempo / 100.0)
        else:
            tempo_score = max(0.5, 140.0 / tempo)

        return duration_score * 0.6 + tempo_score * 0.4

    def _score_highlight_density(self, fusion_result: dict) -> float:
        highlights: list = fusion_result.get("highlight_moments", [])
        if not highlights:
            return 0.0
        avg_intensity = sum(h.get("intensity", 0.0) for h in highlights) / len(highlights)
        count_ratio   = min(len(highlights) / 3.0, 1.0)
        return avg_intensity * count_ratio

    # ── 등급 변환 ─────────────────────────────────────────────────

    @staticmethod
    def _to_grade(score: float) -> str:
        if score >= 0.85:
            return "S"
        elif score >= 0.70:
            return "A"
        elif score >= 0.55:
            return "B"
        elif score >= 0.40:
            return "C"
        else:
            return "D"

    # ── 강점 / 약점 분석 ──────────────────────────────────────────

    @staticmethod
    def _analyze_points(
        factors: dict,
        scene_summary: dict,
        video_info: dict,
    ) -> tuple[list[str], list[str]]:
        strong, weak = [], []

        if factors["emotional_intensity"] >= 0.6:
            strong.append("강한 감정 표현으로 시청자 반응 유도")
        elif factors["emotional_intensity"] < 0.3:
            weak.append("감정 표현이 약해 시청자 반응이 낮을 수 있음")

        if factors["emotional_consistency"] >= 0.7:
            strong.append("얼굴·음성·장면 감정이 일관되게 전달됨")
        elif factors["emotional_consistency"] < 0.4:
            weak.append("얼굴·음성·장면의 감정이 엇갈려 메시지가 혼재됨")

        content_type = scene_summary.get("content_type", "none")
        if factors["content_appeal"] >= 0.75:
            strong.append(f"'{content_type}' 콘텐츠 유형은 높은 호감도를 가짐")
        elif factors["content_appeal"] < 0.5:
            weak.append("사람 또는 동물 등장이 적어 시각적 호감도가 낮음")

        duration = float(video_info.get("duration", 30.0))
        if factors["pacing"] >= 0.8:
            strong.append("영상 길이와 템포가 Shorts 최적 범위에 부합")
        elif duration > _OPTIMAL_DURATION_MAX:
            weak.append(f"영상 길이({duration:.0f}초)가 Shorts 권장 범위(15~45초)를 초과")
        elif duration < _OPTIMAL_DURATION_MIN:
            weak.append(f"영상 길이({duration:.0f}초)가 너무 짧아 임팩트 전달이 어려울 수 있음")

        if factors["highlight_density"] >= 0.6:
            strong.append("감정 피크 구간이 뚜렷해 재시청 유도 가능")
        elif factors["highlight_density"] < 0.2:
            weak.append("감정 피크 구간이 부족해 단조롭게 느껴질 수 있음")

        return strong, weak

    # ── 개선 제안 ─────────────────────────────────────────────────

    @staticmethod
    def _make_recommendation(
        weak_points: list[str],
        factors: dict,
        video_info: dict,
    ) -> str:
        if not weak_points:
            return "현재 구성이 바이럴에 최적화되어 있습니다. 꾸준한 업로드로 알고리즘 노출을 늘려보세요."

        lowest_factor = min(factors, key=factors.get)

        suggestions = {
            "emotional_intensity": (
                "영상 초반 3초 내에 가장 강한 감정 표현을 배치해 이탈률을 낮추세요."
            ),
            "emotional_consistency": (
                "배경음악, 표정, 영상 분위기를 하나의 감정 톤으로 통일하면 메시지 전달력이 높아집니다."
            ),
            "content_appeal": (
                "사람이나 동물이 화면에 자주 등장하도록 구성하면 시청자의 감정 이입을 높일 수 있습니다."
            ),
            "pacing": (
                "Shorts 최적 길이(15~45초)에 맞게 편집하고, 빠른 컷 전환으로 몰입감을 높이세요."
            ),
            "highlight_density": (
                "감정적으로 강렬한 장면을 영상 전반에 고르게 배치해 끝까지 시청하게 유도하세요."
            ),
        }

        return suggestions.get(lowest_factor, "콘텐츠 감정 표현을 더욱 강화해보세요.")
