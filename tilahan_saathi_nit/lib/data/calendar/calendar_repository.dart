import 'package:dio/dio.dart';
import 'package:tilahan_saathi/core/network/api_client.dart';
import 'package:tilahan_saathi/models/oilseed_calendar.dart';

/// Talks to the backend's per-oilseed calendar/activities endpoints.
class CalendarRepository {
  Future<OilseedCalendar> getCalendar(int landId, int oilseedId) async {
    final response =
        await dio.get<Map<String, dynamic>>('/lands/$landId/oilseeds/$oilseedId/calendar');
    return OilseedCalendar.fromJson(response.data!);
  }

  Future<OilseedCalendar> createCalendar(int landId, int oilseedId) async {
    final response =
        await dio.post<Map<String, dynamic>>('/lands/$landId/oilseeds/$oilseedId/calendar');
    return OilseedCalendar.fromJson(response.data!);
  }

  /// Fetches the oilseed's calendar, generating one first if it doesn't
  /// exist yet (e.g. the calendar wasn't created at the same time as the
  /// oilseed for some reason).
  Future<OilseedCalendar> getOrCreateCalendar(int landId, int oilseedId) async {
    try {
      return await getCalendar(landId, oilseedId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return createCalendar(landId, oilseedId);
      }
      rethrow;
    }
  }

  Future<OilseedCalendar> completeActivity(
    int landId,
    int oilseedId,
    int activityId, {
    required bool completed,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      '/lands/$landId/oilseeds/$oilseedId/calendar/activities/$activityId',
      data: {'completed': completed},
    );
    return OilseedCalendar.fromJson(response.data!);
  }
}
