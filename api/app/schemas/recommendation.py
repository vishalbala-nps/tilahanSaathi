from typing import Literal

from pydantic import BaseModel, Field

from app.models.enums import ConfidenceLevel, EvaluationFactor, OilseedCrop


class PositiveFactor(BaseModel):
    factor: EvaluationFactor
    assessment: Literal["excellent_match", "good_match", "acceptable_match"]
    reason: str = Field(..., max_length=300)


class AlternativeCrop(BaseModel):
    crop: OilseedCrop
    reason_not_chosen: str = Field(..., max_length=300)


class CropRecommendationResponse(BaseModel):
    recommended_crop: OilseedCrop
    confidence: ConfidenceLevel
    reasoning: str = Field(..., max_length=600)
    positive_factors: list[PositiveFactor] = Field(..., min_length=1, max_length=4)
    alternatives: list[AlternativeCrop] = Field(..., min_length=1, max_length=2)
