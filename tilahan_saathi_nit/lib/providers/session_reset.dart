import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/providers/farm_profile_provider.dart';

/// Resets state scoped to the signed-in user on logout.
///
/// Note this is only responsible for [farmProfileProvider] (in-progress
/// onboarding state, which isn't tied to the app shell's lifecycle and so
/// needs an explicit reset). The lands/oilseeds/calendar providers don't need
/// manual resetting here — they're all `.autoDispose`, so they're discarded
/// automatically once `MainShell` and its tabs unmount on navigating to
/// `/login`, and recomputed fresh (with a valid token) next time something
/// watches them. Manually invalidating a non-autoDispose provider here was
/// the previous approach, but it eagerly recomputes regardless of whether
/// anything is still watching — with the access token already cleared, that
/// caused an unhandled 401 exception instead of a clean reset.
void resetUserSession(WidgetRef ref) {
  ref.read(farmProfileProvider.notifier).reset();
}
