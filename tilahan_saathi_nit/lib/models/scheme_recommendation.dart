class SchemeSuggestion {
  const SchemeSuggestion({
    required this.scheme,
    required this.name,
    required this.description,
    required this.keyBenefit,
    required this.url,
    required this.reason,
  });

  factory SchemeSuggestion.fromJson(Map<String, dynamic> json) {
    return SchemeSuggestion(
      scheme: json['scheme'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      keyBenefit: json['key_benefit'] as String,
      url: json['url'] as String?,
      reason: json['reason'] as String,
    );
  }

  final String scheme;
  final String name;
  final String description;
  final String keyBenefit;
  final String? url;
  final String reason;
}

class SchemeRecommendationResponse {
  const SchemeRecommendationResponse({
    required this.totalLandAreaAcres,
    required this.suggestions,
    required this.possiblyRelevant,
    required this.disclaimer,
  });

  factory SchemeRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return SchemeRecommendationResponse(
      totalLandAreaAcres: (json['total_land_area_acres'] as num).toDouble(),
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => SchemeSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      possiblyRelevant: (json['possibly_relevant'] as List<dynamic>)
          .map((e) => SchemeSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      disclaimer: json['disclaimer'] as String,
    );
  }

  final double totalLandAreaAcres;
  final List<SchemeSuggestion> suggestions;
  final List<SchemeSuggestion> possiblyRelevant;
  final String disclaimer;
}
