# C:\dev\vibeview\server\services\scene_analyzer.py

from __future__ import annotations

import logging
from pathlib import Path
from collections import Counter, defaultdict
from typing import Optional

import cv2
import numpy as np
import torch

logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────
# CLIP 분위기 프롬프트 레이블 (영/한 매핑)
# ─────────────────────────────────────────────
_VIBE_PROMPTS = [
    "a joyful and energetic scene",
    "a calm and peaceful scene",
    "a sad and melancholic scene",
    "an intense and dramatic scene",
    "a funny and comedic scene",
    "a romantic and tender scene",
    "a scary and tense scene",
    "a cute and adorable scene",
]

_VIBE_LABELS_KO = {
    "a joyful and energetic scene":   "활기찬",
    "a calm and peaceful scene":      "평온한",
    "a sad and melancholic scene":    "슬픈",
    "an intense and dramatic scene":  "긴장감 있는",
    "a funny and comedic scene":      "재미있는",
    "a romantic and tender scene":    "로맨틱한",
    "a scary and tense scene":        "무서운",
    "a cute and adorable scene":      "귀여운",
}

# YOLOv8 클래스 → 카테고리 매핑 (COCO 80 classes 기준)
_YOLO_CATEGORY = {
    # 사람
    0: "person",
    # 동물
    14: "bird", 15: "cat", 16: "dog", 17: "horse", 18: "sheep",
    19: "cow", 20: "elephant", 21: "bear", 22: "zebra", 23: "giraffe",
}


