import logging
from datetime import date, datetime, timezone

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.upsert import upsert
from app.models.price import CommodityPrice, PriceSyncState

logger = logging.getLogger(__name__)

# (price field key, arrival field key) pairs in each Agmarknet record.
_PRICE_ARRIVAL_FIELD_PAIRS = [
    ("as_on_price", "as_on_arrival"),
    ("one_day_ago_price", "one_day_ago_arrival"),
    ("two_day_ago_price", "two_day_ago_arrival"),
]

_PRICE_GROUP_KEY = "price_group"

# Defensive cap — stop paginating even if Agmarknet's pagination metadata is
# ever wrong/buggy and never reports a null next_page.
_MAX_PAGES = 50

# nginx in front of the Agmarknet API rejects requests with no recognizable
# browser User-Agent (bare 403, before the request reaches the app).
_REQUEST_HEADERS = {
    "Content-Type": "application/json",
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0 Safari/537.36"
    ),
}

# Unfiltered dashboard — returns every commodity Agmarknet tracks (cereals,
# pulses, vegetables, oilseeds, etc.), not just oilseeds. Paginated, 10
# commodities per page — see _fetch_all_pages.
_REQUEST_BODY = {"dashboard": "marketwise_price_arrival"}


def _parse_price_group_dates(columns: list[dict]) -> dict[str, date]:
    """Maps each price field key (e.g. "as_on_price") to the real calendar date
    Agmarknet says it belongs to, read from that column's title (e.g. "30 Jul, 2026").
    Deliberately not computed as reported_date - 1/-2, since a reporting gap
    (e.g. a mandi holiday) could make that offset wrong."""
    for column in columns:
        if column.get("key") == _PRICE_GROUP_KEY:
            return {
                sub_column["key"]: datetime.strptime(sub_column["title"], "%d %b, %Y").date()
                for sub_column in column["columns"]
            }
    raise ValueError("price_group not found in Agmarknet response columns")


async def _fetch_all_pages() -> tuple[list[dict], dict] | None:
    """Walks every page of the unfiltered dashboard, returning
    (all records, date_by_field) or None on any failure. date_by_field is
    parsed from the first page only — confirmed it doesn't vary per page."""
    all_records: list[dict] = []
    date_by_field: dict[str, date] | None = None

    async with httpx.AsyncClient(timeout=settings.agmarknet_timeout_seconds) as client:
        page = 1
        while page <= _MAX_PAGES:
            response = await client.post(
                settings.agmarknet_api_url,
                headers=_REQUEST_HEADERS,
                json={**_REQUEST_BODY, "page": page},
            )
            response.raise_for_status()
            payload = response.json()
            data = payload["data"]

            if date_by_field is None:
                date_by_field = _parse_price_group_dates(data["columns"])

            all_records.extend(data["records"])

            if not payload["pagination"].get("next_page"):
                break
            page += 1

    if date_by_field is None:
        raise ValueError("Agmarknet response never included price_group columns")

    return all_records, date_by_field


async def _upsert_price(
    db: AsyncSession,
    commodity_name: str,
    commodity_group: str,
    reported_date: date,
    price: float,
    arrival: float | None,
    msp: float | None,
    trend: str | None,
) -> None:
    # Atomic insert-or-update on (commodity_name, reported_date) — avoids the
    # select-then-insert-or-update race where two concurrent syncs can both
    # see "no existing row" and both try to INSERT, colliding on the unique
    # constraint.
    stmt = upsert(CommodityPrice).values(
        commodity_name=commodity_name,
        commodity_group=commodity_group,
        reported_date=reported_date,
        price_per_quintal=price,
        arrival_metric_tonnes=arrival,
        msp_price=msp,
        trend=trend,
    )
    stmt = stmt.on_conflict_do_update(
        index_elements=["commodity_name", "reported_date"],
        set_={
            "commodity_group": stmt.excluded.commodity_group,
            "price_per_quintal": stmt.excluded.price_per_quintal,
            "arrival_metric_tonnes": stmt.excluded.arrival_metric_tonnes,
            "msp_price": stmt.excluded.msp_price,
            "trend": stmt.excluded.trend,
        },
    )
    await db.execute(stmt)


def _parse_float(value: object) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


async def sync_latest_prices(db: AsyncSession) -> bool:
    """Fetches the latest data from Agmarknet (all pages, all commodities)
    and upserts it. Never raises — any failure (network, bad response,
    unexpected shape) is logged and returns False so callers can fall back
    to serving cached data."""
    try:
        fetched = await _fetch_all_pages()
        if fetched is None:
            return False
        records, date_by_field = fetched

        for record in records:
            commodity_name = str(record.get("cmdt_name", "")).strip()
            commodity_group = str(record.get("cmdt_grp_name", "")).strip()
            if not commodity_name:
                continue

            msp = _parse_float(record.get("msp_price"))
            trend = record.get("trend")

            for price_key, arrival_key in _PRICE_ARRIVAL_FIELD_PAIRS:
                price = _parse_float(record.get(price_key))
                if price is None:
                    continue
                arrival = _parse_float(record.get(arrival_key))
                reported_date = date_by_field[price_key]
                await _upsert_price(
                    db, commodity_name, commodity_group, reported_date, price, arrival, msp, trend
                )

        return True
    except Exception:
        logger.warning("Agmarknet price sync failed", exc_info=True)
        return False


async def ensure_fresh_prices(db: AsyncSession) -> None:
    """Syncs from Agmarknet at most once per calendar day on success. A failed
    sync is not throttled — the very next call will try again. Never raises;
    /price must always be able to serve whatever's cached."""
    result = await db.execute(select(PriceSyncState).where(PriceSyncState.id == 1))
    state = result.scalar_one_or_none()

    if state is not None and state.last_successful_sync_at.date() >= date.today():
        return

    success = await sync_latest_prices(db)
    if not success:
        await db.rollback()
        return

    # Same atomic upsert reasoning as _upsert_price — avoids two concurrent
    # first-ever syncs both trying to INSERT id=1 and colliding.
    now = datetime.now(timezone.utc)
    stmt = upsert(PriceSyncState).values(id=1, last_successful_sync_at=now)
    stmt = stmt.on_conflict_do_update(
        index_elements=["id"],
        set_={"last_successful_sync_at": stmt.excluded.last_successful_sync_at},
    )
    await db.execute(stmt)
    await db.commit()
