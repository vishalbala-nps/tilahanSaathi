import 'package:tilahan_saathi/models/enums.dart';

class Activity {
  const Activity({
    required this.id,
    required this.activityKey,
    required this.stage,
    required this.title,
    required this.category,
    required this.priority,
    required this.description,
    required this.guidance,
    required this.startDate,
    required this.endDate,
    required this.completedAt,
    required this.status,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int,
      activityKey: json['activity_key'] as String,
      stage: json['stage'] as String,
      title: json['title'] as String,
      category: ActivityCategory.fromApi(json['category'] as String),
      priority: ActivityPriority.fromApi(json['priority'] as String),
      description: json['description'] as String,
      guidance: json['guidance'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      status: ActivityStatus.fromApi(json['status'] as String),
    );
  }

  final int id;
  final String activityKey;
  final String stage;
  final String title;
  final ActivityCategory category;
  final ActivityPriority priority;
  final String description;
  final String guidance;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? completedAt;
  final ActivityStatus status;

  bool get isCompleted => completedAt != null;

  bool coversDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}
