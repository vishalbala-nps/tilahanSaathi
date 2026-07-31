import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/lands/lands_repository.dart';
import 'package:tilahan_saathi/models/land.dart';

final landsRepositoryProvider = Provider<LandsRepository>((ref) => LandsRepository());

final landsListProvider = FutureProvider<List<Land>>(
  (ref) => ref.read(landsRepositoryProvider).getLands(),
);
