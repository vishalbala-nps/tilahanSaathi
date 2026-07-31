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


class ActivityCategory(str, enum.Enum):
    CROP_ESTABLISHMENT = "crop_establishment"
    FIELD_MONITORING = "field_monitoring"
    NUTRIENT_MANAGEMENT = "nutrient_management"
    IRRIGATION = "irrigation"
    WEED_MANAGEMENT = "weed_management"
    CROP_MONITORING = "crop_monitoring"
    PEST_MONITORING = "pest_monitoring"
    HARVEST_PREPARATION = "harvest_preparation"
    HARVEST = "harvest"
    POST_HARVEST = "post_harvest"


class ActivityPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class ActivityStatus(str, enum.Enum):
    UPCOMING = "upcoming"
    ACTIVE = "active"
    COMPLETED = "completed"
    OVERDUE = "overdue"
