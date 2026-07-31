import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              _FarmerIllustration(),
              const SizedBox(height: 32),
              Text(
                'Welcome, Kisan!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tilahan Saathi is your AI-powered companion for oilseed farming. '
                'Get crop recommendations, weather advisories, and market insights — '
                'all tailored for Indian farmers.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: 'Get Started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go(AppRoutes.farmSetup),
              ),
              const SizedBox(height: 12),
              Text(
                'Takes about 2 minutes to set up your farm',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmerIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.skyBlue.withValues(alpha: 0.35),
            AppColors.secondary.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 24,
            right: 32,
            child: Icon(
              Icons.wb_sunny_rounded,
              size: 48,
              color: AppColors.accent.withValues(alpha: 0.9),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _PersonIcon(color: AppColors.earthBrown),
                  const SizedBox(width: 16),
                  const _PersonIcon(color: AppColors.primary),
                  const SizedBox(width: 16),
                  _PersonIcon(color: AppColors.earthBrown.withValues(alpha: 0.8)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.grass_rounded,
                      size: 28 + (i % 2) * 8,
                      color: AppColors.primary.withValues(alpha: 0.5 + i * 0.08),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'AI Powered',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonIcon extends StatelessWidget {
  const _PersonIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(Icons.person_rounded, color: color, size: 32),
    );
  }
}
