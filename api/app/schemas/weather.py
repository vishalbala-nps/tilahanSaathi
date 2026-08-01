from pydantic import BaseModel


class WeatherRead(BaseModel):
    temperature_celsius: float
    humidity_percent: float
    current_rainfall_mm: float  # sum over the last 15 minutes, not a daily total
    rainfall_today_mm: float  # today's full-day precipitation total
