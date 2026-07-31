import 'package:tilahan_saathi/models/enums.dart';

class OilseedAgronomy {
  const OilseedAgronomy({
    required this.suitableSoil,
    required this.suitableWater,
    required this.suitableSeason,
    required this.notes,
  });

  final List<SoilType> suitableSoil;
  final List<WaterAvailability> suitableWater;
  final List<PlantingSeason> suitableSeason;
  final String notes;
}

/// Agronomic suitability reference for each oilseed crop.
const oilseedAgronomyKnowledge = <OilseedCrop, OilseedAgronomy>{
  OilseedCrop.groundnut: OilseedAgronomy(
    suitableSoil: [SoilType.sandy, SoilType.loamy, SoilType.redSoil],
    suitableWater: [
      WaterAvailability.rainFed,
      WaterAvailability.limited,
      WaterAvailability.reliable,
    ],
    suitableSeason: [PlantingSeason.kharif, PlantingSeason.summer],
    notes: 'Prefers well-drained light soils; waterlogging harms pod development. '
        'Good rotation after cereals (rice/maize); avoid repeating after itself or '
        'other legumes due to soil-borne disease buildup.',
  ),
  OilseedCrop.soybean: OilseedAgronomy(
    suitableSoil: [SoilType.loamy, SoilType.blackSoil, SoilType.clay],
    suitableWater: [WaterAvailability.rainFed, WaterAvailability.reliable],
    suitableSeason: [PlantingSeason.kharif],
    notes: 'Thrives in black cotton soils with good moisture retention. Excellent '
        'nitrogen-fixing rotation partner before wheat (rabi) in soybean-wheat systems.',
  ),
  OilseedCrop.sesame: OilseedAgronomy(
    suitableSoil: [SoilType.sandy, SoilType.loamy, SoilType.redSoil, SoilType.blackSoil],
    suitableWater: [WaterAvailability.limited, WaterAvailability.rainFed],
    suitableSeason: [PlantingSeason.kharif, PlantingSeason.summer],
    notes: 'Highly drought-tolerant, poor performer in waterlogged or heavy clay '
        'conditions. Good short-duration catch crop between main seasons.',
  ),
  OilseedCrop.mustard: OilseedAgronomy(
    suitableSoil: [SoilType.loamy, SoilType.clay, SoilType.blackSoil],
    suitableWater: [WaterAvailability.limited, WaterAvailability.reliable],
    suitableSeason: [PlantingSeason.rabi],
    notes: 'Classic rabi oilseed, often grown after kharif rice/cotton harvest using '
        'residual soil moisture. Tolerates mild water stress once established.',
  ),
  OilseedCrop.sunflower: OilseedAgronomy(
    suitableSoil: [SoilType.loamy, SoilType.blackSoil, SoilType.redSoil, SoilType.mixed],
    suitableWater: [WaterAvailability.reliable, WaterAvailability.limited],
    suitableSeason: [PlantingSeason.kharif, PlantingSeason.rabi, PlantingSeason.summer],
    notes: 'Adaptable across all three seasons if irrigation is available; deep '
        'taproot gives moderate drought tolerance once established.',
  ),
  OilseedCrop.castor: OilseedAgronomy(
    suitableSoil: [SoilType.sandy, SoilType.redSoil, SoilType.mixed, SoilType.blackSoil],
    suitableWater: [WaterAvailability.rainFed, WaterAvailability.limited],
    suitableSeason: [PlantingSeason.kharif],
    notes: 'Very drought-hardy, tolerates poor/marginal soils where other oilseeds '
        'struggle; long duration crop, less suited to fast rotations.',
  ),
  OilseedCrop.safflower: OilseedAgronomy(
    suitableSoil: [SoilType.blackSoil, SoilType.clay, SoilType.loamy],
    suitableWater: [WaterAvailability.limited, WaterAvailability.rainFed],
    suitableSeason: [PlantingSeason.rabi],
    notes: 'Deep-rooted, good residual-moisture rabi crop on heavy soils after a '
        'kharif cereal; poor tolerance of waterlogging.',
  ),
  OilseedCrop.linseed: OilseedAgronomy(
    suitableSoil: [SoilType.loamy, SoilType.clay, SoilType.blackSoil],
    suitableWater: [WaterAvailability.reliable, WaterAvailability.limited],
    suitableSeason: [PlantingSeason.rabi],
    notes: 'Cool-season rabi crop needing reasonable moisture; commonly '
        'relay-cropped or grown after rice in rice-linseed systems.',
  ),
  OilseedCrop.niger: OilseedAgronomy(
    suitableSoil: [SoilType.redSoil, SoilType.sandy, SoilType.mixed],
    suitableWater: [WaterAvailability.rainFed, WaterAvailability.limited],
    suitableSeason: [PlantingSeason.kharif],
    notes: 'Suited to poor, marginal upland soils with minimal input; common '
        'tribal-belt/hill-region crop, tolerates low fertility.',
  ),
};

/// First-draft sowing-month -> season mapping. Actual kharif/rabi/summer windows
/// vary by region in India — confirm with an agronomist before relying on this
/// for production guidance.
const _monthToSeason = <int, PlantingSeason>{
  1: PlantingSeason.rabi,
  2: PlantingSeason.rabi,
  3: PlantingSeason.summer,
  4: PlantingSeason.summer,
  5: PlantingSeason.summer,
  6: PlantingSeason.kharif,
  7: PlantingSeason.kharif,
  8: PlantingSeason.kharif,
  9: PlantingSeason.kharif,
  10: PlantingSeason.rabi,
  11: PlantingSeason.rabi,
  12: PlantingSeason.rabi,
};

PlantingSeason seasonForMonth(int month) => _monthToSeason[month]!;