class SceneAnalyzer:
    """
    YOLOv8 + CLIP 기반 장면 분석기

    analyze_frames(frames) → {
        "scene_timeline": [...],
        "scene_summary": {
            "dominant_vibe": str,           # 대표 분위기 (한글)
            "vibe_distribution": {...},     # 분위기별 비율
            "object_stats": {
                "person_ratio": float,      # 사람 등장 프레임 비율
                "animal_ratio": float,      # 동물 등장 프레임 비율
                "avg_person_count": float,  # 평균 사람 수
            },
            "content_type": str,            # "person" / "animal" / "mixed" / "none"
        }
    }
    """

    def __init__(self, yolo_model: str = "yolov8n.pt", device: Optional[str] = None):
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self._yolo = None
        self._clip_model = None
        self._clip_preprocess = None
        self._clip_text_features = None
        self._yolo_model_name = yolo_model

    # ──────────────────────────────────────────
    # 지연 로드 (서버 시작 시 메모리 절약)
    # ──────────────────────────────────────────
    def _load_yolo(self):
        if self._yolo is None:
            try:
                from ultralytics import YOLO
                self._yolo = YOLO(self._yolo_model_name)
                logger.info(f"YOLOv8 로드 완료: {self._yolo_model_name}")
            except Exception as e:
                raise RuntimeError(f"YOLOv8 로드 실패: {e}") from e

    def _load_clip(self):
        if self._clip_model is None:
            try:
                import clip  # openai-clip 패키지
                model, preprocess = clip.load("ViT-B/32", device=self.device)
                self._clip_model = model
                self._clip_preprocess = preprocess

                # 텍스트 프롬프트 사전 인코딩 (한 번만)
                text_tokens = clip.tokenize(_VIBE_PROMPTS).to(self.device)
                with torch.no_grad():
                    self._clip_text_features = self._clip_model.encode_text(text_tokens)
                    self._clip_text_features /= self._clip_text_features.norm(dim=-1, keepdim=True)
                logger.info("CLIP 로드 완료: ViT-B/32")
            except Exception as e:
                raise RuntimeError(f"CLIP 로드 실패: {e}") from e

    # ──────────────────────────────────────────
    # 퍼블릭 API
    # ──────────────────────────────────────────
    def analyze_frames(self, frames: list[dict]) -> dict:
        """
        video_processor.extract_frames() 결과를 받아 장면 분석 수행.

        Parameters
        ----------
        frames : list[dict]
            [{"timestamp": float, "frame_path": Path}, ...]

        Returns
        -------
        dict : scene_timeline + scene_summary
        """
        if not frames:
            return self._empty_result()

        self._load_yolo()
        self._load_clip()

        scene_timeline = []
        vibe_counter: Counter = Counter()
        person_frames = 0
        animal_frames = 0
        person_counts: list[int] = []

        for item in frames:
            frame_path = Path(item["frame_path"])
            timestamp = item["timestamp"]

            if not frame_path.exists():
                logger.warning(f"프레임 파일 없음: {frame_path}")
                continue

            # BGR 이미지 로드
            img_bgr = cv2.imread(str(frame_path))
            if img_bgr is None:
                continue

            # 1) YOLOv8 객체 감지
            yolo_result = self._run_yolo(img_bgr)

            # 2) CLIP 분위기 분석
            vibe_label, vibe_score = self._run_clip(img_bgr)

            # 집계
            vibe_counter[vibe_label] += 1
            if yolo_result["person_count"] > 0:
                person_frames += 1
            if yolo_result["animal_count"] > 0:
                animal_frames += 1
            person_counts.append(yolo_result["person_count"])

            scene_timeline.append({
                "timestamp": timestamp,
                "vibe": vibe_label,
                "vibe_score": round(float(vibe_score), 4),
                "person_count": yolo_result["person_count"],
                "animal_count": yolo_result["animal_count"],
                "detected_objects": yolo_result["detected_objects"],
            })

        total = len(scene_timeline)
        if total == 0:
            return self._empty_result()

        # 분위기 분포 (비율)
        vibe_distribution = {
            _VIBE_LABELS_KO[k]: round(v / total, 3)
            for k, v in vibe_counter.most_common()
        }
        dominant_vibe_en = vibe_counter.most_common(1)[0][0]
        dominant_vibe = _VIBE_LABELS_KO[dominant_vibe_en]

        person_ratio = round(person_frames / total, 3)
        animal_ratio = round(animal_frames / total, 3)
        avg_person_count = round(sum(person_counts) / len(person_counts), 2)

        # 콘텐츠 유형 판별
        content_type = self._classify_content(person_ratio, animal_ratio)

        scene_summary = {
            "dominant_vibe": dominant_vibe,
            "vibe_distribution": vibe_distribution,
            "object_stats": {
                "person_ratio": person_ratio,
                "animal_ratio": animal_ratio,
                "avg_person_count": avg_person_count,
            },
            "content_type": content_type,
        }

        return {
            "scene_timeline": scene_timeline,
            "scene_summary": scene_summary,
        }

    # ──────────────────────────────────────────
    # 내부 메서드
    # ──────────────────────────────────────────
    def _run_yolo(self, img_bgr: np.ndarray) -> dict:
        """YOLOv8으로 사람/동물 감지."""
        try:
            results = self._yolo(img_bgr, verbose=False)
        except Exception as e:
            logger.warning(f"YOLO 추론 실패: {e}")
            return {"person_count": 0, "animal_count": 0, "detected_objects": []}

        person_count = 0
        animal_count = 0
        detected: list[str] = []

        if results and len(results) > 0:
            boxes = results[0].boxes
            if boxes is not None:
                for cls_id in boxes.cls.cpu().numpy().astype(int):
                    category = _YOLO_CATEGORY.get(int(cls_id))
                    if category == "person":
                        person_count += 1
                        if "person" not in detected:
                            detected.append("person")
                    elif category is not None:
                        animal_count += 1
                        if category not in detected:
                            detected.append(category)

        return {
            "person_count": person_count,
            "animal_count": animal_count,
            "detected_objects": detected,
        }

    def _run_clip(self, img_bgr: np.ndarray) -> tuple[str, float]:
        """CLIP으로 장면 분위기 분류. (프롬프트 레이블, 유사도 점수) 반환."""
        try:
            import clip
            from PIL import Image

            img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
            pil_img = Image.fromarray(img_rgb)

            img_tensor = self._clip_preprocess(pil_img).unsqueeze(0).to(self.device)
            with torch.no_grad():
                image_features = self._clip_model.encode_image(img_tensor)
                image_features /= image_features.norm(dim=-1, keepdim=True)

            # 코사인 유사도
            similarities = (image_features @ self._clip_text_features.T).squeeze(0)
            best_idx = int(similarities.argmax().item())
            best_score = float(similarities[best_idx].item())

            return _VIBE_PROMPTS[best_idx], best_score

        except Exception as e:
            logger.warning(f"CLIP 추론 실패: {e}")
            return _VIBE_PROMPTS[0], 0.0

    @staticmethod
    def _classify_content(person_ratio: float, animal_ratio: float) -> str:
        if person_ratio >= 0.5 and animal_ratio >= 0.3:
            return "mixed"
        elif person_ratio >= 0.3:
            return "person"
        elif animal_ratio >= 0.3:
            return "animal"
        else:
            return "none"

    @staticmethod
    def _empty_result() -> dict:
        return {
            "scene_timeline": [],
            "scene_summary": {
                "dominant_vibe": "알 수 없음",
                "vibe_distribution": {},
                "object_stats": {
                    "person_ratio": 0.0,
                    "animal_ratio": 0.0,
                    "avg_person_count": 0.0,
                },
                "content_type": "none",
            },
        }
