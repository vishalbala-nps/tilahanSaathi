import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/data/mock/crop_details.dart';
import 'package:tilahan_saathi/features/auth/forgot_password_screen.dart';
import 'package:tilahan_saathi/features/auth/login_screen.dart';
import 'package:tilahan_saathi/features/auth/signup_screen.dart';
import 'package:tilahan_saathi/features/crop_details/crop_details_screen.dart';
import 'package:tilahan_saathi/features/home/main_shell.dart';
import 'package:tilahan_saathi/features/lands/all_lands_screen.dart';
import 'package:tilahan_saathi/features/lands/land_details_screen.dart';
import 'package:tilahan_saathi/features/oilseeds/add_oilseed_screen.dart';
import 'package:tilahan_saathi/features/oilseeds/oilseed_calendar_screen.dart';
import 'package:tilahan_saathi/features/oilseeds/suggest_oilseed_screen.dart';
import 'package:tilahan_saathi/features/onboarding/farm_setup_screen.dart';
import 'package:tilahan_saathi/features/recommendations/crop_recommendations_screen.dart';
import 'package:tilahan_saathi/features/splash/splash_screen.dart';
import 'package:tilahan_saathi/features/welcome/welcome_screen.dart';
import 'package:tilahan_saathi/models/enums.dart';
import 'package:tilahan_saathi/models/land.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const farmSetup = '/farm-setup';
  static const recommendations = '/recommendations';
  static const cropDetails = '/crop-details';
  static const profitability = '/profitability';
  static const allLands = '/lands';
  static const landDetails = '/land-details';
  static const addOilseed = '/add-oilseed';
  static const suggestOilseed = '/suggest-oilseed';
  static const oilseedCalendar = '/oilseed-calendar';
  static const home = '/home';
  static const myCrop = '/my-crop';
  static const market = '/market';
  static const profile = '/profile';
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmSetup,
        builder: (context, state) => const FarmSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.recommendations,
        builder: (context, state) => const CropRecommendationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.cropDetails,
        pageBuilder: (context, state) {
          final name = state.uri.queryParameters['name'] ?? '';
          final crop = CropDetailsData.all
              .firstWhere((c) => c.name == name, orElse: () => CropDetailsData.groundnut);
          return MaterialPage(child: CropDetailsScreen(crop: crop));
        },
      ),
      GoRoute(
        path: AppRoutes.profitability,
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.allLands,
        builder: (context, state) => const AllLandsScreen(),
      ),
      GoRoute(
        path: AppRoutes.landDetails,
        builder: (context, state) => LandDetailsScreen(land: state.extra as Land),
      ),
      GoRoute(
        path: AppRoutes.addOilseed,
        builder: (context, state) =>
            AddOilseedScreen(preselectedCrop: state.extra as OilseedCrop?),
      ),
      GoRoute(
        path: AppRoutes.suggestOilseed,
        builder: (context, state) => const SuggestOilseedScreen(),
      ),
      GoRoute(
        path: AppRoutes.oilseedCalendar,
        builder: (context, state) {
          final landId = int.parse(state.uri.queryParameters['landId']!);
          final oilseedId = int.parse(state.uri.queryParameters['oilseedId']!);
          return OilseedCalendarScreen(landId: landId, oilseedId: oilseedId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myCrop,
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.market,
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
