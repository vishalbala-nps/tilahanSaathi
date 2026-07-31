import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/models/land.dart';
import 'package:tilahan_saathi/providers/lands_provider.dart';

/// The id of the land the farmer is currently viewing. `null` means "no
/// explicit pick yet" — defer to the first land in the list.
final selectedLandIdProvider = StateProvider<int?>((ref) => null);

/// The land to actually show as "current" — resolves [selectedLandIdProvider]
/// against the live lands list, falling back to the first land, or `null`
/// if the farmer has no lands at all.
final selectedLandProvider = Provider<AsyncValue<Land?>>((ref) {
  final landsAsync = ref.watch(landsListProvider);
  return landsAsync.whenData((lands) {
    if (lands.isEmpty) return null;
    final selectedId = ref.watch(selectedLandIdProvider);
    return lands.firstWhere((land) => land.id == selectedId, orElse: () => lands.first);
  });
});
