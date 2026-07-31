from datetime import date, datetime

from sqlalchemy import Date, DateTime, Enum, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.enums import OilseedCrop


class Oilseed(Base):
    __tablename__ = "oilseeds"

    id: Mapped[int] = mapped_column(primary_key=True)
    land_id: Mapped[int] = mapped_column(ForeignKey("lands.id"), index=True)
    crop: Mapped[OilseedCrop] = mapped_column(Enum(OilseedCrop, name="oilseed_planting_crop"))
    sowing_date: Mapped[date] = mapped_column(Date)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
