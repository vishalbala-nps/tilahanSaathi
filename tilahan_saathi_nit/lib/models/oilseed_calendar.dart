import 'package:tilahan_saathi/models/activity.dart';
import 'package:tilahan_saathi/models/enums.dart';
import 'package:tilahan_saathi/models/growth_stage_info.dart';

class OilseedCalendar {
  const OilseedCalendar({
    required this.id,
    required this.oilseedId,
    required this.crop,
    required this.sowingDate,
    required this.cropAgeDays,
    required this.currentStage,
    required this.activities,
    required this.createdAt,
  });

  factory OilseedCalendar.fromJson(Map<String, dynamic> json) {
    return OilseedCalendar(
      id: json['id'] as int,
      oilseedId: json['oilseed_id'] as int,
      crop: OilseedCrop.fromApi(json['crop'] as String),
      sowingDate: DateTime.parse(json['sowing_date'] as String),
      cropAgeDays: json['crop_age_days'] as int,
      currentStage: json['current_stage'] == null
          ? null
          : GrowthStageInfo.fromJson(json['current_stage'] as Map<String, dynamic>),
      activities: (json['activities'] as List<dynamic>)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int oilseedId;
  final OilseedCrop crop;
  final DateTime sowingDate;
  final int cropAgeDays;
  final GrowthStageInfo? currentStage;
  final List<Activity> activities;
  final DateTime createdAt;

  List<Activity> activitiesOn(DateTime day) =>
      activities.where((a) => a.coversDay(day)).toList();
}
