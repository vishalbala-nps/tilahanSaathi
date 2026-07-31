from datetime import date, timedelta

from fastapi import HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.crop_calendar import CropCalendar, CropCalendarActivity
from app.models.enums import ActivityCategory, ActivityPriority, OilseedCrop
from app.models.land import Land
from app.models.oilseed import Oilseed
from app.schemas.calendar import ActivityRead, CalendarRead, GrowthStageInfo
from app.services.llm_client import LLMCallError, get_structured_completion

# ---------------------------------------------------------------------------
# FIRST-DRAFT GROWTH-STAGE & ACTIVITY TEMPLATES — NOT REVIEWED BY A DOMAIN EXPERT.
# Synthesized for engineering purposes only. An agronomist familiar with Indian
# oilseed cultivation must review and correct all day-ranges and guidance before
# farmers rely on these calendars in production. Day offsets are relative to the
# sowing date (day 0 = sowing date).
# ---------------------------------------------------------------------------

GROWTH_STAGES: dict[OilseedCrop, list[dict]] = {
    OilseedCrop.GROUNDNUT: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 10},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 11, "end_day": 35},
        {"stage": "flowering", "name": "Flowering", "start_day": 36, "end_day": 55},
        {"stage": "pod_development", "name": "Pod Development", "start_day": 56, "end_day": 90},
        {"stage": "maturity", "name": "Maturity", "start_day": 91, "end_day": 110},
    ],
    OilseedCrop.SOYBEAN: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 8},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 9, "end_day": 30},
        {"stage": "flowering", "name": "Flowering", "start_day": 31, "end_day": 50},
        {"stage": "pod_filling", "name": "Pod Filling", "start_day": 51, "end_day": 85},
        {"stage": "maturity", "name": "Maturity", "start_day": 86, "end_day": 105},
    ],
    OilseedCrop.SESAME: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 7},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 8, "end_day": 25},
        {"stage": "flowering", "name": "Flowering", "start_day": 26, "end_day": 45},
        {"stage": "capsule_development", "name": "Capsule Development", "start_day": 46, "end_day": 75},
        {"stage": "maturity", "name": "Maturity", "start_day": 76, "end_day": 90},
    ],
    OilseedCrop.MUSTARD: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 10},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 11, "end_day": 40},
        {"stage": "flowering", "name": "Flowering", "start_day": 41, "end_day": 70},
        {"stage": "pod_development", "name": "Pod Development", "start_day": 71, "end_day": 110},
        {"stage": "maturity", "name": "Maturity", "start_day": 111, "end_day": 135},
    ],
    OilseedCrop.SUNFLOWER: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 10},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 11, "end_day": 35},
        {"stage": "flowering", "name": "Flowering", "start_day": 36, "end_day": 55},
        {"stage": "seed_filling", "name": "Seed Filling", "start_day": 56, "end_day": 85},
        {"stage": "maturity", "name": "Maturity", "start_day": 86, "end_day": 100},
    ],
    OilseedCrop.CASTOR: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 12},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 13, "end_day": 50},
        {"stage": "flowering", "name": "Flowering", "start_day": 51, "end_day": 90},
        {"stage": "capsule_development", "name": "Capsule Development", "start_day": 91, "end_day": 140},
        {"stage": "maturity", "name": "Maturity", "start_day": 141, "end_day": 170},
    ],
    OilseedCrop.SAFFLOWER: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 12},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 13, "end_day": 45},
        {"stage": "flowering", "name": "Flowering", "start_day": 46, "end_day": 80},
        {"stage": "seed_development", "name": "Seed Development", "start_day": 81, "end_day": 115},
        {"stage": "maturity", "name": "Maturity", "start_day": 116, "end_day": 140},
    ],
    OilseedCrop.LINSEED: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 10},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 11, "end_day": 40},
        {"stage": "flowering", "name": "Flowering", "start_day": 41, "end_day": 65},
        {"stage": "boll_development", "name": "Boll Development", "start_day": 66, "end_day": 100},
        {"stage": "maturity", "name": "Maturity", "start_day": 101, "end_day": 120},
    ],
    OilseedCrop.NIGER: [
        {"stage": "germination", "name": "Germination", "start_day": 0, "end_day": 8},
        {"stage": "vegetative", "name": "Vegetative", "start_day": 9, "end_day": 30},
        {"stage": "flowering", "name": "Flowering", "start_day": 31, "end_day": 55},
        {"stage": "seed_development", "name": "Seed Development", "start_day": 56, "end_day": 80},
        {"stage": "maturity", "name": "Maturity", "start_day": 81, "end_day": 95},
    ],
}

