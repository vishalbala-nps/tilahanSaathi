import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/providers/farm_profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(farmProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Namaste, Kisan!',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (profile.district != null)
              Text(
                '${profile.district}, ${profile.state}',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.eco_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Crop',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            profile.currentCrop ?? 'Groundnut',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Growth stage: Flowering',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.55,
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            color: AppColors.accent.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.earthBrown, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Advisory",
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.earthBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Apply micronutrients this week. Avoid irrigation before expected rain.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _QuickStatCard(
                  icon: Icons.wb_sunny_rounded,
                  label: '32°C',
                  subtitle: 'Partly cloudy',
                  color: AppColors.skyBlue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _QuickStatCard(
                  icon: Icons.water_drop_rounded,
                  label: '60%',
                  subtitle: 'Humidity',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Upcoming Tasks',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _TaskTile(title: 'Pest inspection', date: 'Tomorrow', icon: Icons.bug_report_outlined),
          const _TaskTile(title: 'Light irrigation', date: 'In 3 days', icon: Icons.water_outlined),
          const _TaskTile(title: 'Fertilizer top-dress', date: 'In 5 days', icon: Icons.grass_rounded),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionChip(icon: Icons.calendar_month_rounded, label: 'Calendar'),
              _ActionChip(icon: Icons.health_and_safety_outlined, label: 'Crop Health'),
              _ActionChip(icon: Icons.cloud_outlined, label: 'Weather'),
              _ActionChip(icon: Icons.auto_awesome, label: 'Ask AI'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.title,
    required this.date,
    required this.icon,
  });

  final String title;
  final String date;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
            Text(
              date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      onPressed: () {},
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
    );
  }
}
