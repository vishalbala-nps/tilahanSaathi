import enum


class SoilType(str, enum.Enum):
    SANDY = "sandy"
    LOAMY = "loamy"
    CLAY = "clay"
    RED_SOIL = "red_soil"
    BLACK_SOIL = "black_soil"
    MIXED = "mixed"
    UNKNOWN = "unknown"


class WaterAvailability(str, enum.Enum):
    RELIABLE = "reliable"
    LIMITED = "limited"
    RAIN_FED = "rain_fed"
    UNKNOWN = "unknown"


class PlantingSeason(str, enum.Enum):
    KHARIF = "kharif"
    RABI = "rabi"
    SUMMER = "summer"
    UNKNOWN = "unknown"
