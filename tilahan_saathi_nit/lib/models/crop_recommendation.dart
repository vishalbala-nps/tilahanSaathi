import 'package:tilahan_saathi/models/enums.dart';

class PositiveFactor {
  const PositiveFactor({
    required this.factor,
    required this.assessment,
    required this.reason,
  });

  factory PositiveFactor.fromJson(Map<String, dynamic> json) {
    return PositiveFactor(
      factor: EvaluationFactor.fromApi(json['factor'] as String),
      assessment: PositiveFactorAssessment.fromApi(json['assessment'] as String),
      reason: json['reason'] as String,
    );
  }

  final EvaluationFactor factor;
  final PositiveFactorAssessment assessment;
  final String reason;
}

class CropRecommendation {
  const CropRecommendation({
    required this.recommendedCrop,
    required this.confidencePercent,
    required this.reasoning,
    required this.positiveFactors,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      recommendedCrop: OilseedCrop.fromApi(json['recommended_crop'] as String),
      confidencePercent: (json['confidence_percent'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
      positiveFactors: (json['positive_factors'] as List<dynamic>)
          .map((e) => PositiveFactor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final OilseedCrop recommendedCrop;
  final double confidencePercent;
  final String reasoning;
  final List<PositiveFactor> positiveFactors;
}
