from pydantic import BaseModel


class CropSummary(BaseModel):
    commodity_name: str
    commodity_group: str
