import 'package:tilahan_saathi/core/network/api_client.dart';

/// Talks to the backend's `/lands` endpoints.
class LandsRepository {
  Future<List<dynamic>> getLands() async {
    final response = await dio.get<List<dynamic>>('/lands');
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> createLand(Map<String, dynamic> payload) async {
    final response = await dio.post<Map<String, dynamic>>('/lands', data: payload);
    return response.data!;
  }
}
