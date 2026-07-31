import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/models/land.dart';
import 'package:tilahan_saathi/providers/lands_provider.dart';
import 'package:tilahan_saathi/providers/selected_land_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class LandDetailsScreen extends ConsumerStatefulWidget {
  const LandDetailsScreen({super.key, required this.land});

  final Land land;

  @override
  ConsumerState<LandDetailsScreen> createState() => _LandDetailsScreenState();
}

class _LandDetailsScreenState extends ConsumerState<LandDetailsScreen> {
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this land?'),
        content: Text(
          'This will permanently remove "${widget.land.name}" and everything grown on it. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(landsRepositoryProvider).deleteLand(widget.land.id);
      ref.invalidate(landsListProvider);
      ref.read(selectedLandIdProvider.notifier).state = null;
      if (mounted) context.go(AppRoutes.home);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error))),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final land = widget.land;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Land Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.earthBrown.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.landscape_rounded, color: AppColors.earthBrown, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          land.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          land.farmLocation,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Land Details',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _DetailRow(icon: Icons.straighten_rounded, label: 'Area', value: '${land.areaAcres.toStringAsFixed(1)} acres'),
                  const Divider(height: 24),
                  _DetailRow(icon: Icons.terrain_rounded, label: 'Soil type', value: land.soilType.label),
                  const Divider(height: 24),
                  _DetailRow(icon: Icons.water_drop_rounded, label: 'Water availability', value: land.waterAvailability.label),
                  const Divider(height: 24),
                  _DetailRow(icon: Icons.calendar_today_rounded, label: 'Planting season', value: land.plantingSeason.label),
                  const Divider(height: 24),
                  _DetailRow(icon: Icons.eco_rounded, label: 'Last grown crop', value: land.lastGrownCrop),
                  const Divider(height: 24),
                  _DetailRow(icon: Icons.event_available_rounded, label: 'Added on', value: _formatDate(land.createdAt)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : OutlinedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    label: const Text('Delete Land', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
