from fastapi import APIRouter

router = APIRouter()


@router.get("")
async def get_user():
    # TODO: 사용자 API 구현
    return {"message": "사용자 API - 구현 예정"}
