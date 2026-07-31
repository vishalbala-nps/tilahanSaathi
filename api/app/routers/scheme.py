from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.land import Land
from app.models.oilseed import Oilseed
from app.models.user import User
from app.schemas.scheme import SchemeRecommendationResponse
from app.services import scheme_recommendation as scheme_recommendation_service

router = APIRouter(prefix="/schemes", tags=["schemes"])


@router.post("/recommendations", response_model=SchemeRecommendationResponse)
async def recommend_schemes(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SchemeRecommendationResponse:
    lands_result = await db.execute(select(Land).where(Land.user_id == current_user.id))
    lands = list(lands_result.scalars().all())
    if not lands:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Add at least one land before requesting scheme suggestions",
        )

    oilseeds_result = await db.execute(
        select(Oilseed).join(Land, Oilseed.land_id == Land.id).where(Land.user_id == current_user.id)
    )
    oilseeds = list(oilseeds_result.scalars().all())

    return await scheme_recommendation_service.generate_scheme_recommendations(lands, oilseeds, db)
