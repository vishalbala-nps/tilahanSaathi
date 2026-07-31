import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/async_error_view.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/models/land.dart';
import 'package:tilahan_saathi/models/oilseed.dart';
import 'package:tilahan_saathi/providers/farm_profile_provider.dart';
import 'package:tilahan_saathi/providers/lands_provider.dart';
import 'package:tilahan_saathi/providers/oilseeds_provider.dart';
import 'package:tilahan_saathi/providers/selected_land_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landAsync = ref.watch(selectedLandProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tilahan Saathi')),
      body: SafeArea(
        child: landAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.invalidate(landsListProvider),
          ),
          data: (land) {
            if (land == null) return const _NoLandsState();
            return _HomeContent(land: land);
          },
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.land});

  final Land land;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oilseedsAsync = ref.watch(oilseedsForLandProvider(land.id));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _CurrentLandCard(land: land),
        const SizedBox(height: 24),
        Text(
          'Oilseeds Planted',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        oilseedsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => AsyncErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.invalidate(oilseedsForLandProvider(land.id)),
          ),
          data: (oilseeds) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (oilseeds.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      Icon(Icons.grass_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.6)),
                      const SizedBox(height: 12),
                      Text(
                        'No oilseeds planted on this land yet',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                )
              else
                ...oilseeds.map(
                  (oilseed) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OilseedCard(landId: land.id, oilseed: oilseed),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Oilseed'),
                onPressed: () => context.push(AppRoutes.addOilseed),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Suggest Oilseed',
                icon: Icons.auto_awesome,
                onPressed: () => context.push(AppRoutes.suggestOilseed),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrentLandCard extends StatelessWidget {
  const _CurrentLandCard({required this.land});

  final Land land;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              TextButton(
                onPressed: () => context.push(AppRoutes.allLands),
                child: const Text('All Lands'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: '${land.areaAcres.toStringAsFixed(1)} acres'),
              _InfoChip(label: land.soilType.label),
              _InfoChip(label: land.waterAvailability.label),
              _InfoChip(label: land.plantingSeason.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _OilseedCard extends StatelessWidget {
  const _OilseedCard({required this.landId, required this.oilseed});

  final int landId;
  final Oilseed oilseed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crop = oilseed.crop;

    return AppCard(
      onTap: () => context.push(
        '${AppRoutes.oilseedCalendar}?landId=$landId&oilseedId=${oilseed.id}',
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: crop.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(crop.icon, color: crop.color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.label,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Sown ${_formatDate(oilseed.sowingDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _NoLandsState extends ConsumerWidget {
  const _NoLandsState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.landscape_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                'No Land Added Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your farm to get crop recommendations and calendars.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Add Land',
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
    );
  }
}
