class CropSummary {
  const CropSummary({required this.commodityName, required this.commodityGroup});

  factory CropSummary.fromJson(Map<String, dynamic> json) {
    return CropSummary(
      commodityName: json['commodity_name'] as String,
      commodityGroup: json['commodity_group'] as String,
    );
  }

  final String commodityName;
  final String commodityGroup;
}
