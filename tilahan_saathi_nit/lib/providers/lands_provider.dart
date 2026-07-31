import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/data/lands/lands_repository.dart';
import 'package:tilahan_saathi/models/land.dart';

final landsRepositoryProvider = Provider<LandsRepository>((ref) => LandsRepository());

// autoDispose: this holds the signed-in user's lands. Without it, invalidating
// this provider (e.g. on logout, to stop the next user's session from seeing
// stale data) would force an EAGER refetch on the next frame regardless of
// whether anything is still watching it — with the access token already
// cleared, that refetch 401s, and since nothing may be listening for that
// particular error at that moment, it surfaces as an unhandled exception
// instead of a normal AsyncValue.error. autoDispose means it's simply thrown
// away once unwatched (e.g. when the whole app shell unmounts on logout) and
// recomputed fresh — with a valid token — next time something watches it.
final landsListProvider = FutureProvider.autoDispose<List<Land>>(
  (ref) => ref.read(landsRepositoryProvider).getLands(),
);
