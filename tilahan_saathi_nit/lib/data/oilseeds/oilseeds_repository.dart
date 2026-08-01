import 'package:intl/intl.dart';
import 'package:tilahan_saathi/core/network/api_client.dart';
import 'package:tilahan_saathi/models/crop_recommendation.dart';
import 'package:tilahan_saathi/models/enums.dart';
import 'package:tilahan_saathi/models/oilseed.dart';
import 'package:tilahan_saathi/models/price_entry.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

/// Talks to the backend's `/lands/{landId}/oilseeds` and
/// `/lands/{landId}/recommendations` endpoints.
class OilseedsRepository {
  Future<List<Oilseed>> listOilseeds(int landId) async {
    final response = await dio.get<List<dynamic>>('/lands/$landId/oilseeds');
    return (response.data ?? [])
        .map((e) => Oilseed.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Oilseed> createOilseed(
    int landId, {
    required OilseedCrop crop,
    required DateTime sowingDate,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/lands/$landId/oilseeds',
      data: {
        'crop': crop.apiValue,
        'sowing_date': _dateFormat.format(sowingDate),
      },
    );
    return Oilseed.fromJson(response.data!);
  }

  Future<CropRecommendation> recommendCrop(
    int landId, {
    required int nitrogen,
    required int phosphorus,
    required int potassium,
    required double ph,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/lands/$landId/recommendations',
      data: {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'ph': ph,
      },
    );
    return CropRecommendation.fromJson(response.data!);
  }

  Future<void> deleteOilseed(int landId, int oilseedId) async {
    await dio.delete<void>('/lands/$landId/oilseeds/$oilseedId');
  }

  Future<List<PriceEntry>> getOilseedPrices(int landId, int oilseedId) async {
    final response = await dio.get<List<dynamic>>('/lands/$landId/oilseeds/$oilseedId/price');
    return (response.data ?? [])
        .map((e) => PriceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
