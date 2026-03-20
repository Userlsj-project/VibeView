from fastapi import APIRouter

router = APIRouter()


@router.get("")
async def get_trend():
    # TODO: 감정 트렌드 구현
    return {"message": "트렌드 API - 구현 예정"}
