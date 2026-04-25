# C:\dev\vibeview\server\services\audio_analyzer.py

import librosa
import numpy as np
import whisper
from pathlib import Path
from collections import Counter


class AudioAnalyzer:
    """
    Whisper + librosa 기반 음성/BGM 감정 분석기

    감정 분류 방식: 스코어 기반 (Score-based)
    - 각 감정에 대해 여러 특징값이 얼마나 부합하는지 점수 계산
    - 가장 높은 점수의 감정 선택
    - 단순 규칙 if/else보다 다양한 BGM/음성을 정확하게 구분
    """

    def __init__(self, whisper_model: str = "base"):
        self.model = whisper.load_model(whisper_model)

    # ------------------------------------------------------------------
    # 1. STT - 언어 감지 전용
    # ------------------------------------------------------------------
    def transcribe(self, audio_path: Path) -> dict:
        result = self.model.transcribe(
            str(audio_path),
            word_timestamps=False,
            verbose=False,
        )
        return {
            "language": result.get("language", "unknown"),
        }

    # ------------------------------------------------------------------
    # 2. 음성 특징 추출 (librosa)
    # ------------------------------------------------------------------
    def extract_features(self, audio_path: Path, segment_sec: float = 1.0) -> list[dict]:
        y, sr = librosa.load(str(audio_path), sr=16000, mono=True)

        hop_length   = 512
        frame_length = 2048

        f0  = librosa.yin(y, fmin=50, fmax=400, sr=sr, hop_length=hop_length)
        rms = librosa.feature.rms(y=y, frame_length=frame_length, hop_length=hop_length)[0]
        zcr = librosa.feature.zero_crossing_rate(y, frame_length=frame_length, hop_length=hop_length)[0]

        spectral_centroid  = librosa.feature.spectral_centroid(y=y, sr=sr, hop_length=hop_length)[0]
        spectral_bandwidth = librosa.feature.spectral_bandwidth(y=y, sr=sr, hop_length=hop_length)[0]
        mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13, hop_length=hop_length)

        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
        tempo_val = float(tempo) if np.isscalar(tempo) else float(tempo[0])

        # 하모닉/퍼커시브 분리
        y_harmonic, y_percussive = librosa.effects.hpss(y)
        harmonic_rms   = float(np.mean(librosa.feature.rms(y=y_harmonic)[0]))
        percussive_rms = float(np.mean(librosa.feature.rms(y=y_percussive)[0]))
        harmonic_ratio = harmonic_rms / (harmonic_rms + percussive_rms + 1e-6)

        # 조성 분석 (장조 vs 단조)
        chroma      = librosa.feature.chroma_cqt(y=y_harmonic, sr=sr, hop_length=hop_length)
        major_score = float(np.mean(chroma[[0, 4, 7], :]))
        minor_score = float(np.mean(chroma[[0, 3, 7], :]))
        is_major    = major_score > minor_score

        # 비트 강도
        onset_env    = librosa.onset.onset_strength(y=y, sr=sr, hop_length=hop_length)
        beat_strength = float(np.mean(onset_env))

        frames_per_sec = sr / hop_length
        segment_frames = max(1, int(segment_sec * frames_per_sec))
        total_frames   = min(len(f0), len(rms), len(zcr), len(spectral_centroid))
        results        = []

        for start_frame in range(0, total_frames, segment_frames):
            end_frame  = min(start_frame + segment_frames, total_frames)
            timestamp  = round(start_frame / frames_per_sec, 2)

            f0_seg     = f0[start_frame:end_frame]
            valid_f0   = f0_seg[f0_seg > 0]
            pitch_mean = float(np.mean(valid_f0)) if len(valid_f0) > 0 else 0.0
            pitch_std  = float(np.std(valid_f0))  if len(valid_f0) > 0 else 0.0

            energy     = float(np.mean(rms[start_frame:end_frame]))
            zcr_mean   = float(np.mean(zcr[start_frame:end_frame]))
            sc_mean    = float(np.mean(spectral_centroid[start_frame:end_frame]))
            sb_mean    = float(np.mean(spectral_bandwidth[start_frame:end_frame]))
            mfcc1_mean = float(np.mean(mfcc[1, start_frame:end_frame]))

            emotion, valence = self._score_based_classify(
                pitch=pitch_mean,
                pitch_std=pitch_std,
                energy=energy,
                zcr=zcr_mean,
                tempo=tempo_val,
                spectral_centroid=sc_mean,
                spectral_bandwidth=sb_mean,
                mfcc1=mfcc1_mean,
                is_major=is_major,
                harmonic_ratio=harmonic_ratio,
                beat_strength=beat_strength,
            )

            results.append({
                "timestamp":  timestamp,
                "pitch_mean": round(pitch_mean, 2),
                "pitch_std":  round(pitch_std,  2),
                "energy":     round(energy,      5),
                "zcr":        round(zcr_mean,    5),
                "tempo":      round(tempo_val,   1),
                "emotion":    emotion,
                "valence":    valence,
            })

        return results

    # ------------------------------------------------------------------
    # 3. 스코어 기반 감정 분류
    # ------------------------------------------------------------------
    def _score_based_classify(
        self,
        pitch: float,
        pitch_std: float,
        energy: float,
        zcr: float,
        tempo: float,
        spectral_centroid: float,
        spectral_bandwidth: float,
        mfcc1: float,
        is_major: bool,
        harmonic_ratio: float,
        beat_strength: float,
    ) -> tuple[str, float]:
        """
        각 감정에 대해 특징값 부합도 점수를 계산하고
        가장 높은 점수의 감정을 반환합니다.

        BGM 감정 구분 핵심 지표:
        - is_major: 장조=밝음/긍정, 단조=어두움/부정
        - 템포: 빠름=신남/분노, 느림=슬픔/평온
        - 에너지: 높음=강한감정, 낮음=약한감정
        - spectral_centroid: 높음=밝은소리, 낮음=어두운소리
        - harmonic_ratio: 높음=멜로디위주, 낮음=리듬위주
        - zcr: 높음=거친소리, 낮음=부드러운소리
        - beat_strength: 강한비트=신남/분노
        """

        if energy < 0.001:
            return "silence", 0.0

        # 플래그 계산
        fast_tempo     = tempo > 120
        mid_tempo      = 80 <= tempo <= 120
        slow_tempo     = tempo < 80
        high_energy    = energy > 0.05
        mid_energy     = 0.02 <= energy <= 0.05
        low_energy     = energy < 0.02
        bright_sound   = spectral_centroid > 2500
        dark_sound     = spectral_centroid < 1500
        wide_band      = spectral_bandwidth > 2000
        narrow_band    = spectral_bandwidth < 1000
        rough_sound    = zcr > 0.15
        smooth_sound   = zcr < 0.06
        high_pitch     = pitch > 200
        low_pitch      = pitch < 120
        variable_pitch = pitch_std > 50
        strong_beat    = beat_strength > 2.0
        melodic        = harmonic_ratio > 0.6
        rhythmic       = harmonic_ratio < 0.4

        scores: dict[str, float] = {
            "excited":   0.0,
            "happy":     0.0,
            "neutral":   0.0,
            "sad":       0.0,
            "angry":     0.0,
            "fearful":   0.0,
            "surprised": 0.0,
        }

        # excited: 빠른 템포 + 높은 에너지 + 장조 + 강한 비트
        if fast_tempo:                       scores["excited"] += 2.0
        if high_energy:                      scores["excited"] += 1.5
        if is_major:                         scores["excited"] += 1.0
        if strong_beat:                      scores["excited"] += 1.5
        if bright_sound:                     scores["excited"] += 1.0
        if rhythmic:                         scores["excited"] += 0.5

        # happy: 장조 + 밝은 음색 + 중간~빠른 템포 + 멜로디 위주
        if is_major:                         scores["happy"] += 2.0
        if bright_sound:                     scores["happy"] += 1.5
        if mid_tempo or fast_tempo:          scores["happy"] += 1.0
        if melodic:                          scores["happy"] += 1.0
        if high_pitch:                       scores["happy"] += 0.5
        if smooth_sound:                     scores["happy"] += 0.5
        if mid_energy or high_energy:        scores["happy"] += 0.5

        # sad: 단조 + 느린 템포 + 낮은 에너지 + 어두운 음색 + 멜로디
        if not is_major:                     scores["sad"] += 2.0
        if slow_tempo:                       scores["sad"] += 2.0
        if low_energy or mid_energy:         scores["sad"] += 1.0
        if dark_sound:                       scores["sad"] += 1.5
        if melodic:                          scores["sad"] += 0.5
        if smooth_sound:                     scores["sad"] += 0.5
        if low_pitch:                        scores["sad"] += 0.5

        # angry: 빠른 템포 + 높은 에너지 + 단조 + 거친 소리
        if fast_tempo:                       scores["angry"] += 1.5
        if high_energy:                      scores["angry"] += 2.0
        if not is_major:                     scores["angry"] += 1.0
        if rough_sound:                      scores["angry"] += 2.0
        if low_pitch:                        scores["angry"] += 1.0
        if dark_sound:                       scores["angry"] += 1.0
        if strong_beat:                      scores["angry"] += 0.5

        # fearful: 단조 + 낮은 에너지 + 피치 변동 큼 + 어두운 음색 + 좁은 대역폭
        if not is_major:                     scores["fearful"] += 1.5
        if low_energy or mid_energy:         scores["fearful"] += 1.0
        if variable_pitch:                   scores["fearful"] += 2.0
        if dark_sound:                       scores["fearful"] += 1.0
        if narrow_band:                      scores["fearful"] += 1.0
        if slow_tempo or mid_tempo:          scores["fearful"] += 0.5

        # surprised: 피치 변동 매우 큼 + 중간 에너지 + 밝은 음색
        if variable_pitch:                   scores["surprised"] += 2.0
        if mid_energy or high_energy:        scores["surprised"] += 1.0
        if fast_tempo or mid_tempo:          scores["surprised"] += 1.0
        if bright_sound:                     scores["surprised"] += 0.5
        if wide_band:                        scores["surprised"] += 0.5

        # neutral: 중간 템포 + 중간 에너지 + 변동 없음
        if mid_tempo:                        scores["neutral"] += 1.5
        if mid_energy:                       scores["neutral"] += 1.5
        if not variable_pitch:               scores["neutral"] += 1.0
        if not rough_sound:                  scores["neutral"] += 0.5

        best_emotion = max(scores, key=scores.__getitem__)

        valence_map = {
            "excited":   0.8,
            "happy":     0.6,
            "neutral":   0.0,
            "sad":      -0.5,
            "angry":    -0.7,
            "fearful":  -0.4,
            "surprised": 0.1,
        }

        return best_emotion, valence_map[best_emotion]

    # ------------------------------------------------------------------
    # 4. 전체 파이프라인
    # ------------------------------------------------------------------
    def analyze(self, audio_path: Path) -> dict:
        transcription    = self.transcribe(audio_path)
        feature_timeline = self.extract_features(audio_path)

        if feature_timeline:
            avg_valence = round(
                sum(f["valence"] for f in feature_timeline) / len(feature_timeline), 3
            )
            emotion_counts   = Counter(
                f["emotion"] for f in feature_timeline if f["emotion"] != "silence"
            )
            dominant_emotion = emotion_counts.most_common(1)[0][0] if emotion_counts else "neutral"
            tempo            = feature_timeline[0]["tempo"]
        else:
            avg_valence      = 0.0
            dominant_emotion = "neutral"
            tempo            = 0.0

        return {
            "feature_timeline": feature_timeline,
            "summary": {
                "avg_valence":      avg_valence,
                "dominant_emotion": dominant_emotion,
                "tempo":            tempo,
                "language":         transcription["language"],
            },
        }