ACTIVITY_TEMPLATES: dict[OilseedCrop, list[dict]] = {
    OilseedCrop.GROUNDNUT: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 7, "end_day": 14, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.HIGH, "stage": "vegetative", "start_day": 20, "end_day": 30, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering stage", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 36, "end_day": 55, "description": "Monitor crop growth and look for signs of stress during flowering."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 40, "end_day": 80, "description": "Increase regular crop inspection for early signs of pests and diseases."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 95, "end_day": 105, "description": "Begin preparing for harvest and monitor crop maturity."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 100, "end_day": 115, "description": "This is an estimated harvest window. Confirm crop maturity in the field before harvesting."},
    ],
    OilseedCrop.SOYBEAN: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 6, "end_day": 12, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.HIGH, "stage": "vegetative", "start_day": 15, "end_day": 25, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering stage", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 31, "end_day": 50, "description": "Monitor crop growth and look for signs of stress during flowering; avoid water stress."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 35, "end_day": 75, "description": "Watch for pod borer and stem fly during pod filling."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 90, "end_day": 100, "description": "Begin preparing for harvest and monitor crop maturity."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 95, "end_day": 110, "description": "This is an estimated harvest window. Confirm crop maturity in the field before harvesting."},
    ],
    OilseedCrop.SESAME: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 5, "end_day": 10, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.HIGH, "stage": "vegetative", "start_day": 12, "end_day": 22, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering stage", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 26, "end_day": 45, "description": "Monitor crop growth and look for signs of stress during flowering."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.MEDIUM, "stage": "flowering", "start_day": 30, "end_day": 65, "description": "Watch for leaf webber and phyllody during capsule development."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 78, "end_day": 85, "description": "Begin preparing for harvest and monitor crop maturity."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 82, "end_day": 95, "description": "This is an estimated harvest window. Sesame shatters easily — confirm maturity before harvesting."},
    ],
    OilseedCrop.MUSTARD: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 7, "end_day": 15, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.HIGH, "stage": "vegetative", "start_day": 20, "end_day": 32, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "nutrient_top_dressing", "title": "Nitrogen top-dressing", "category": ActivityCategory.NUTRIENT_MANAGEMENT, "priority": ActivityPriority.MEDIUM, "stage": "vegetative", "start_day": 30, "end_day": 40, "description": "Typical window for a nitrogen top-dressing application on rabi mustard."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering stage", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 41, "end_day": 70, "description": "Monitor crop growth and look for signs of stress during flowering."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 45, "end_day": 95, "description": "Watch for aphid infestation, common on mustard during this window."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 115, "end_day": 125, "description": "Begin preparing for harvest and monitor crop maturity."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 120, "end_day": 135, "description": "This is an estimated harvest window. Confirm crop maturity in the field before harvesting."},
    ],
    OilseedCrop.SUNFLOWER: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 7, "end_day": 14, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.HIGH, "stage": "vegetative", "start_day": 18, "end_day": 28, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering and pollination", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 36, "end_day": 55, "description": "Pollination is critical for sunflower head-fill — monitor bee activity and head development."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 40, "end_day": 75, "description": "Watch for head borer and bird damage as seeds develop."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 88, "end_day": 95, "description": "Begin preparing for harvest and monitor crop maturity."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 92, "end_day": 105, "description": "This is an estimated harvest window. Confirm crop maturity in the field before harvesting."},
    ],
    OilseedCrop.CASTOR: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 8, "end_day": 18, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.HIGH, "stage": "vegetative", "start_day": 25, "end_day": 40, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering (spike) stage", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.MEDIUM, "stage": "flowering", "start_day": 51, "end_day": 90, "description": "Monitor primary and secondary spike development."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 60, "end_day": 130, "description": "Watch for capsule borer and semilooper during capsule development — castor's long duration means extended pest exposure."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 145, "end_day": 160, "description": "Begin preparing for harvest; castor is often harvested in multiple pickings as capsules mature."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 150, "end_day": 175, "description": "This is an estimated harvest window. Confirm capsule maturity before harvesting each picking."},
    ],
    OilseedCrop.SAFFLOWER: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 8, "end_day": 16, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.HIGH, "stage": "vegetative", "start_day": 20, "end_day": 32, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering stage", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 46, "end_day": 80, "description": "Monitor crop growth during flowering. Safflower has spiny bracts — handle with care during field checks."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.MEDIUM, "stage": "flowering", "start_day": 50, "end_day": 105, "description": "Watch for aphid infestation during flowering and seed development."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 120, "end_day": 130, "description": "Begin preparing for harvest and monitor crop maturity."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 125, "end_day": 140, "description": "This is an estimated harvest window. Confirm crop maturity in the field before harvesting."},
    ],
    OilseedCrop.LINSEED: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 7, "end_day": 15, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.MEDIUM, "stage": "vegetative", "start_day": 20, "end_day": 30, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering stage", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.HIGH, "stage": "flowering", "start_day": 41, "end_day": 65, "description": "Monitor crop growth and look for signs of stress during flowering."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.MEDIUM, "stage": "flowering", "start_day": 45, "end_day": 90, "description": "Watch for bud fly and aphids during flowering and boll development."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 105, "end_day": 113, "description": "Begin preparing for harvest and monitor crop maturity."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 108, "end_day": 120, "description": "This is an estimated harvest window. Confirm crop maturity in the field before harvesting."},
    ],
    OilseedCrop.NIGER: [
        {"activity_key": "crop_establishment_check", "title": "Inspect crop establishment", "category": ActivityCategory.CROP_ESTABLISHMENT, "priority": ActivityPriority.MEDIUM, "stage": "germination", "start_day": 6, "end_day": 12, "description": "Check crop establishment and look for uneven emergence or early stress."},
        {"activity_key": "weed_management_check", "title": "Check for weed growth", "category": ActivityCategory.WEED_MANAGEMENT, "priority": ActivityPriority.MEDIUM, "stage": "vegetative", "start_day": 15, "end_day": 25, "description": "Monitor the field for weed growth during the early crop stage."},
        {"activity_key": "flowering_monitoring", "title": "Monitor flowering stage", "category": ActivityCategory.CROP_MONITORING, "priority": ActivityPriority.MEDIUM, "stage": "flowering", "start_day": 31, "end_day": 55, "description": "Monitor crop growth and look for signs of stress during flowering."},
        {"activity_key": "pest_disease_monitoring", "title": "Increase pest and disease monitoring", "category": ActivityCategory.PEST_MONITORING, "priority": ActivityPriority.LOW, "stage": "flowering", "start_day": 35, "end_day": 65, "description": "Niger is relatively pest-hardy; occasional monitoring for aphids is sufficient."},
        {"activity_key": "harvest_preparation", "title": "Prepare for harvest", "category": ActivityCategory.HARVEST_PREPARATION, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 83, "end_day": 90, "description": "Begin preparing for harvest and monitor crop maturity."},
        {"activity_key": "expected_harvest", "title": "Expected harvest window", "category": ActivityCategory.HARVEST, "priority": ActivityPriority.HIGH, "stage": "maturity", "start_day": 85, "end_day": 95, "description": "This is an estimated harvest window. Confirm crop maturity in the field before harvesting."},
    ],
}


