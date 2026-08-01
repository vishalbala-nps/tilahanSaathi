import asyncio
from pathlib import Path

import joblib

from app.models.enums import OilseedCrop

_MODEL_PATH = Path(__file__).resolve().parent.parent.parent / "models" / "oilseed_model.pkl"
_model = joblib.load(_MODEL_PATH)


def _predict_sync(
    n: int, p: int, k: int, temperature: float, humidity: float, ph: float, rainfall: float
) -> tuple[OilseedCrop, float]:
    [proba] = _model.predict_proba([[n, p, k, temperature, humidity, ph, rainfall]])
    best_index = proba.argmax()
    crop = OilseedCrop(str(_model.classes_[best_index]))
    confidence = float(proba[best_index])  # 0.0-1.0, the model's probability for this class
    return crop, confidence


async def predict_crop(
    *,
    nitrogen: int,
    phosphorus: int,
    potassium: int,
    temperature: float,
    humidity: float,
    ph: float,
    rainfall: float,
) -> tuple[OilseedCrop, float]:
    return await asyncio.to_thread(
        _predict_sync, nitrogen, phosphorus, potassium, temperature, humidity, ph, rainfall
    )
