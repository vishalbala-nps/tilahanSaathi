import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/lands/lands_repository.dart';

final landsRepositoryProvider = Provider<LandsRepository>((ref) => LandsRepository());
