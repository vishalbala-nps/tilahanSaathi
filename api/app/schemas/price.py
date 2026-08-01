from datetime import date

from pydantic import BaseModel, ConfigDict


class PriceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    commodity_name: str
    commodity_group: str
    reported_date: date
    price_per_quintal: float
    arrival_metric_tonnes: float | None
    msp_price: float | None
    trend: str | None
