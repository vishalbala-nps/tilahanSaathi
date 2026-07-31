from datetime import date

from fastapi import HTTPException, status

from app.models.enums import OilseedCrop, PlantingSeason
from app.models.land import Land
from app.schemas.recommendation import CropRecommendationResponse
from app.services.llm_client import LLMCallError, get_structured_completion

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


def _render_knowledge_base() -> str:
    lines = []
    for crop, info in OILSEED_AGRONOMY_KNOWLEDGE.items():
        lines.append(
            f"- {crop.value}: suitable soil = {', '.join(info['suitable_soil'])}; "
            f"suitable water availability = {', '.join(info['suitable_water'])}; "
            f"suitable season = {', '.join(info['suitable_season'])}. {info['notes']}"
        )
    return "\n".join(lines)


# Extension point for later: add a `target_language` parameter here and append
# "Respond in {target_language}." to the user prompt — reasoning fields are
# already free text, so no schema/endpoint change is needed for this.
SYSTEM_PROMPT = f"""You are an agronomy assistant for Tilahan Saathi, an app that helps \
oilseed farmers in India choose what to grow.

Reason ONLY from the agronomic knowledge given below — do not rely on any other knowledge \
you may have about these crops. This knowledge is the sole source of truth for this task.

Oilseed crop knowledge base:
{_render_knowledge_base()}

Given a specific farm's soil type, water availability, planting season, and last-grown crop, \
recommend the single best oilseed crop from the knowledge base above. Factor in the farm's \
last-grown crop for crop-rotation reasoning (e.g. avoid recommending the same crop \
consecutively unless no better fit exists; prefer rotation partners that restore soil \
fertility per the notes above).

Also identify 1-2 other crops from the knowledge base that were reasonably close \
contenders, and explain concretely why each lost out to your top pick.

For your top pick, list 1-4 specific positive factors that support it (e.g. soil match, \
water availability match, season match, rotation benefit), each grounded in the knowledge \
base and this farm's specific data.

Use confidence "high" only when soil, water availability, and season all clearly match the \
knowledge base for your recommended crop; use "low" when the input data is borderline, \
contains "unknown" values, or forces a guess.
"""


def _build_user_prompt(land: Land) -> str:
    return (
        f"Farm location: {land.farm_location}\n"
        f"Land area: {land.area_acres} acres\n"
        f"Soil type: {land.soil_type.value}\n"
        f"Water availability: {land.water_availability.value}\n"
        f"Planting season: {land.planting_season.value}\n"
        f"Last crop grown on this land: {land.last_grown_crop}\n\n"
        "Recommend the best oilseed crop for this farm."
    )


async def generate_recommendation(land: Land) -> CropRecommendationResponse:
    user_prompt = _build_user_prompt(land)
    try:
        return await get_structured_completion(
            system_prompt=SYSTEM_PROMPT,
            user_prompt=user_prompt,
            response_schema=CropRecommendationResponse,
        )
    except LLMCallError:
        try:
            return await get_structured_completion(
                system_prompt=SYSTEM_PROMPT,
                user_prompt=user_prompt
                + "\n\nIMPORTANT: You MUST respond with valid JSON matching the exact "
                "schema provided, using ONLY crop names from the knowledge base above. "
                "Double-check every field before responding.",
                response_schema=CropRecommendationResponse,
            )
        except LLMCallError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Unable to generate a crop recommendation right now. Please try again shortly.",
            ) from exc
