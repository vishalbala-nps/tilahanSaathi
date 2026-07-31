import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/calendar/calendar_repository.dart';
import 'package:tilahan_saathi/models/oilseed_calendar.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) => CalendarRepository());

typedef CalendarKey = ({int landId, int oilseedId});

// autoDispose: see landsListProvider for why — avoids an eager, unauthenticated
// refetch (and the resulting unhandled exception) when the session resets.
class CalendarNotifier extends AutoDisposeFamilyAsyncNotifier<OilseedCalendar, CalendarKey> {
  @override
  Future<OilseedCalendar> build(CalendarKey arg) {
    return ref.read(calendarRepositoryProvider).getOrCreateCalendar(arg.landId, arg.oilseedId);
  }

  /// Marks an activity complete/incomplete and updates local state directly
  /// from the server's response, avoiding a redundant refetch.
  Future<void> completeActivity(int activityId, {required bool completed}) async {
    final updated = await ref.read(calendarRepositoryProvider).completeActivity(
          arg.landId,
          arg.oilseedId,
          activityId,
          completed: completed,
        );
    state = AsyncValue.data(updated);
  }
}

final calendarProvider =
    AsyncNotifierProvider.autoDispose.family<CalendarNotifier, OilseedCalendar, CalendarKey>(
  CalendarNotifier.new,
);
