import 'package:tilahan_saathi/core/network/api_client.dart';
import 'package:tilahan_saathi/models/crop_summary.dart';
import 'package:tilahan_saathi/models/price_entry.dart';

/// Talks to the backend's `/crops` and `/price` endpoints.
class PriceRepository {
  Future<List<CropSummary>> listCrops() async {
    final response = await dio.get<List<dynamic>>('/crops');
    return (response.data ?? [])
        .map((e) => CropSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PriceEntry>> getPrices({required String commodityName}) async {
    final response = await dio.get<List<dynamic>>(
      '/price',
      queryParameters: {'commodity_name': commodityName},
    );
    return (response.data ?? [])
        .map((e) => PriceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
