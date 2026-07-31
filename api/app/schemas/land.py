from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.enums import PlantingSeason, SoilType, WaterAvailability


class LandCreate(BaseModel):
    name: str
    farm_location: str
    area_acres: float
    soil_type: SoilType
    water_availability: WaterAvailability
    last_grown_crop: str
    planting_season: PlantingSeason


class LandRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: str
    name: str
    farm_location: str
    area_acres: float
    soil_type: SoilType
    water_availability: WaterAvailability
    last_grown_crop: str
    planting_season: PlantingSeason
    created_at: datetime
