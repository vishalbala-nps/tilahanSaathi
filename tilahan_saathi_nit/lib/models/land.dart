import 'package:tilahan_saathi/models/enums.dart';

class Land {
  const Land({
    required this.id,
    required this.userId,
    required this.name,
    required this.farmLocation,
    required this.areaAcres,
    required this.soilType,
    required this.waterAvailability,
    required this.lastGrownCrop,
    required this.plantingSeason,
    required this.createdAt,
  });

  factory Land.fromJson(Map<String, dynamic> json) {
    return Land(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      farmLocation: json['farm_location'] as String,
      areaAcres: (json['area_acres'] as num).toDouble(),
      soilType: SoilType.fromApi(json['soil_type'] as String),
      waterAvailability: WaterAvailability.fromApi(json['water_availability'] as String),
      lastGrownCrop: json['last_grown_crop'] as String,
      plantingSeason: PlantingSeason.fromApi(json['planting_season'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final String userId;
  final String name;
  final String farmLocation;
  final double areaAcres;
  final SoilType soilType;
  final WaterAvailability waterAvailability;
  final String lastGrownCrop;
  final PlantingSeason plantingSeason;
  final DateTime createdAt;
}
