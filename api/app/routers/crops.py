from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.price import CommodityPrice
from app.models.user import User
from app.schemas.crops import CropSummary
from app.services import price_sync as price_sync_service

router = APIRouter(prefix="/crops", tags=["crops"])


@router.get("", response_model=list[CropSummary])
async def list_crops(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[CropSummary]:
    await price_sync_service.ensure_fresh_prices(db)

    result = await db.execute(
        select(CommodityPrice.commodity_name, CommodityPrice.commodity_group)
        .distinct()
        .order_by(CommodityPrice.commodity_name)
    )
    return [
        CropSummary(commodity_name=commodity_name, commodity_group=commodity_group)
        for commodity_name, commodity_group in result.all()
    ]
