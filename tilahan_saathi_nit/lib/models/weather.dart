class Weather {
  const Weather({
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.currentRainfallMm,
    required this.rainfallTodayMm,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperatureCelsius: (json['temperature_celsius'] as num).toDouble(),
      humidityPercent: (json['humidity_percent'] as num).toDouble(),
      currentRainfallMm: (json['current_rainfall_mm'] as num).toDouble(),
      rainfallTodayMm: (json['rainfall_today_mm'] as num).toDouble(),
    );
  }

  final double temperatureCelsius;
  final double humidityPercent;
  final double currentRainfallMm;
  final double rainfallTodayMm;
}
