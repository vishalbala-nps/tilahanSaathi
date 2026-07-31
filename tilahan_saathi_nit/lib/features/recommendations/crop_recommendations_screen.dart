import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/providers/farm_profile_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class CropRecommendationsScreen extends ConsumerWidget {
  const CropRecommendationsScreen({super.key});

  static const _crops = [
    _CropPreview(
      name: 'Groundnut',
      suitability: 92,
      reason: 'Ideal for your loamy soil and Kharif season',
      icon: Icons.grain_rounded,
      color: AppColors.earthBrown,
    ),
    _CropPreview(
      name: 'Sesame',
      suitability: 87,
      reason: 'Low water need suits your rainfed setup',
      icon: Icons.spa_rounded,
      color: AppColors.accent,
    ),
    _CropPreview(
      name: 'Sunflower',
      suitability: 84,
      reason: 'Strong market demand in your region',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.accent,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(farmProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('AI Crop Recommendations'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top picks for your farm',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.district ?? "Your district"}, ${profile.state ?? "India"} · '
                '${profile.landAreaAcres.toStringAsFixed(1)} acres',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _crops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final crop = _crops[index];
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: crop.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(crop.icon, color: crop.color, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      crop.name,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _SuitabilityBadge(score: crop.suitability),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            crop.reason,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => context.go(
                              '${AppRoutes.cropDetails}?name=${crop.name}',
                            ),
                            child: const Text('View Details'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              PrimaryButton(
                label: 'Go to Dashboard',
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuitabilityBadge extends StatelessWidget {
  const _SuitabilityBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score% Match',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _CropPreview {
  const _CropPreview({
    required this.name,
    required this.suitability,
    required this.reason,
    required this.icon,
    required this.color,
  });

  final String name;
  final int suitability;
  final String reason;
  final IconData icon;
  final Color color;
}
