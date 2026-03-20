# C:\dev\vibeview\server\services\audio_analyzer.py

import librosa
import numpy as np
import whisper
from pathlib import Path
from typing import Optional


class AudioAnalyzer:
    """
    Whisper + librosa 기반 음성 감정 분석기
    - Whisper: STT (발화 내용 + 타임스탬프)
    - librosa: 피치 / 에너지 / 템포 추출 → 감정 분류
    """

    def __init__(self, whisper_model: str = "base"):
        """
        Args:
            whisper_model: "tiny" / "base" / "small" / "medium"
                           중간 발표용은 "base" 권장 (속도/정확도 균형)
        """
        self.model = whisper.load_model(whisper_model)

    # ------------------------------------------------------------------
    # 1. STT — 발화 내용 + 타임스탬프
    # ------------------------------------------------------------------
    def transcribe(self, audio_path: Path) -> dict:
        """
        Whisper로 음성을 텍스트로 변환합니다.

        Returns:
            {
                "text": str,           # 전체 발화 내용
                "language": str,       # 감지된 언어
                "segments": [
                    {
                        "start": float,
                        "end": float,
                        "text": str,
                    }
                ]
            }
        """
        result = self.model.transcribe(
            str(audio_path),
            word_timestamps=False,
            verbose=False,
        )

        segments = [
            {
                "start": round(seg["start"], 2),
                "end": round(seg["end"], 2),
                "text": seg["text"].strip(),
            }
            for seg in result.get("segments", [])
        ]

        return {
            "text": result.get("text", "").strip(),
            "language": result.get("language", "unknown"),
            "segments": segments,
        }

    # ------------------------------------------------------------------
    # 2. 음성 특징 추출 (librosa)
    # ------------------------------------------------------------------
    def extract_features(self, audio_path: Path, segment_sec: float = 1.0) -> list[dict]:
        """
        librosa로 초 단위 음성 특징을 추출합니다.

        Args:
            segment_sec: 분석 단위 (초). 기본 1초

        Returns:
            [
                {
                    "timestamp": float,
                    "pitch_mean": float,    # 평균 피치 (Hz)
                    "pitch_std": float,     # 피치 변동성
                    "energy": float,        # RMS 에너지
                    "zcr": float,           # 영교차율
                    "tempo": float,         # 추정 템포 (BPM)
                    "emotion": str,
                    "valence": float,
                }
            ]
        """
        y, sr = librosa.load(str(audio_path), sr=16000, mono=True)

        hop_length = 512
        frame_length = 2048

        # 피치 추출 (yin 알고리즘)
        f0 = librosa.yin(y, fmin=50, fmax=400, sr=sr, hop_length=hop_length)

        # RMS 에너지
        rms = librosa.feature.rms(y=y, frame_length=frame_length, hop_length=hop_length)[0]

        # 영교차율
        zcr = librosa.feature.zero_crossing_rate(y, frame_length=frame_length, hop_length=hop_length)[0]

        # 전체 템포 (1회 추정)
        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
        tempo_val = float(tempo) if np.isscalar(tempo) else float(tempo[0])

        # 프레임 → 초 단위로 묶기
        frames_per_sec = sr / hop_length
        segment_frames = max(1, int(segment_sec * frames_per_sec))

        total_frames = min(len(f0), len(rms), len(zcr))
        results = []

        for start_frame in range(0, total_frames, segment_frames):
            end_frame = min(start_frame + segment_frames, total_frames)
            timestamp = round(start_frame / frames_per_sec, 2)

            f0_seg = f0[start_frame:end_frame]
            valid_f0 = f0_seg[f0_seg > 0]
            pitch_mean = float(np.mean(valid_f0)) if len(valid_f0) > 0 else 0.0
            pitch_std = float(np.std(valid_f0)) if len(valid_f0) > 0 else 0.0

            energy = float(np.mean(rms[start_frame:end_frame]))
            zcr_mean = float(np.mean(zcr[start_frame:end_frame]))

            emotion, valence = self._classify_emotion(pitch_mean, pitch_std, energy, zcr_mean)

            results.append({
                "timestamp": timestamp,
                "pitch_mean": round(pitch_mean, 2),
                "pitch_std": round(pitch_std, 2),
                "energy": round(energy, 5),
                "zcr": round(zcr_mean, 5),
                "tempo": round(tempo_val, 1),
                "emotion": emotion,
                "valence": valence,
            })

        return results

    # ------------------------------------------------------------------
    # 3. 감정 분류
    # ------------------------------------------------------------------
    def _classify_emotion(self, pitch: float, pitch_std: float,
                          energy: float, zcr: float) -> tuple[str, float]:
        """
        피치 / 에너지 / ZCR 기반 규칙 기반 감정 분류

        Returns:
            (emotion: str, valence: float)
        """
        # 무음 구간
        if energy < 0.001:
            return "silence", 0.0

        # 높은 피치 + 높은 에너지 + 피치 변동 큼 → 흥분/기쁨
        if pitch > 220 and energy > 0.05 and pitch_std > 30:
            return "excited", 0.7

        # 높은 피치 + 낮은 에너지 → 질문/불안
        if pitch > 200 and energy < 0.03:
            return "anxious", -0.3

        # 낮은 피치 + 높은 에너지 + ZCR 높음 → 분노
        if pitch < 130 and energy > 0.06 and zcr > 0.1:
            return "angry", -0.7

        # 낮은 피치 + 낮은 에너지 → 슬픔/침울
        if pitch < 140 and energy < 0.025:
            return "sad", -0.5

        # 중간 피치 + 중간 에너지 → 평온
        return "neutral", 0.0

    # ------------------------------------------------------------------
    # 4. 전체 파이프라인
    # ------------------------------------------------------------------
    def analyze(self, audio_path: Path) -> dict:
        """
        STT + 음성 특징 추출을 한 번에 실행합니다.

        Returns:
            {
                "transcription": {...},
                "feature_timeline": [...],
                "summary": {
                    "avg_valence": float,
                    "dominant_emotion": str,
                    "tempo": float,
                    "language": str,
                    "full_text": str,
                }
            }
        """
        transcription = self.transcribe(audio_path)
        feature_timeline = self.extract_features(audio_path)

        if feature_timeline:
            avg_valence = round(
                sum(f["valence"] for f in feature_timeline) / len(feature_timeline), 3
            )
            from collections import Counter
            emotion_counts = Counter(
                f["emotion"] for f in feature_timeline if f["emotion"] != "silence"
            )
            dominant_emotion = emotion_counts.most_common(1)[0][0] if emotion_counts else "neutral"
            tempo = feature_timeline[0]["tempo"]
        else:
            avg_valence = 0.0
            dominant_emotion = "neutral"
            tempo = 0.0

        return {
            "transcription": transcription,
            "feature_timeline": feature_timeline,
            "summary": {
                "avg_valence": avg_valence,
                "dominant_emotion": dominant_emotion,
                "tempo": tempo,
                "language": transcription["language"],
                "full_text": transcription["text"],
            },
        }