import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/providers/auth_provider.dart';
import 'package:tilahan_saathi/providers/farm_profile_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(farmProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded, size: 40, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farmer',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '+91 XXXXX XXXXX',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Farm Information',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Location', value: '${profile.district ?? "—"}, ${profile.state ?? "—"}'),
                _InfoRow(label: 'Land area', value: '${profile.landAreaAcres.toStringAsFixed(1)} acres'),
                _InfoRow(label: 'Soil', value: profile.soilType ?? '—'),
                _InfoRow(label: 'Water', value: profile.waterAvailability ?? '—'),
                _InfoRow(label: 'Season', value: profile.planningSeason ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SettingsTile(icon: Icons.language_rounded, title: 'Language', subtitle: 'English'),
          const _SettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Enabled'),
          const _SettingsTile(icon: Icons.help_outline_rounded, title: 'Help & Support', subtitle: 'FAQs, contact'),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'Logout',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.error),
            ),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              ref.read(farmProfileProvider.notifier).reset();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {},
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
