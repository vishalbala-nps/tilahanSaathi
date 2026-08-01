from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.price import CommodityPrice
from app.models.user import User
from app.schemas.price import PriceRead
from app.services import price_sync as price_sync_service

router = APIRouter(prefix="/price", tags=["price"])


@router.get("", response_model=list[PriceRead])
async def get_prices(
    commodity_name: str | None = None,
    commodity_group: str | None = None,
    date: date | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[CommodityPrice]:
    await price_sync_service.ensure_fresh_prices(db)

    query = select(CommodityPrice)
    if commodity_name is not None:
        query = query.where(CommodityPrice.commodity_name == commodity_name)
    if commodity_group is not None:
        query = query.where(CommodityPrice.commodity_group == commodity_group)
    if date is not None:
        query = query.where(CommodityPrice.reported_date == date)
    query = query.order_by(CommodityPrice.reported_date.desc(), CommodityPrice.commodity_name)

    result = await db.execute(query)
    return list(result.scalars().all())
