import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/providers/lands_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

/// Decides where to send the user right after a successful login, signup,
/// or auto-login: onboarding if they have no land registered yet, otherwise
/// straight to the home dashboard.
Future<void> navigateAfterLogin(BuildContext context, WidgetRef ref) async {
  final lands = await ref.read(landsRepositoryProvider).getLands();
  if (!context.mounted) return;
  context.go(lands.isEmpty ? AppRoutes.welcome : AppRoutes.home);
}
