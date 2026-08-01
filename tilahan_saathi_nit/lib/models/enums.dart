import 'package:flutter/material.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';

enum SoilType {
  sandy('sandy', 'Sandy'),
  loamy('loamy', 'Loamy'),
  clay('clay', 'Clay'),
  redSoil('red_soil', 'Red Soil'),
  blackSoil('black_soil', 'Black Soil'),
  mixed('mixed', 'Mixed'),
  unknown('unknown', 'Unknown');

  const SoilType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static SoilType fromApi(String value) =>
      SoilType.values.firstWhere((e) => e.apiValue == value, orElse: () => SoilType.unknown);
}

enum WaterAvailability {
  reliable('reliable', 'Reliable'),
  limited('limited', 'Limited'),
  rainFed('rain_fed', 'Rain-fed'),
  unknown('unknown', 'Unknown');

  const WaterAvailability(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static WaterAvailability fromApi(String value) => WaterAvailability.values
      .firstWhere((e) => e.apiValue == value, orElse: () => WaterAvailability.unknown);
}

enum PlantingSeason {
  kharif('kharif', 'Kharif'),
  rabi('rabi', 'Rabi'),
  summer('summer', 'Summer'),
  unknown('unknown', 'Unknown');

  const PlantingSeason(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PlantingSeason fromApi(String value) => PlantingSeason.values
      .firstWhere((e) => e.apiValue == value, orElse: () => PlantingSeason.unknown);
}

enum OilseedCrop {
  groundnut('groundnut', 'Groundnut', Icons.grain_rounded, AppColors.earthBrown),
  soybean('soybean', 'Soybean', Icons.eco_rounded, AppColors.primary),
  sesame('sesame', 'Sesame', Icons.spa_rounded, AppColors.accent),
  mustard('mustard', 'Mustard', Icons.local_florist_rounded, Color(0xFFCDA434)),
  sunflower('sunflower', 'Sunflower', Icons.wb_sunny_rounded, Color(0xFFF2A93B)),
  castor('castor', 'Castor', Icons.park_rounded, Color(0xFF6B8E23)),
  safflower('safflower', 'Safflower', Icons.local_florist_rounded, Color(0xFFE2725B)),
  linseed('linseed', 'Linseed', Icons.grass_rounded, Color(0xFF4A6FA5)),
  niger('niger', 'Niger', Icons.eco_rounded, AppColors.secondary);

  const OilseedCrop(this.apiValue, this.label, this.icon, this.color);

  final String apiValue;
  final String label;
  final IconData icon;
  final Color color;

  static OilseedCrop fromApi(String value) =>
      OilseedCrop.values.firstWhere((e) => e.apiValue == value);
}

enum ActivityCategory {
  cropEstablishment('crop_establishment', 'Crop Establishment', Icons.eco_rounded),
  fieldMonitoring('field_monitoring', 'Field Monitoring', Icons.visibility_outlined),
  nutrientManagement('nutrient_management', 'Nutrient Management', Icons.science_outlined),
  irrigation('irrigation', 'Irrigation', Icons.water_drop_rounded),
  weedManagement('weed_management', 'Weed Management', Icons.content_cut_rounded),
  cropMonitoring('crop_monitoring', 'Crop Monitoring', Icons.monitor_heart_outlined),
  pestMonitoring('pest_monitoring', 'Pest Monitoring', Icons.bug_report_outlined),
  harvestPreparation('harvest_preparation', 'Harvest Preparation', Icons.checklist_rounded),
  harvest('harvest', 'Harvest', Icons.agriculture_rounded),
  postHarvest('post_harvest', 'Post-Harvest', Icons.inventory_2_outlined);

  const ActivityCategory(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static ActivityCategory fromApi(String value) =>
      ActivityCategory.values.firstWhere((e) => e.apiValue == value);
}

enum ActivityPriority {
  low('low', 'Low', AppColors.primary),
  medium('medium', 'Medium', AppColors.accent),
  high('high', 'High', Color(0xFFE2725B)),
  critical('critical', 'Critical', AppColors.error);

  const ActivityPriority(this.apiValue, this.label, this.color);

  final String apiValue;
  final String label;
  final Color color;

  static ActivityPriority fromApi(String value) =>
      ActivityPriority.values.firstWhere((e) => e.apiValue == value);
}

enum ActivityStatus {
  upcoming('upcoming', 'Upcoming', AppColors.textSecondary, Icons.schedule_rounded),
  active('active', 'Active', AppColors.skyBlue, Icons.play_circle_outline_rounded),
  completed('completed', 'Completed', AppColors.primary, Icons.check_circle_rounded),
  overdue('overdue', 'Overdue', AppColors.error, Icons.warning_amber_rounded);

  const ActivityStatus(this.apiValue, this.label, this.color, this.icon);

  final String apiValue;
  final String label;
  final Color color;
  final IconData icon;

  static ActivityStatus fromApi(String value) =>
      ActivityStatus.values.firstWhere((e) => e.apiValue == value);
}

enum EvaluationFactor {
  location('location', 'Location', Icons.location_on_outlined),
  season('season', 'Season', Icons.calendar_month_outlined),
  soil('soil', 'Soil', Icons.terrain_rounded),
  waterAvailability('water_availability', 'Water Availability', Icons.water_drop_outlined),
  previousCrop('previous_crop', 'Previous Crop', Icons.history_rounded),
  regionalSuitability('regional_suitability', 'Regional Suitability', Icons.map_outlined),
  sowingWindow('sowing_window', 'Sowing Window', Icons.event_available_outlined),
  cropRotation('crop_rotation', 'Crop Rotation', Icons.autorenew_rounded),
  dataAvailability('data_availability', 'Data Availability', Icons.analytics_outlined),
  other('other', 'Other', Icons.info_outline_rounded);

  const EvaluationFactor(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static EvaluationFactor fromApi(String value) =>
      EvaluationFactor.values.firstWhere((e) => e.apiValue == value);
}

enum PositiveFactorAssessment {
  excellentMatch('excellent_match', 'Excellent Match', AppColors.primary),
  goodMatch('good_match', 'Good Match', AppColors.accent),
  acceptableMatch('acceptable_match', 'Acceptable Match', AppColors.textSecondary);

  const PositiveFactorAssessment(this.apiValue, this.label, this.color);

  final String apiValue;
  final String label;
  final Color color;

  static PositiveFactorAssessment fromApi(String value) => PositiveFactorAssessment.values
      .firstWhere((e) => e.apiValue == value);
}
