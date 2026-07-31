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

class AlternativeCrop {
  const AlternativeCrop({required this.crop, required this.reasonNotChosen});

  factory AlternativeCrop.fromJson(Map<String, dynamic> json) {
    return AlternativeCrop(
      crop: OilseedCrop.fromApi(json['crop'] as String),
      reasonNotChosen: json['reason_not_chosen'] as String,
    );
  }

  final OilseedCrop crop;
  final String reasonNotChosen;
}

class CropRecommendation {
  const CropRecommendation({
    required this.recommendedCrop,
    required this.confidence,
    required this.reasoning,
    required this.positiveFactors,
    required this.alternatives,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      recommendedCrop: OilseedCrop.fromApi(json['recommended_crop'] as String),
      confidence: ConfidenceLevel.fromApi(json['confidence'] as String),
      reasoning: json['reasoning'] as String,
      positiveFactors: (json['positive_factors'] as List<dynamic>)
          .map((e) => PositiveFactor.fromJson(e as Map<String, dynamic>))
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((e) => AlternativeCrop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final OilseedCrop recommendedCrop;
  final ConfidenceLevel confidence;
  final String reasoning;
  final List<PositiveFactor> positiveFactors;
  final List<AlternativeCrop> alternatives;
}
