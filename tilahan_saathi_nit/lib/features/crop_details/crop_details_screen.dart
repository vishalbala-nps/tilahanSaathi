import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/features/crop_details/crop_detail_model.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class CropDetailsScreen extends ConsumerWidget {
  const CropDetailsScreen({super.key, required this.crop});

  final CropDetail crop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(crop.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CropIllustration(color: crop.color),
              const SizedBox(height: 24),
              _SuitabilityHeader(crop: crop),
              const SizedBox(height: 24),
              Text(
                'Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.date_range_rounded,
                      label: 'Growing Duration',
                      value: crop.growingDuration,
                    ),
                    const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.water_drop_rounded,
                      label: 'Water Requirement',
                      value: crop.waterRequirement,
                    ),
                    const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.calendar_month_rounded,
                      label: 'Season',
                      value: crop.season,
                    ),
                    const Divider(height: 20),
                    _InfoRow(
                      icon: Icons.assessment_rounded,
                      label: 'Suitability',
                      value: '${crop.suitabilityScore}% Match',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Why Recommended',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Text(
                  crop.whyRecommended,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Things to Consider',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...crop.thingsToConsider.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Compare Profitability',
                icon: Icons.compare_arrows_rounded,
                onPressed: () => context.go(AppRoutes.profitability),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Back to Recommendations',
                onPressed: () => context.go(AppRoutes.recommendations),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropIllustration extends StatelessWidget {
  const _CropIllustration({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                7,
                (i) => Icon(
                  Icons.grass_rounded,
                  size: 24,
                  color: color.withValues(alpha: 0.3 + i * 0.08),
                ),
              ),
            ),
          ),
          CircleAvatar(
            radius: 48,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              Icons.eco_rounded,
              size: 48,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuitabilityHeader extends StatelessWidget {
  const _SuitabilityHeader({required this.crop});

  final CropDetail crop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI Match Score',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${crop.suitabilityScore}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: crop.suitabilityScore / 100,
            minHeight: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            color: crop.color,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}