def compute_crop_age_days(sowing_date: date, today: date) -> int:
    return (today - sowing_date).days


def compute_current_stage(crop: OilseedCrop, age_days: int) -> dict | None:
    for stage in GROWTH_STAGES[crop]:
        if stage["start_day"] <= age_days <= stage["end_day"]:
            return stage
    return None


def compute_activity_status(start_date: date, end_date: date, completed_at, today: date) -> str:
    if completed_at is not None:
        return "completed"
    if today < start_date:
        return "upcoming"
    if start_date <= today <= end_date:
        return "active"
    return "overdue"


class ActivityGuidanceItem(BaseModel):
    activity_key: str
    guidance: str = Field(..., max_length=400)


class LLMCalendarGuidance(BaseModel):
    activity_guidance: list[ActivityGuidanceItem]


def _build_calendar_system_prompt(land: Land, crop: OilseedCrop, activities: list[dict]) -> str:
    activity_lines = "\n".join(
        f'- {a["activity_key"]}: "{a["title"]}" ({a["category"].value}) — {a["description"]}'
        for a in activities
    )
    return f"""You are an agronomy assistant for Tilahan Saathi, an app that helps oilseed \
farmers in India follow a cultivation calendar.

A deterministic system has already computed the exact schedule below for a {crop.value} crop \
on a farm with soil type {land.soil_type.value}, water availability {land.water_availability.value}, \
and planting season {land.planting_season.value}. Do NOT change, add, or remove any activity, \
its dates, category, or priority — those are fixed and verified elsewhere. Your ONLY job is to \
write one short, personalized guidance note for EACH activity below, tailored to this farm's \
specific soil and water conditions, grounded in the activity's own description.

Activities:
{activity_lines}

Return exactly one guidance note per activity_key listed above, using the EXACT activity_key \
values shown — do not rename, merge, split, or add activity_keys.
"""


