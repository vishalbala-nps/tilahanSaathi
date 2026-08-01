from typing import Literal

from pydantic import BaseModel, Field

from app.models.enums import EvaluationFactor, OilseedCrop


class SoilNutrientRequest(BaseModel):
    nitrogen: int = Field(..., ge=0, description="Soil nitrogen (N) from a soil test")
    phosphorus: int = Field(..., ge=0, description="Soil phosphorus (P) from a soil test")
    potassium: int = Field(..., ge=0, description="Soil potassium (K) from a soil test")
    ph: float = Field(..., ge=0, le=14, description="Soil pH from a soil test")


class PositiveFactor(BaseModel):
    factor: EvaluationFactor
    assessment: Literal["excellent_match", "good_match", "acceptable_match"]
    reason: str = Field(..., max_length=300)


class CropRecommendationResponse(BaseModel):
    recommended_crop: OilseedCrop
    confidence_percent: float = Field(..., ge=0, le=100, description="The prediction model's confidence in recommended_crop")
    reasoning: str = Field(..., max_length=600)
    positive_factors: list[PositiveFactor] = Field(..., min_length=1, max_length=4)
