from datetime import date, datetime

from pydantic import BaseModel, ConfigDict

from app.models.enums import ActivityCategory, ActivityPriority, ActivityStatus, OilseedCrop


class GrowthStageInfo(BaseModel):
    stage: str
    name: str
    start_day: int
    end_day: int


class ActivityRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    activity_key: str
    stage: str
    title: str
    category: ActivityCategory
    priority: ActivityPriority
    description: str
    guidance: str
    start_date: date
    end_date: date
    completed_at: datetime | None
    status: ActivityStatus


class CalendarRead(BaseModel):
    id: int
    oilseed_id: int
    crop: OilseedCrop
    sowing_date: date
    crop_age_days: int
    current_stage: GrowthStageInfo | None
    activities: list[ActivityRead]
    created_at: datetime


class ActivityCompleteRequest(BaseModel):
    completed: bool
