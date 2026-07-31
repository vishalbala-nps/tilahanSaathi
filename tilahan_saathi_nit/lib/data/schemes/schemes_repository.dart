import 'package:tilahan_saathi/core/network/api_client.dart';
import 'package:tilahan_saathi/models/scheme_recommendation.dart';

/// Talks to the backend's `/schemes/recommendations` endpoint.
class SchemesRepository {
  Future<SchemeRecommendationResponse> recommendSchemes() async {
    final response = await dio.post<Map<String, dynamic>>('/schemes/recommendations');
    return SchemeRecommendationResponse.fromJson(response.data!);
  }
}
