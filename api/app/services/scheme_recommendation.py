from fastapi import HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import SchemeRelevance
from app.models.land import Land
from app.models.oilseed import Oilseed
from app.models.scheme import GovernmentSchemeInfo
from app.schemas.scheme import SchemeRecommendationResponse, SchemeSuggestion
from app.services.llm_client import LLMCallError, get_structured_completion

DISCLAIMER = (
    "This is AI-generated guidance based on the farm details you've provided and "
    "general scheme information — it is not a confirmation of eligibility or "
    "enrollment. Scheme rules, subsidy amounts, and exclusions can change and "
    "depend on details we don't collect (income, social category, exact state "
    "notifications). Confirm eligibility with your local agriculture office or "
    "the official scheme portal before applying."
)

_CENTRAL_STATE_VALUE = "central"


def _select_candidate_schemes(
    all_schemes: list[GovernmentSchemeInfo], lands: list[Land]
) -> list[GovernmentSchemeInfo]:
    farm_locations = [land.farm_location.lower() for land in lands]
    candidates = []
    for scheme in all_schemes:
        state = scheme.state.lower()
        if state == _CENTRAL_STATE_VALUE:
            candidates.append(scheme)
        elif any(state in farm_location for farm_location in farm_locations):
            candidates.append(scheme)
    return candidates


def _render_knowledge_base(schemes: list[GovernmentSchemeInfo]) -> str:
    lines = []
    for scheme in schemes:
        lines.append(
            f"- {scheme.slug} ({scheme.name}): {scheme.description} "
            f"Eligibility: {scheme.eligibility_summary}"
        )
    return "\n".join(lines)


def _build_system_prompt(schemes: list[GovernmentSchemeInfo]) -> str:
    return f"""You are an assistant for Tilahan Saathi, an app that helps oilseed \
farmers in India discover government schemes they may benefit from.

Reason ONLY from the scheme knowledge given below — do not rely on any other knowledge \
you may have about these schemes. This knowledge is the sole source of truth for this task.

Government scheme knowledge base:
{_render_knowledge_base(schemes)}

Given a farmer's profile (total landholding, each land's soil type, water availability, \
and planting season, and the oilseed crops they currently grow), evaluate EVERY scheme \
in the knowledge base above exactly once. For each scheme, decide:
- status: "relevant" ONLY if the farmer's profile clearly and confidently matches the \
scheme's eligibility criteria as given; "not_relevant" if it clearly does not match; \
"insufficient_data" if the scheme's eligibility depends on information not in the \
farmer's profile (e.g. income, social category, exact state-level notification) and you \
cannot confidently decide either way. Be strict — only use "relevant" when you are sure.
- reason: a short, specific explanation grounded in the farmer's actual profile and the \
scheme's eligibility summary above — never invent eligibility criteria not stated above.

Do not guess at exclusions you cannot verify (income, social category, government \
employment, exact state notifications) — mark those as "insufficient_data" rather than \
assuming the farmer qualifies or doesn't.
"""


def _build_farmer_profile_prompt(lands: list[Land], oilseeds: list[Oilseed]) -> str:
    total_area = sum(land.area_acres for land in lands)
    land_lines = "\n".join(
        f"  - {land.name}: soil type = {land.soil_type.value}, water availability = "
        f"{land.water_availability.value}, planting season = {land.planting_season.value}"
        for land in lands
    )
    crops_grown = sorted({oilseed.crop.value for oilseed in oilseeds})
    crops_line = ", ".join(crops_grown) if crops_grown else "none recorded yet"

    return (
        f"Number of lands: {len(lands)}\n"
        f"Total land area: {total_area} acres\n"
        f"Lands:\n{land_lines}\n"
        f"Oilseed crops currently grown: {crops_line}\n\n"
        "Evaluate every scheme in the knowledge base for this farmer."
    )


class SchemeEvaluation(BaseModel):
    scheme: str
    status: SchemeRelevance
    reason: str = Field(..., max_length=400)


class LLMSchemeEvaluationOutput(BaseModel):
    evaluations: list[SchemeEvaluation]


async def _generate_evaluations(
    system_prompt: str, user_prompt: str, expected_schemes: set[str]
) -> dict[str, SchemeEvaluation]:
    async def _attempt(prompt: str) -> dict[str, SchemeEvaluation]:
        result = await get_structured_completion(
            system_prompt=system_prompt,
            user_prompt=prompt,
            response_schema=LLMSchemeEvaluationOutput,
        )
        got_schemes = {e.scheme for e in result.evaluations}
        if got_schemes != expected_schemes:
            raise LLMCallError(f"Expected schemes {expected_schemes}, got {got_schemes}")
        return {e.scheme: e for e in result.evaluations}

    try:
        return await _attempt(user_prompt)
    except LLMCallError:
        try:
            return await _attempt(
                user_prompt
                + "\n\nIMPORTANT: You MUST evaluate every scheme in the knowledge base "
                "exactly once, using EXACTLY those scheme identifiers — no more, no "
                "fewer, no renaming."
            )
        except LLMCallError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Unable to generate scheme suggestions right now. Please try again shortly.",
            ) from exc


def _to_suggestion(scheme: GovernmentSchemeInfo, evaluation: SchemeEvaluation) -> SchemeSuggestion:
    return SchemeSuggestion(
        scheme=scheme.slug,
        name=scheme.name,
        description=scheme.description,
        key_benefit=scheme.key_benefit,
        url=scheme.url,
        reason=evaluation.reason,
    )


async def generate_scheme_recommendations(
    lands: list[Land], oilseeds: list[Oilseed], db: AsyncSession
) -> SchemeRecommendationResponse:
    result = await db.execute(select(GovernmentSchemeInfo).where(GovernmentSchemeInfo.is_active.is_(True)))
    all_schemes = list(result.scalars().all())
    candidates = _select_candidate_schemes(all_schemes, lands)

    total_land_area_acres = sum(land.area_acres for land in lands)

    if not candidates:
        return SchemeRecommendationResponse(
            total_land_area_acres=total_land_area_acres,
            suggestions=[],
            possibly_relevant=[],
            disclaimer=DISCLAIMER,
        )

    system_prompt = _build_system_prompt(candidates)
    user_prompt = _build_farmer_profile_prompt(lands, oilseeds)
    expected_schemes = {scheme.slug for scheme in candidates}
    evaluations = await _generate_evaluations(system_prompt, user_prompt, expected_schemes)

    suggestions = []
    possibly_relevant = []
    for scheme in candidates:
        evaluation = evaluations[scheme.slug]
        if evaluation.status == SchemeRelevance.RELEVANT:
            suggestions.append(_to_suggestion(scheme, evaluation))
        elif evaluation.status == SchemeRelevance.INSUFFICIENT_DATA:
            possibly_relevant.append(_to_suggestion(scheme, evaluation))
        # not_relevant schemes are dropped entirely

    return SchemeRecommendationResponse(
        total_land_area_acres=total_land_area_acres,
        suggestions=suggestions,
        possibly_relevant=possibly_relevant,
        disclaimer=DISCLAIMER,
    )
