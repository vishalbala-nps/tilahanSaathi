import httpx

_FORECAST_API_URL = "https://api.open-meteo.com/v1/forecast"


class WeatherFetchError(Exception):
    """Raised when Open-Meteo's forecast API can't be reached or returns an
    unexpected shape."""


async def get_current_weather(latitude: float, longitude: float) -> dict:
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(
                _FORECAST_API_URL,
                params={
                    "latitude": latitude,
                    "longitude": longitude,
                    # "current" precipitation would be a backward-looking sum over
                    # just the last 15 minutes, not a meaningful daily total — use
                    # "daily" precipitation_sum (today only, via forecast_days=1)
                    # instead, which actually answers "how much has it rained today".
                    "current": "temperature_2m,relative_humidity_2m",
                    "daily": "precipitation_sum",
                    "timezone": "auto",
                    "forecast_days": 1,
                },
            )
            response.raise_for_status()
            payload = response.json()
            return {
                "temperature_2m": payload["current"]["temperature_2m"],
                "relative_humidity_2m": payload["current"]["relative_humidity_2m"],
                "today_precipitation_sum": payload["daily"]["precipitation_sum"][0],
            }
    except (httpx.HTTPError, KeyError, IndexError) as exc:
        raise WeatherFetchError(str(exc)) from exc
