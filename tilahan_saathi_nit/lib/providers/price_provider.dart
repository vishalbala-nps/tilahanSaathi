import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/prices/price_repository.dart';
import 'package:tilahan_saathi/models/crop_summary.dart';
import 'package:tilahan_saathi/models/price_entry.dart';
import 'package:tilahan_saathi/providers/oilseeds_provider.dart';

final priceRepositoryProvider = Provider<PriceRepository>((ref) => PriceRepository());

final cropsListProvider = FutureProvider.autoDispose<List<CropSummary>>(
  (ref) => ref.read(priceRepositoryProvider).listCrops(),
);

final priceHistoryProvider = FutureProvider.autoDispose.family<List<PriceEntry>, String>(
  (ref, commodityName) => ref.read(priceRepositoryProvider).getPrices(commodityName: commodityName),
);

typedef OilseedKey = ({int landId, int oilseedId});

/// Most recent price for a planted oilseed, or `null` if the backend has no
/// price data for its crop (e.g. castor/linseed aren't tracked by Agmarknet,
/// or nothing has synced yet) — `null` rather than throwing lets callers show
/// nothing instead of an error for what's a secondary, easily-missing datum.
final oilseedLatestPriceProvider = FutureProvider.autoDispose.family<PriceEntry?, OilseedKey>(
  (ref, key) async {
    final prices = await ref.read(oilseedsRepositoryProvider).getOilseedPrices(key.landId, key.oilseedId);
    return prices.isEmpty ? null : prices.first;
  },
);
