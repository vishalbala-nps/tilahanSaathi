import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/auth/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
