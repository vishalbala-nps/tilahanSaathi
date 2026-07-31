from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.enums import PlantingSeason, SoilType, WaterAvailability


class Land(Base):
    __tablename__ = "lands"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[str] = mapped_column(String(128), ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(255))
    farm_location: Mapped[str] = mapped_column(String(255))
    area_acres: Mapped[float] = mapped_column(Float)
    soil_type: Mapped[SoilType] = mapped_column(Enum(SoilType, name="soil_type"))
    water_availability: Mapped[WaterAvailability] = mapped_column(
        Enum(WaterAvailability, name="water_availability")
    )
    last_grown_crop: Mapped[str] = mapped_column(String(100))
    planting_season: Mapped[PlantingSeason] = mapped_column(Enum(PlantingSeason, name="planting_season"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
