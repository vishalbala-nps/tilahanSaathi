from datetime import datetime

from pydantic import BaseModel, ConfigDict


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    firebase_uid: str
    email: str | None
    display_name: str | None
    created_at: datetime
