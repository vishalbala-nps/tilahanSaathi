import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/oilseeds/oilseeds_repository.dart';
import 'package:tilahan_saathi/models/oilseed.dart';

final oilseedsRepositoryProvider = Provider<OilseedsRepository>((ref) => OilseedsRepository());

// autoDispose: see landsListProvider for why — avoids an eager, unauthenticated
// refetch (and the resulting unhandled exception) when the session resets.
final oilseedsForLandProvider = FutureProvider.autoDispose.family<List<Oilseed>, int>(
  (ref, landId) => ref.read(oilseedsRepositoryProvider).listOilseeds(landId),
);
