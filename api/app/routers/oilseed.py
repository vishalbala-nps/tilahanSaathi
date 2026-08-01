from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_owned_land
from app.db.session import get_db
from app.models.crop_calendar import CropCalendar, CropCalendarActivity
from app.models.oilseed import Oilseed
from app.models.price import CommodityPrice
from app.models.user import User
from app.schemas.calendar import ActivityCompleteRequest, CalendarRead
from app.schemas.oilseed import OilseedCreate, OilseedRead
from app.schemas.price import PriceRead
from app.services import crop_calendar as crop_calendar_service
from app.services import price_sync as price_sync_service
from app.services.crop_recommendation import validate_crop_season

router = APIRouter(prefix="/lands/{land_id}/oilseeds", tags=["oilseeds"])


@router.post("", response_model=OilseedRead, status_code=status.HTTP_201_CREATED)
async def create_oilseed(
    land_id: int,
    body: OilseedCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Oilseed:
    await get_owned_land(land_id, current_user.id, db)
    validate_crop_season(body.crop, body.sowing_date)
    oilseed = Oilseed(land_id=land_id, crop=body.crop, sowing_date=body.sowing_date)
    db.add(oilseed)
    await db.commit()
    await db.refresh(oilseed)
    return oilseed


@router.get("", response_model=list[OilseedRead])
async def list_oilseeds(
    land_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[Oilseed]:
    await get_owned_land(land_id, current_user.id, db)
    result = await db.execute(select(Oilseed).where(Oilseed.land_id == land_id))
    return list(result.scalars().all())


async def _get_owned_oilseed(land_id: int, oilseed_id: int, db: AsyncSession) -> Oilseed:
    result = await db.execute(
        select(Oilseed).where(Oilseed.id == oilseed_id, Oilseed.land_id == land_id)
    )
    oilseed = result.scalar_one_or_none()
    if oilseed is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Oilseed not found")
    return oilseed


@router.get("/{oilseed_id}", response_model=OilseedRead)
async def get_oilseed(
    land_id: int,
    oilseed_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Oilseed:
    await get_owned_land(land_id, current_user.id, db)
    return await _get_owned_oilseed(land_id, oilseed_id, db)


@router.delete("/{oilseed_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_oilseed(
    land_id: int,
    oilseed_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    await get_owned_land(land_id, current_user.id, db)
    oilseed = await _get_owned_oilseed(land_id, oilseed_id, db)
    await db.delete(oilseed)
    await db.commit()


async def _get_calendar_with_activities(
    oilseed_id: int, db: AsyncSession
) -> tuple[CropCalendar, list[CropCalendarActivity]] | None:
    result = await db.execute(
        select(CropCalendar)
        .where(CropCalendar.oilseed_id == oilseed_id)
        .order_by(CropCalendar.created_at.desc())
        .limit(1)
    )
    calendar = result.scalar_one_or_none()
    if calendar is None:
        return None
    activities_result = await db.execute(
        select(CropCalendarActivity)
        .where(CropCalendarActivity.calendar_id == calendar.id)
        .order_by(CropCalendarActivity.start_date)
    )
    return calendar, list(activities_result.scalars().all())


@router.post("/{oilseed_id}/calendar", response_model=CalendarRead, status_code=status.HTTP_201_CREATED)
async def create_calendar(
    land_id: int,
    oilseed_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CalendarRead:
    land = await get_owned_land(land_id, current_user.id, db)
    oilseed = await _get_owned_oilseed(land_id, oilseed_id, db)
    calendar = await crop_calendar_service.generate_calendar(land, oilseed, db)
    found = await _get_calendar_with_activities(oilseed.id, db)
    assert found is not None  # we just created it
    calendar, activities = found
    return crop_calendar_service.build_calendar_read(calendar, oilseed, activities)


@router.get("/{oilseed_id}/calendar", response_model=CalendarRead)
async def get_calendar(
    land_id: int,
    oilseed_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CalendarRead:
    await get_owned_land(land_id, current_user.id, db)
    oilseed = await _get_owned_oilseed(land_id, oilseed_id, db)
    found = await _get_calendar_with_activities(oilseed.id, db)
    if found is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No calendar found for this oilseed")
    calendar, activities = found
    return crop_calendar_service.build_calendar_read(calendar, oilseed, activities)


@router.patch("/{oilseed_id}/calendar/activities/{activity_id}", response_model=CalendarRead)
async def complete_calendar_activity(
    land_id: int,
    oilseed_id: int,
    activity_id: int,
    body: ActivityCompleteRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CalendarRead:
    await get_owned_land(land_id, current_user.id, db)
    oilseed = await _get_owned_oilseed(land_id, oilseed_id, db)

    result = await db.execute(
        select(CropCalendarActivity)
        .join(CropCalendar, CropCalendarActivity.calendar_id == CropCalendar.id)
        .where(CropCalendarActivity.id == activity_id, CropCalendar.oilseed_id == oilseed.id)
    )
    activity = result.scalar_one_or_none()
    if activity is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found")

    activity.completed_at = datetime.now(timezone.utc) if body.completed else None
    await db.commit()

    found = await _get_calendar_with_activities(oilseed.id, db)
    assert found is not None
    calendar, activities = found
    return crop_calendar_service.build_calendar_read(calendar, oilseed, activities)


@router.get("/{oilseed_id}/price", response_model=list[PriceRead])
async def get_oilseed_price(
    land_id: int,
    oilseed_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[CommodityPrice]:
    await get_owned_land(land_id, current_user.id, db)
    oilseed = await _get_owned_oilseed(land_id, oilseed_id, db)
    return await price_sync_service.get_prices_for_crop(db, oilseed.crop)
