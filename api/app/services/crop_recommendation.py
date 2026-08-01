from datetime import date

from fastapi import HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import OilseedCrop, PlantingSeason
from app.models.land import Land
from app.schemas.recommendation import CropRecommendationResponse, PositiveFactor, SoilNutrientRequest
from app.services import geocoding as geocoding_service
from app.services import oilseed_predictor
from app.services import weather as weather_service
from app.services.llm_client import LLMCallError, get_structured_completion
from app.services.weather import WeatherFetchError

# ---------------------------------------------------------------------------
# FIRST-DRAFT AGRONOMIC KNOWLEDGE — NOT REVIEWED BY A DOMAIN EXPERT.
# Synthesized for engineering purposes only. An agronomist familiar with
# Indian oilseed cultivation must review and correct this before farmers
# rely on these recommendations in production.
# ---------------------------------------------------------------------------
OILSEED_AGRONOMY_KNOWLEDGE: dict[OilseedCrop, dict] = {
    OilseedCrop.GROUNDNUT: {
        "suitable_soil": ["sandy", "loamy", "red_soil"],
        "suitable_water": ["rain_fed", "limited", "reliable"],
        "suitable_season": ["kharif", "summer"],
        "notes": "Prefers well-drained light soils; waterlogging harms pod development. "
        "Good rotation after cereals (rice/maize); avoid repeating after itself or other "
        "legumes due to soil-borne disease buildup.",
    },
    OilseedCrop.SOYBEAN: {
        "suitable_soil": ["loamy", "black_soil", "clay"],
        "suitable_water": ["rain_fed", "reliable"],
        "suitable_season": ["kharif"],
        "notes": "Thrives in black cotton soils with good moisture retention. Excellent "
        "nitrogen-fixing rotation partner before wheat (rabi) in soybean-wheat systems.",
    },
    OilseedCrop.SESAME: {
        "suitable_soil": ["sandy", "loamy", "red_soil", "black_soil"],
        "suitable_water": ["limited", "rain_fed"],
        "suitable_season": ["kharif", "summer"],
        "notes": "Highly drought-tolerant, poor performer in waterlogged or heavy clay "
        "conditions. Good short-duration catch crop between main seasons.",
    },
    OilseedCrop.MUSTARD: {
        "suitable_soil": ["loamy", "clay", "black_soil"],
        "suitable_water": ["limited", "reliable"],
        "suitable_season": ["rabi"],
        "notes": "Classic rabi oilseed, often grown after kharif rice/cotton harvest using "
        "residual soil moisture. Tolerates mild water stress once established.",
    },
    OilseedCrop.SUNFLOWER: {
        "suitable_soil": ["loamy", "black_soil", "red_soil", "mixed"],
        "suitable_water": ["reliable", "limited"],
        "suitable_season": ["kharif", "rabi", "summer"],
        "notes": "Adaptable across all three seasons if irrigation is available; deep "
        "taproot gives moderate drought tolerance once established.",
    },
    OilseedCrop.CASTOR: {
        "suitable_soil": ["sandy", "red_soil", "mixed", "black_soil"],
        "suitable_water": ["rain_fed", "limited"],
        "suitable_season": ["kharif"],
        "notes": "Very drought-hardy, tolerates poor/marginal soils where other oilseeds "
        "struggle; long duration crop, less suited to fast rotations.",
    },
    OilseedCrop.SAFFLOWER: {
        "suitable_soil": ["black_soil", "clay", "loamy"],
        "suitable_water": ["limited", "rain_fed"],
        "suitable_season": ["rabi"],
        "notes": "Deep-rooted, good residual-moisture rabi crop on heavy soils after a "
        "kharif cereal; poor tolerance of waterlogging.",
    },
    OilseedCrop.LINSEED: {
        "suitable_soil": ["loamy", "clay", "black_soil"],
        "suitable_water": ["reliable", "limited"],
        "suitable_season": ["rabi"],
        "notes": "Cool-season rabi crop needing reasonable moisture; commonly relay-cropped "
        "or grown after rice in rice-linseed systems.",
    },
    OilseedCrop.NIGER: {
        "suitable_soil": ["red_soil", "sandy", "mixed"],
        "suitable_water": ["rain_fed", "limited"],
        "suitable_season": ["kharif"],
        "notes": "Suited to poor, marginal upland soils with minimal input; common "
        "tribal-belt/hill-region crop, tolerates low fertility.",
    },
}


# First-draft month -> season mapping (sowing month, not full season span). Actual
# kharif/rabi/summer windows vary by region in India — an agronomist should confirm
# these boundaries before relying on this for production guidance.
_MONTH_TO_SEASON: dict[int, PlantingSeason] = {
    1: PlantingSeason.RABI,
    2: PlantingSeason.RABI,
    3: PlantingSeason.SUMMER,
    4: PlantingSeason.SUMMER,
    5: PlantingSeason.SUMMER,
    6: PlantingSeason.KHARIF,
    7: PlantingSeason.KHARIF,
    8: PlantingSeason.KHARIF,
    9: PlantingSeason.KHARIF,
    10: PlantingSeason.RABI,
    11: PlantingSeason.RABI,
    12: PlantingSeason.RABI,
}


def derive_season_from_sowing_date(sowing_date: date) -> PlantingSeason:
    return _MONTH_TO_SEASON[sowing_date.month]


