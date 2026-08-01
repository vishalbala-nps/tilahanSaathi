import httpx

_GEOCODING_API_URL = "https://geocoding-api.open-meteo.com/v1/search"


async def _search(query: str, client: httpx.AsyncClient) -> list[dict]:
    response = await client.get(
        _GEOCODING_API_URL,
        params={"name": query, "count": 10, "language": "en", "format": "json", "country": "IN"},
    )
    response.raise_for_status()
    return response.json().get("results") or []


async def resolve_coordinates(farm_location: str) -> tuple[float, float] | None:
    """Best-effort geocoding of a free-text farm location to (latitude, longitude).

    farm_location is farmer-entered free text, not a structured address.
    Open-Meteo's search only reliably matches on a single place name — a full
    "village, district, state" string (or even "village, district") returns
    zero results, confirmed by testing live. So try the full string first,
    then fall back to just its first comma-separated segment (typically the
    actual village/town name, and the most specific/reliable part).

    Once a query returns candidates, prefer one whose state/district is
    mentioned in the original text (same substring-matching approach used for
    government scheme state matching); otherwise fall back to the most
    populous same-named place. Returns None if nothing matches at all.
    """
    first_segment = farm_location.split(",", 1)[0].strip()
    queries = [farm_location] if first_segment == farm_location else [farm_location, first_segment]

    async with httpx.AsyncClient(timeout=10) as client:
        for query in queries:
            results = await _search(query, client)
            if results:
                break
        else:
            return None

    location_lower = farm_location.lower()
    for candidate in results:
        state = (candidate.get("admin1") or "").lower()
        district = (candidate.get("admin2") or "").lower()
        if (state and state in location_lower) or (district and district in location_lower):
            return candidate["latitude"], candidate["longitude"]

    best = max(results, key=lambda candidate: candidate.get("population") or 0)
    return best["latitude"], best["longitude"]
