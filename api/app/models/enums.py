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


class OilseedCrop(str, enum.Enum):
    GROUNDNUT = "groundnut"
    SOYBEAN = "soybean"
    SESAME = "sesame"
    MUSTARD = "mustard"
    SUNFLOWER = "sunflower"
    CASTOR = "castor"
    SAFFLOWER = "safflower"
    LINSEED = "linseed"
    NIGER = "niger"


class ConfidenceLevel(str, enum.Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class EvaluationFactor(str, enum.Enum):
    LOCATION = "location"
    SEASON = "season"
    SOIL = "soil"
    WATER_AVAILABILITY = "water_availability"
    PREVIOUS_CROP = "previous_crop"
    REGIONAL_SUITABILITY = "regional_suitability"
    SOWING_WINDOW = "sowing_window"
    CROP_ROTATION = "crop_rotation"
    DATA_AVAILABILITY = "data_availability"
    OTHER = "other"
