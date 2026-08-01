class PriceEntry {
  const PriceEntry({
    required this.commodityName,
    required this.commodityGroup,
    required this.reportedDate,
    required this.pricePerQuintal,
    required this.arrivalMetricTonnes,
    required this.mspPrice,
    required this.trend,
  });

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    return PriceEntry(
      commodityName: json['commodity_name'] as String,
      commodityGroup: json['commodity_group'] as String,
      reportedDate: DateTime.parse(json['reported_date'] as String),
      pricePerQuintal: (json['price_per_quintal'] as num).toDouble(),
      arrivalMetricTonnes: (json['arrival_metric_tonnes'] as num?)?.toDouble(),
      mspPrice: (json['msp_price'] as num?)?.toDouble(),
      trend: json['trend'] as String?,
    );
  }

  final String commodityName;
  final String commodityGroup;
  final DateTime reportedDate;
  final double pricePerQuintal;
  final double? arrivalMetricTonnes;
  final double? mspPrice;
  final String? trend;
}
