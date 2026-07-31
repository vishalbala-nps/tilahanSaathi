from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class GovernmentSchemeInfo(Base):
    __tablename__ = "government_schemes"

    id: Mapped[int] = mapped_column(primary_key=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    description: Mapped[str] = mapped_column(String(1500))
    eligibility_summary: Mapped[str] = mapped_column(String(1500))
    key_benefit: Mapped[str] = mapped_column(String(500))
    url: Mapped[str | None] = mapped_column(String(500), nullable=True)  # primary official scheme URL
    state: Mapped[str] = mapped_column(String(100), index=True)  # "central" or e.g. "Maharashtra"
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
