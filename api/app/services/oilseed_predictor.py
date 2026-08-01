import asyncio
from pathlib import Path

import joblib

from app.models.enums import OilseedCrop

_MODEL_PATH = Path(__file__).resolve().parent.parent.parent / "models" / "oilseed_model.pkl"
_model = joblib.load(_MODEL_PATH)


def _predict_sync(
    n: int, p: int, k: int, temperature: float, humidity: float, ph: float, rainfall: float
) -> OilseedCrop:
    [label] = _model.predict([[n, p, k, temperature, humidity, ph, rainfall]])
    return OilseedCrop(str(label))


async def predict_crop(
    *,
    nitrogen: int,
    phosphorus: int,
    potassium: int,
    temperature: float,
    humidity: float,
    ph: float,
    rainfall: float,
) -> OilseedCrop:
    return await asyncio.to_thread(
        _predict_sync, nitrogen, phosphorus, potassium, temperature, humidity, ph, rainfall
    )
