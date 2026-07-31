import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/oilseeds/oilseeds_repository.dart';
import 'package:tilahan_saathi/models/oilseed.dart';

final oilseedsRepositoryProvider = Provider<OilseedsRepository>((ref) => OilseedsRepository());

final oilseedsForLandProvider = FutureProvider.family<List<Oilseed>, int>(
  (ref, landId) => ref.read(oilseedsRepositoryProvider).listOilseeds(landId),
);
