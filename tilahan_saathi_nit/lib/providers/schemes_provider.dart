import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/schemes/schemes_repository.dart';

final schemesRepositoryProvider = Provider<SchemesRepository>((ref) => SchemesRepository());
