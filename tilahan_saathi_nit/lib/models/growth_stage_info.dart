class GrowthStageInfo {
  const GrowthStageInfo({
    required this.stage,
    required this.name,
    required this.startDay,
    required this.endDay,
  });

  factory GrowthStageInfo.fromJson(Map<String, dynamic> json) {
    return GrowthStageInfo(
      stage: json['stage'] as String,
      name: json['name'] as String,
      startDay: json['start_day'] as int,
      endDay: json['end_day'] as int,
    );
  }

  final String stage;
  final String name;
  final int startDay;
  final int endDay;
}
