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
import 'package:tilahan_saathi/providers/calendar_provider.dart';
import 'package:tilahan_saathi/providers/farm_profile_provider.dart';
import 'package:tilahan_saathi/providers/lands_provider.dart';
import 'package:tilahan_saathi/providers/oilseeds_provider.dart';
import 'package:tilahan_saathi/providers/price_provider.dart';
import 'package:tilahan_saathi/providers/selected_land_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landAsync = ref.watch(selectedLandProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tilahan Saathi'),
        actions: [
          if (landAsync.value != null)
            TextButton(
              onPressed: () => context.push(AppRoutes.allLands),
              child: const Text('All Lands'),
            ),
        ],
      ),
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
        const SizedBox(height: 20),
        _WeatherCard(landId: land.id),
        const SizedBox(height: 20),
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
      onTap: () => context.push(AppRoutes.landDetails, extra: land),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _WeatherCard extends ConsumerWidget {
  const _WeatherCard({required this.landId});

  final int landId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(landWeatherProvider(landId));

    return weatherAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (error, _) => AsyncErrorView(
        message: friendlyErrorMessage(error),
        onRetry: () => ref.invalidate(landWeatherProvider(landId)),
      ),
      data: (weather) => AppCard(
        child: Row(
          children: [
            Expanded(
              child: _WeatherStat(
                icon: Icons.thermostat_rounded,
                color: AppColors.accent,
                value: '${weather.temperatureCelsius.toStringAsFixed(1)}°C',
                label: 'Temperature',
              ),
            ),
            const _WeatherDivider(),
            Expanded(
              child: _WeatherStat(
                icon: Icons.water_drop_rounded,
                color: AppColors.skyBlue,
                value: '${weather.humidityPercent.toStringAsFixed(0)}%',
                label: 'Humidity',
              ),
            ),
            const _WeatherDivider(),
            Expanded(
              child: _WeatherStat(
                icon: Icons.umbrella_rounded,
                color: AppColors.primary,
                value: '${weather.rainfallTodayMm.toStringAsFixed(1)} mm',
                label: 'Rainfall Today',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherDivider extends StatelessWidget {
  const _WeatherDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.textSecondary.withValues(alpha: 0.15));
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _OilseedCard extends ConsumerWidget {
  const _OilseedCard({required this.landId, required this.oilseed});

  final int landId;
  final Oilseed oilseed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final crop = oilseed.crop;
    final calendarAsync = ref.watch(calendarProvider((landId: landId, oilseedId: oilseed.id)));
    final priceAsync = ref.watch(oilseedLatestPriceProvider((landId: landId, oilseedId: oilseed.id)));

    return AppCard(
      onTap: () => context.push(
        '${AppRoutes.oilseedCalendar}?landId=$landId&oilseedId=${oilseed.id}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      calendarAsync.when(
                        data: (calendar) => calendar.stageAndDayLabel,
                        loading: () => 'Sown ${_formatDate(oilseed.sowingDate)}',
                        error: (_, __) => 'Sown ${_formatDate(oilseed.sowingDate)}',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    priceAsync.maybeWhen(
                      data: (price) => price == null
                          ? const SizedBox.shrink()
                          : Text(
                              '₹${price.pricePerQuintal.toStringAsFixed(0)}/quintal · ${_formatShortDate(price.reportedDate)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
          calendarAsync.maybeWhen(
            data: (calendar) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _ProgressBar(progress: calendar.progress, color: crop.color),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatShortDate(DateTime date) => '${date.day}/${date.month}';
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).round()}%',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
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
