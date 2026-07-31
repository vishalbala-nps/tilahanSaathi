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

  /// Length of the full crop cycle in days, derived from the furthest-out
  /// activity end date (the backend doesn't return the full stage list,
  /// only the current one, so this is the only cycle-length signal we have).
  int get totalCycleDays {
    if (activities.isEmpty) return 0;
    return activities
        .map((a) => a.endDate.difference(sowingDate).inDays)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Fraction (0.0-1.0) of the crop cycle elapsed so far.
  double get progress {
    if (totalCycleDays <= 0) return 0;
    return (cropAgeDays / totalCycleDays).clamp(0.0, 1.0);
  }

  /// Human-readable stage label that always has something sensible to show,
  /// even when [currentStage] is null (not sown yet, or past the last
  /// tracked stage).
  String get stageLabel {
    if (cropAgeDays < 0) return 'Not sown yet';
    final stage = currentStage;
    if (stage != null) return stage.name;
    if (totalCycleDays > 0 && cropAgeDays > totalCycleDays) return 'Ready for Harvest';
    return 'Growing';
  }

  /// Combined stage + day-count line for card/header display. Suppresses the
  /// negative day count for a future sowing date (e.g. "Day -6") in favor of
  /// a countdown to sowing.
  String get stageAndDayLabel {
    if (cropAgeDays < 0) {
      final daysUntilSowing = -cropAgeDays;
      return 'Sowing in $daysUntilSowing day${daysUntilSowing == 1 ? '' : 's'}';
    }
    return '$stageLabel · Day $cropAgeDays';
  }
}
