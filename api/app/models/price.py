from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class CommodityPrice(Base):
    __tablename__ = "commodity_prices"

    id: Mapped[int] = mapped_column(primary_key=True)
    commodity_name: Mapped[str] = mapped_column(String(255), index=True)  # Agmarknet cmdt_name
    commodity_group: Mapped[str] = mapped_column(String(100), index=True)  # Agmarknet cmdt_grp_name
    reported_date: Mapped[date] = mapped_column(Date, index=True)
    price_per_quintal: Mapped[float] = mapped_column(Float)
    arrival_metric_tonnes: Mapped[float | None] = mapped_column(Float, nullable=True)
    msp_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    trend: Mapped[str | None] = mapped_column(String(10), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("commodity_name", "reported_date", name="uq_commodity_price_name_date"),
    )


class PriceSyncState(Base):
    """Singleton row (id=1) tracking the last successful Agmarknet sync."""

    __tablename__ = "price_sync_state"

    id: Mapped[int] = mapped_column(primary_key=True)
    last_successful_sync_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
