from pydantic import BaseModel


class WeatherRead(BaseModel):
    temperature_celsius: float
    humidity_percent: float
    rainfall_today_mm: float  # today's full-day precipitation total
