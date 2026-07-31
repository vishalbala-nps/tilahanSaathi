from datetime import date, datetime

from pydantic import BaseModel, ConfigDict

from app.models.enums import OilseedCrop


class OilseedCreate(BaseModel):
    crop: OilseedCrop
    sowing_date: date


class OilseedRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    land_id: int
    crop: OilseedCrop
    sowing_date: date
    created_at: datetime
