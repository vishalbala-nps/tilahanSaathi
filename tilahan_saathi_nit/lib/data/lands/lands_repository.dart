import 'package:tilahan_saathi/core/network/api_client.dart';
import 'package:tilahan_saathi/models/land.dart';

/// Talks to the backend's `/lands` endpoints.
class LandsRepository {
  Future<List<Land>> getLands() async {
    final response = await dio.get<List<dynamic>>('/lands');
    return (response.data ?? [])
        .map((e) => Land.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Land> createLand(Map<String, dynamic> payload) async {
    final response = await dio.post<Map<String, dynamic>>('/lands', data: payload);
    return Land.fromJson(response.data!);
  }

  Future<void> deleteLand(int id) async {
    await dio.delete<void>('/lands/$id');
  }
}
