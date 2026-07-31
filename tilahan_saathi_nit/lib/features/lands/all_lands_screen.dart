import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/async_error_view.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/models/land.dart';
import 'package:tilahan_saathi/providers/farm_profile_provider.dart';
import 'package:tilahan_saathi/providers/lands_provider.dart';
import 'package:tilahan_saathi/providers/selected_land_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class AllLandsScreen extends ConsumerStatefulWidget {
  const AllLandsScreen({super.key});

  @override
  ConsumerState<AllLandsScreen> createState() => _AllLandsScreenState();
}

class _AllLandsScreenState extends ConsumerState<AllLandsScreen> {
  Future<void> _confirmDelete(Land land) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this land?'),
        content: Text(
          'This will permanently remove "${land.name}" and everything grown on it. '
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

    try {
      await ref.read(landsRepositoryProvider).deleteLand(land.id);
      ref.invalidate(landsListProvider);
      if (ref.read(selectedLandIdProvider) == land.id) {
        ref.read(selectedLandIdProvider.notifier).state = null;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final landsAsync = ref.watch(landsListProvider);
    final selectedId = ref.watch(selectedLandIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Lands')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: landsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorView(
              message: friendlyErrorMessage(error),
              onRetry: () => ref.invalidate(landsListProvider),
            ),
            data: (lands) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: lands.isEmpty
                      ? Center(
                          child: Text(
                            'No lands added yet.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: lands.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final land = lands[index];
                            final isSelected = (selectedId ?? lands.first.id) == land.id;
                            return _LandTile(
                              land: land,
                              isSelected: isSelected,
                              onTap: () {
                                ref.read(selectedLandIdProvider.notifier).state = land.id;
                                context.pop();
                              },
                              onDetails: () => context.push(AppRoutes.landDetails, extra: land),
                              onDelete: () => _confirmDelete(land),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Add New Land',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    ref.read(farmProfileProvider.notifier).reset();
                    context.push(AppRoutes.farmSetup);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LandTile extends StatelessWidget {
  const _LandTile({
    required this.land,
    required this.isSelected,
    required this.onTap,
    required this.onDetails,
    required this.onDelete,
  });

  final Land land;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDetails;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.earthBrown.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.landscape_rounded, color: AppColors.earthBrown, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  land.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${land.farmLocation} · ${land.areaAcres.toStringAsFixed(1)} acres',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
            tooltip: 'Details',
            onPressed: onDetails,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
