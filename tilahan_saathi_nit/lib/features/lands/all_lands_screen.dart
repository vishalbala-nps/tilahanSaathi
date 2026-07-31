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

class AllLandsScreen extends ConsumerWidget {
  const AllLandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
  const _LandTile({required this.land, required this.isSelected, required this.onTap});

  final Land land;
  final bool isSelected;
  final VoidCallback onTap;

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
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          else
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
