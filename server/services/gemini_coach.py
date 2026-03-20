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
        emotion_data: 감정 분석 결과 딕셔너리
        question: 사용자 질문 (선택)
    
    Returns:
        AI 코치 피드백 텍스트
    """

    prompt = f"""
당신은 YouTube Shorts와 TikTok 영상 전문 AI 크리에이터 코치입니다.
아래 영상 감정 분석 결과를 바탕으로 구체적이고 실용적인 피드백을 한국어로 제공해주세요.

[감정 분석 결과]
- 주요 감정: {emotion_data.get('dominant_emotion', '알 수 없음')}
- 감정 점수: {emotion_data.get('emotion_score', 0):.2f}
- 영상 길이: {emotion_data.get('duration', 0)}초
- 피사체: {', '.join(emotion_data.get('subjects', []))}
- 바이럴 점수: {emotion_data.get('viral_score', 0)}/100
- 감정 타임라인 요약: {emotion_data.get('timeline_summary', '없음')}

{"[사용자 질문]: " + question if question else ""}

다음 형식으로 피드백을 제공해주세요:
1. 핵심 분석 (2~3문장)
2. 잘된 점
3. 개선할 점
4. 구체적인 액션 아이템 (3가지)
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

    prompt = f"""
당신은 YouTube Shorts와 TikTok 트렌드 전문 분석가입니다.
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
