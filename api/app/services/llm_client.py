import json

import litellm
from pydantic import BaseModel, ValidationError

from app.core.config import settings


class LLMCallError(Exception):
    """Raised for any failure calling the LLM or parsing its response."""


async def get_structured_completion(
    *, system_prompt: str, user_prompt: str, response_schema: type[BaseModel]
) -> BaseModel:
    try:
        response = await litellm.acompletion(
            model=settings.llm_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format=response_schema,
            temperature=settings.llm_temperature,
            timeout=settings.llm_timeout_seconds,
        )
    except litellm.exceptions.APIError as exc:
        raise LLMCallError(str(exc)) from exc

    content = response.choices[0].message.content
    try:
        return response_schema.model_validate_json(content)
    except (json.JSONDecodeError, ValidationError) as exc:
        raise LLMCallError(f"LLM response failed schema validation: {exc}") from exc
