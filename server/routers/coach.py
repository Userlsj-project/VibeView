from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.gemini_coach import get_coach_feedback

router = APIRouter()


class CoachRequest(BaseModel):
    video_id: str
    emotion_data: dict
    question: str = None


class CoachResponse(BaseModel):
    feedback: str


@router.post("", response_model=CoachResponse)
async def coach(request: CoachRequest):
    try:
        feedback = get_coach_feedback(
            emotion_data=request.emotion_data,
            question=request.question
        )
        return CoachResponse(feedback=feedback)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
