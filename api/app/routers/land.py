from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_owned_land
from app.db.session import get_db
from app.models.land import Land
from app.models.user import User
from app.schemas.land import LandCreate, LandRead
from app.schemas.recommendation import CropRecommendationResponse
from app.services import crop_recommendation as crop_recommendation_service

router = APIRouter(prefix="/lands", tags=["lands"])


@router.post("", response_model=LandRead, status_code=status.HTTP_201_CREATED)
async def create_land(
    body: LandCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Land:
    land = Land(user_id=current_user.id, **body.model_dump())
    db.add(land)
    await db.commit()
    await db.refresh(land)
    return land


@router.get("", response_model=list[LandRead])
async def list_lands(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[Land]:
    result = await db.execute(select(Land).where(Land.user_id == current_user.id))
    return list(result.scalars().all())


@router.get("/{land_id}", response_model=LandRead)
async def get_land(
    land_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Land:
    return await get_owned_land(land_id, current_user.id, db)


@router.delete("/{land_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_land(
    land_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    land = await get_owned_land(land_id, current_user.id, db)
    await db.delete(land)
    await db.commit()


@router.post("/{land_id}/recommendations", response_model=CropRecommendationResponse)
async def recommend_crops(
    land_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CropRecommendationResponse:
    land = await get_owned_land(land_id, current_user.id, db)
    return await crop_recommendation_service.generate_recommendation(land)
