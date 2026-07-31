from fastapi import APIRouter, Depends, HTTPException, status
from app.api.deps import get_current_user
from app.schemas.user import UserRead
from app.models.user import User

router = APIRouter(prefix="/user", tags=["user"])

@router.get("/", response_model=UserRead)
async def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user