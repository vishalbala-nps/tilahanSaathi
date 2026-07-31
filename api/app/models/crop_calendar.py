from datetime import date, datetime

from sqlalchemy import Date, DateTime, Enum, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.enums import ActivityCategory, ActivityPriority


class CropCalendar(Base):
    __tablename__ = "crop_calendars"

    id: Mapped[int] = mapped_column(primary_key=True)
    oilseed_id: Mapped[int] = mapped_column(ForeignKey("oilseeds.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class CropCalendarActivity(Base):
    __tablename__ = "crop_calendar_activities"

    id: Mapped[int] = mapped_column(primary_key=True)
    calendar_id: Mapped[int] = mapped_column(ForeignKey("crop_calendars.id"), index=True)
    activity_key: Mapped[str] = mapped_column(String(100))  # stable id from the template, e.g. "weed_management_check"
    stage: Mapped[str] = mapped_column(String(100))  # growth stage this activity falls in, e.g. "flowering"
    title: Mapped[str] = mapped_column(String(255))
    category: Mapped[ActivityCategory] = mapped_column(Enum(ActivityCategory, name="activity_category"))
    priority: Mapped[ActivityPriority] = mapped_column(Enum(ActivityPriority, name="activity_priority"))
    description: Mapped[str] = mapped_column(String(500))
    guidance: Mapped[str] = mapped_column(String(500))  # personalized by the LLM at generation time
    start_date: Mapped[date] = mapped_column(Date)
    end_date: Mapped[date] = mapped_column(Date)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
