from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_owned_land
from app.db.session import get_db
from app.models.land import Land
from app.models.user import User
from app.schemas.land import LandCreate, LandRead
from app.schemas.recommendation import CropRecommendationResponse, SoilNutrientRequest
from app.schemas.weather import WeatherRead
from app.services import crop_recommendation as crop_recommendation_service
from app.services import geocoding as geocoding_service
from app.services import weather as weather_service
from app.services.weather import WeatherFetchError

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
    body: SoilNutrientRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CropRecommendationResponse:
    land = await get_owned_land(land_id, current_user.id, db)
    return await crop_recommendation_service.generate_recommendation(land, body, db)


@router.get("/{land_id}/weather", response_model=WeatherRead)
async def get_land_weather(
    land_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> WeatherRead:
    land = await get_owned_land(land_id, current_user.id, db)

    if land.latitude is None or land.longitude is None:
        coordinates = await geocoding_service.resolve_coordinates(land.farm_location)
        if coordinates is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Could not resolve this land's location for a weather lookup",
            )
        land.latitude, land.longitude = coordinates
        await db.commit()
        await db.refresh(land)

    try:
        weather = await weather_service.get_current_weather(land.latitude, land.longitude)
    except WeatherFetchError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY, detail="Weather service unavailable"
        ) from exc

    return WeatherRead(
        temperature_celsius=weather["temperature_2m"],
        humidity_percent=weather["relative_humidity_2m"],
        current_rainfall_mm=weather["current_precipitation"],
        rainfall_today_mm=weather["today_precipitation_sum"],
    )
