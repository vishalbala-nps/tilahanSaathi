from sqlalchemy import Insert, Table
from sqlalchemy.engine import make_url
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

_backend = make_url(settings.database_url).get_backend_name()

if _backend == "sqlite":
    from sqlalchemy.dialects.sqlite import insert as _dialect_insert
elif _backend == "postgresql":
    from sqlalchemy.dialects.postgresql import insert as _dialect_insert
else:
    raise RuntimeError(
        f"No upsert() support wired up for database backend '{_backend}'. "
        "Add a dialect-specific insert() import in app/db/upsert.py."
    )


def upsert(table: Table | type[DeclarativeBase]) -> Insert:
    """Dialect-aware INSERT ... ON CONFLICT DO UPDATE builder. Picks the
    sqlite/postgresql insert() automatically based on DATABASE_URL, so
    callers (and DATABASE_URL) are the only things that need to change when
    switching database backends — call sites stay the same either way.
    """
    return _dialect_insert(table)
