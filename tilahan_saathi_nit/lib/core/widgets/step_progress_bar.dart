import 'package:flutter/material.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';

class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${((currentStep + 1) / totalSteps * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            color: AppColors.primary,
          ),
        ),
        if (labels != null && currentStep < labels!.length) ...[
          const SizedBox(height: 8),
          Text(
            labels![currentStep],
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
