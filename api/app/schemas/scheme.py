from pydantic import BaseModel


class SchemeSuggestion(BaseModel):
    scheme: str
    name: str
    description: str
    key_benefit: str
    url: str | None
    reason: str


class SchemeRecommendationResponse(BaseModel):
    total_land_area_acres: float
    suggestions: list[SchemeSuggestion]
    possibly_relevant: list[SchemeSuggestion]
    disclaimer: str
