# C:\dev\vibeview\server\services\gemini_coach.py

import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-2.5-flash")


def get_coach_feedback(emotion_data: dict, question: str = None) -> str:
    """
    감정 분석 결과를 바탕으로 AI 코치 피드백 생성

    Args:
        emotion_data: 분석 결과 딕셔너리 (face_summary, audio_summary, video_info 포함)
        question: 사용자 질문 (선택)

    Returns:
        AI 코치 피드백 텍스트
    """

    # face_summary 파싱
    face_summary = emotion_data.get("face_summary") or {}
    face_dist    = face_summary.get("emotion_distribution", {})
    face_peak    = face_summary.get("peak_emotion") or {}
    face_valence = face_summary.get("avg_valence", 0)

    # audio_summary 파싱
    audio_summary    = emotion_data.get("audio_summary") or {}
    audio_emotion    = audio_summary.get("dominant_emotion", "알 수 없음")
    audio_valence    = audio_summary.get("avg_valence", 0)
    audio_tempo      = audio_summary.get("tempo", 0)
    audio_language   = audio_summary.get("language", "알 수 없음")

    # video_info 파싱
    video_info = emotion_data.get("video_info") or {}
    duration   = video_info.get("duration", 0)

    # 얼굴 감정 분포 텍스트 변환
    face_dist_str = ", ".join(
        f"{k}: {round(v * 100)}%" for k, v in face_dist.items()
    ) if face_dist else "데이터 없음"

    peak_emotion_str = (
        f"{face_peak.get('emotion', '없음')} "
        f"(타임스탬프: {face_peak.get('timestamp', 0)}초, "
        f"감정극성: {face_peak.get('valence', 0)})"
    ) if face_peak else "데이터 없음"

    prompt = f"""당신은 YouTube Shorts 영상 전문 AI 크리에이터 코치입니다.
아래 영상 감정 분석 결과를 바탕으로 구체적이고 실용적인 피드백을 한국어로 제공해주세요.

[영상 기본 정보]
- 영상 길이: {duration}초

[얼굴 감정 분석]
- 감정 분포: {face_dist_str}
- 평균 감정 극성: {face_valence} (-1: 매우 부정적 ~ +1: 매우 긍정적)
- 피크 감정: {peak_emotion_str}

[음성 감정 분석]
- 주요 감정: {audio_emotion}
- 평균 감정 극성: {audio_valence}
- 템포: {audio_tempo} BPM
- 감지 언어: {audio_language}

{"[사용자 질문]: " + question if question else ""}

다음 형식으로 피드백을 제공해주세요:

## 핵심 분석
(2~3문장으로 영상의 전반적인 감정 흐름 요약)

## 잘된 점
- (구체적인 장점 2~3가지)

## 개선할 점
- (구체적인 개선점 2~3가지)

## 액션 아이템
1. (구체적인 실천 방법)
2. (구체적인 실천 방법)
3. (구체적인 실천 방법)
"""

    response = model.generate_content(prompt)
    return response.text


def get_trend_analysis(trend_data: list) -> str:
    """
    최근 바이럴 영상 트렌드 분석

    Args:
        trend_data: 최근 영상 감정 데이터 리스트

    Returns:
        트렌드 분석 텍스트
    """
    prompt = f"""당신은 YouTube Shorts 트렌드 전문 분석가입니다.
아래 최근 바이럴 영상들의 감정 데이터를 분석해서 현재 트렌드를 한국어로 설명해주세요.

[최근 바이럴 영상 감정 데이터]
{trend_data}

다음을 포함해서 분석해주세요:
1. 현재 유행하는 감정 흐름
2. 조회수가 높은 영상의 공통 패턴
3. 크리에이터를 위한 트렌드 활용 팁
"""

    response = model.generate_content(prompt)
    return response.text
