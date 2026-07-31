import 'package:tilahan_saathi/models/enums.dart';

class Oilseed {
  const Oilseed({
    required this.id,
    required this.landId,
    required this.crop,
    required this.sowingDate,
    required this.createdAt,
  });

  factory Oilseed.fromJson(Map<String, dynamic> json) {
    return Oilseed(
      id: json['id'] as int,
      landId: json['land_id'] as int,
      crop: OilseedCrop.fromApi(json['crop'] as String),
      sowingDate: DateTime.parse(json['sowing_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int landId;
  final OilseedCrop crop;
  final DateTime sowingDate;
  final DateTime createdAt;
}