async def _generate_guidance(system_prompt: str, expected_keys: set[str]) -> dict[str, str]:
    user_prompt = "Generate personalized guidance for each activity listed in the system prompt."

    async def _attempt(extra_instruction: str = "") -> dict[str, str]:
        result = await get_structured_completion(
            system_prompt=system_prompt,
            user_prompt=user_prompt + extra_instruction,
            response_schema=LLMCalendarGuidance,
        )
        got_keys = {item.activity_key for item in result.activity_guidance}
        if got_keys != expected_keys:
            raise LLMCallError(f"Expected activity_keys {expected_keys}, got {got_keys}")
        return {item.activity_key: item.guidance for item in result.activity_guidance}

    try:
        return await _attempt()
    except LLMCallError:
        try:
            return await _attempt(
                "\n\nIMPORTANT: You MUST return exactly one guidance note per activity_key "
                "listed, using EXACTLY those activity_key values — no more, no fewer, no renaming."
            )
        except LLMCallError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Unable to generate calendar guidance right now. Please try again shortly.",
            ) from exc


async def generate_calendar(land: Land, oilseed: Oilseed, db: AsyncSession) -> CropCalendar:
    crop = oilseed.crop
    sowing_date = oilseed.sowing_date
    if crop not in GROWTH_STAGES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"No calendar template is available for {crop.value} yet",
        )

    templates = ACTIVITY_TEMPLATES[crop]
    expected_keys = {t["activity_key"] for t in templates}
    system_prompt = _build_calendar_system_prompt(land, crop, templates)
    guidance_by_key = await _generate_guidance(system_prompt, expected_keys)

    calendar = CropCalendar(oilseed_id=oilseed.id)
    db.add(calendar)
    await db.flush()

    for template in templates:
        db.add(
            CropCalendarActivity(
                calendar_id=calendar.id,
                activity_key=template["activity_key"],
                stage=template["stage"],
                title=template["title"],
                category=template["category"],
                priority=template["priority"],
                description=template["description"],
                guidance=guidance_by_key[template["activity_key"]],
                start_date=sowing_date + timedelta(days=template["start_day"]),
                end_date=sowing_date + timedelta(days=template["end_day"]),
            )
        )

    await db.commit()
    await db.refresh(calendar)
    return calendar


def build_calendar_read(
    calendar: CropCalendar, oilseed: Oilseed, activities: list[CropCalendarActivity]
) -> CalendarRead:
    today = date.today()
    age_days = compute_crop_age_days(oilseed.sowing_date, today)
    current_stage = compute_current_stage(oilseed.crop, age_days)

    return CalendarRead(
        id=calendar.id,
        oilseed_id=calendar.oilseed_id,
        crop=oilseed.crop,
        sowing_date=oilseed.sowing_date,
        crop_age_days=age_days,
        current_stage=GrowthStageInfo(**current_stage) if current_stage else None,
        activities=[
            ActivityRead(
                id=a.id,
                activity_key=a.activity_key,
                stage=a.stage,
                title=a.title,
                category=a.category,
                priority=a.priority,
                description=a.description,
                guidance=a.guidance,
                start_date=a.start_date,
                end_date=a.end_date,
                completed_at=a.completed_at,
                status=compute_activity_status(a.start_date, a.end_date, a.completed_at, today),
            )
            for a in activities
        ],
        created_at=calendar.created_at,
    )
