import firebase_admin.auth as firebase_auth
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.firebase import verify_firebase_id_token
from app.core.security import create_access_token
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import FirebaseLoginRequest, LoginResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
async def login(body: FirebaseLoginRequest, db: AsyncSession = Depends(get_db)) -> LoginResponse:
    try:
        firebase_user = verify_firebase_id_token(body.firebase_id_token)
    except firebase_auth.InvalidIdTokenError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Firebase ID token") from exc
    except firebase_auth.ExpiredIdTokenError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Expired Firebase ID token") from exc

    result = await db.execute(select(User).where(User.id == firebase_user.uid))
    user = result.scalar_one_or_none()

    if user is None:
        user = User(
            id=firebase_user.uid,
            email=firebase_user.email,
            display_name=firebase_user.name,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    access_token = create_access_token(user.id)
    return LoginResponse(user_id=user.id, access_token=access_token)