def validate_crop_season(crop: OilseedCrop, sowing_date: date) -> None:
    season = derive_season_from_sowing_date(sowing_date)
    suitable_seasons = OILSEED_AGRONOMY_KNOWLEDGE[crop]["suitable_season"]
    if season.value not in suitable_seasons:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                f"{crop.value} is not typically sown in {season.value} season "
                f"(sowing month: {sowing_date.strftime('%B')}). It is suited to: "
                f"{', '.join(suitable_seasons)}."
            ),
        )


# The crop itself is now decided by app.services.oilseed_predictor (an ML model) —
# the LLM's job is only to explain that pick, not choose among candidates. Not
# exported: recommended_crop is already known before this call, so the LLM isn't
# asked to restate it (letting it do so risks it "disagreeing" with the model).
class _RecommendationExplanation(BaseModel):
    reasoning: str = Field(..., max_length=600)
    positive_factors: list[PositiveFactor] = Field(..., min_length=1, max_length=4)


def _build_explanation_system_prompt(crop: OilseedCrop) -> str:
    info = OILSEED_AGRONOMY_KNOWLEDGE[crop]
    return f"""You are an agronomy assistant for Tilahan Saathi, an app that helps \
oilseed farmers in India choose what to grow.

A machine learning model has already determined that the best oilseed crop for this \
farm is {crop.value}, based on the farm's soil nutrients (N, P, K), soil pH, and current \
weather (temperature, humidity, rainfall). Your job is NOT to pick a crop — it is already \
decided. Your job is to explain, in terms a farmer can understand, why {crop.value} is a \
good fit for this specific farm.

Reason ONLY from the known agronomic facts below — do not rely on any other knowledge you \
may have about this crop. This knowledge is the sole source of truth for this task.

Known agronomic facts about {crop.value}:
- Suitable soil types: {', '.join(info['suitable_soil'])}
- Suitable water availability: {', '.join(info['suitable_water'])}
- Suitable planting season: {', '.join(info['suitable_season'])}
- Notes: {info['notes']}

Given this farm's specific soil type, water availability, planting season, last-grown crop, \
soil nutrient levels (N/P/K), pH, and current weather, write a short overall reasoning \
summary and list 1-4 specific positive factors supporting why {crop.value} suits this farm \
— each grounded in the facts above and/or this farm's specific data (e.g. soil match, water \
availability match, season match, favorable N/P/K or pH range, favorable current weather, \
rotation benefit from the last-grown crop).
"""


def _build_explanation_user_prompt(
    land: Land, nutrients: SoilNutrientRequest, temperature: float, humidity: float, rainfall: float
) -> str:
    return (
        f"Farm location: {land.farm_location}\n"
        f"Land area: {land.area_acres} acres\n"
        f"Soil type: {land.soil_type.value}\n"
        f"Water availability: {land.water_availability.value}\n"
        f"Planting season: {land.planting_season.value}\n"
        f"Last crop grown on this land: {land.last_grown_crop}\n"
        f"Soil nitrogen (N): {nutrients.nitrogen}\n"
        f"Soil phosphorus (P): {nutrients.phosphorus}\n"
        f"Soil potassium (K): {nutrients.potassium}\n"
        f"Soil pH: {nutrients.ph}\n"
        f"Current temperature: {temperature}°C\n"
        f"Current humidity: {humidity}%\n"
        f"Today's rainfall so far: {rainfall}mm\n\n"
        "Explain why this recommended crop suits this farm."
    )


async def generate_recommendation(
    land: Land, nutrients: SoilNutrientRequest, db: AsyncSession
) -> CropRecommendationResponse:
    if land.latitude is None or land.longitude is None:
        coordinates = await geocoding_service.resolve_coordinates(land.farm_location)
        if coordinates is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Could not resolve this land's location for a weather lookup",
            )
        land.latitude, land.longitude = coordinates
        await db.commit()
        await db.refresh(land)

    try:
        weather = await weather_service.get_current_weather(land.latitude, land.longitude)
    except WeatherFetchError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY, detail="Weather service unavailable"
        ) from exc

    temperature = weather["temperature_2m"]
    humidity = weather["relative_humidity_2m"]
    rainfall = weather["today_precipitation_sum"]

    print("N: ",nutrients.nitrogen)
    print("P: ",nutrients.phosphorus)
    print("K: ",nutrients.potassium)
    print("Temp: ",temperature)
    print("Humidity: ",humidity)
    print("pH: ",nutrients.ph)
    print("Raianfall: ",rainfall*100)

    crop = await oilseed_predictor.predict_crop(
        nitrogen=nutrients.nitrogen,
        phosphorus=nutrients.phosphorus,
        potassium=nutrients.potassium,
        temperature=temperature,
        humidity=humidity,
        ph=nutrients.ph,
        rainfall=rainfall*100,
    )
    print("Predicted Crop: ",crop)
    system_prompt = _build_explanation_system_prompt(crop)
    user_prompt = _build_explanation_user_prompt(land, nutrients, temperature, humidity, rainfall)

    try:
        explanation = await get_structured_completion(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            response_schema=_RecommendationExplanation,
        )
    except LLMCallError:
        try:
            explanation = await get_structured_completion(
                system_prompt=system_prompt,
                user_prompt=user_prompt
                + "\n\nIMPORTANT: You MUST respond with valid JSON matching the exact "
                "schema provided. Double-check every field before responding.",
                response_schema=_RecommendationExplanation,
            )
        except LLMCallError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Unable to generate a crop recommendation right now. Please try again shortly.",
            ) from exc

    return CropRecommendationResponse(
        recommended_crop=crop,
        reasoning=explanation.reasoning,
        positive_factors=explanation.positive_factors,
    )
