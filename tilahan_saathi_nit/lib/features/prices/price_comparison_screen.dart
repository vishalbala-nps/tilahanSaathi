import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/async_error_view.dart';
import 'package:tilahan_saathi/data/prices/oilseed_commodity_names.dart';
import 'package:tilahan_saathi/models/crop_summary.dart';
import 'package:tilahan_saathi/models/price_entry.dart';
import 'package:tilahan_saathi/providers/price_provider.dart';

const _normalCropColor = AppColors.skyBlue;
const _oilseedColor = AppColors.primary;

class PriceComparisonScreen extends ConsumerStatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  ConsumerState<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends ConsumerState<PriceComparisonScreen> {
  String? _normalCrop;
  String? _oilseedCrop;

  @override
  Widget build(BuildContext context) {
    final cropsAsync = ref.watch(cropsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Compare Prices')),
      body: SafeArea(
        child: cropsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.invalidate(cropsListProvider),
          ),
          data: _buildContent,
        ),
      ),
    );
  }

  Widget _buildContent(List<CropSummary> crops) {
    final theme = Theme.of(context);

    final normalCrops = crops.where((c) => !oilseedCommodityNames.contains(c.commodityName)).toList();
    final oilseedCrops = crops.where((c) => oilseedCommodityNames.contains(c.commodityName)).toList();

    if (normalCrops.isEmpty || oilseedCrops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Not enough price data available yet to compare crops.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final normalCrop = _normalCrop ?? normalCrops.first.commodityName;
    final oilseedCrop = _oilseedCrop ?? oilseedCrops.first.commodityName;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _CropDropdown(
                label: 'Normal Crop',
                color: _normalCropColor,
                value: normalCrop,
                crops: normalCrops,
                onChanged: (value) => setState(() => _normalCrop = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CropDropdown(
                label: 'Oilseed',
                color: _oilseedColor,
                value: oilseedCrop,
                crops: oilseedCrops,
                onChanged: (value) => setState(() => _oilseedCrop = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ComparisonBody(normalCrop: normalCrop, oilseedCrop: oilseedCrop),
      ],
    );
  }
}

class _CropDropdown extends StatelessWidget {
  const _CropDropdown({
    required this.label,
    required this.color,
    required this.value,
    required this.crops,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final String value;
  final List<CropSummary> crops;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: crops
              .map((crop) => DropdownMenuItem(
                    value: crop.commodityName,
                    child: Text(crop.commodityName, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ComparisonBody extends ConsumerWidget {
  const _ComparisonBody({required this.normalCrop, required this.oilseedCrop});

  final String normalCrop;
  final String oilseedCrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalAsync = ref.watch(priceHistoryProvider(normalCrop));
    final oilseedAsync = ref.watch(priceHistoryProvider(oilseedCrop));
    final theme = Theme.of(context);

    if (normalAsync.isLoading || oilseedAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = normalAsync.error ?? oilseedAsync.error;
    if (error != null) {
      return AsyncErrorView(
        message: friendlyErrorMessage(error),
        onRetry: () {
          ref.invalidate(priceHistoryProvider(normalCrop));
          ref.invalidate(priceHistoryProvider(oilseedCrop));
        },
      );
    }

    final normalPrices = normalAsync.value ?? const <PriceEntry>[];
    final oilseedPrices = oilseedAsync.value ?? const <PriceEntry>[];

    if (normalPrices.isEmpty && oilseedPrices.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'No price data available for $normalCrop or $oilseedCrop yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final normalLatest = normalPrices.isEmpty ? null : normalPrices.first;
    final oilseedLatest = oilseedPrices.isEmpty ? null : oilseedPrices.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _LatestPriceCard(label: normalCrop, color: _normalCropColor, entries: normalPrices)),
            const SizedBox(width: 12),
            Expanded(child: _LatestPriceCard(label: oilseedCrop, color: _oilseedColor, entries: oilseedPrices)),
          ],
        ),
        const SizedBox(height: 16),
        _NetProfitCard(
          normalCropName: normalCrop,
          oilseedCropName: oilseedCrop,
          normalLatest: normalLatest,
          oilseedLatest: oilseedLatest,
        ),
        const SizedBox(height: 16),
        _PriceChart(normalCrop: normalCrop, oilseedCrop: oilseedCrop, normalPrices: normalPrices, oilseedPrices: oilseedPrices),
        if (normalPrices.isEmpty || oilseedPrices.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'No price data available for ${normalPrices.isEmpty ? normalCrop : oilseedCrop} yet.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _NetProfitCard extends StatelessWidget {
  const _NetProfitCard({
    required this.normalCropName,
    required this.oilseedCropName,
    required this.normalLatest,
    required this.oilseedLatest,
  });

  final String normalCropName;
  final String oilseedCropName;
  final PriceEntry? normalLatest;
  final PriceEntry? oilseedLatest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normal = normalLatest;
    final oilseed = oilseedLatest;

    if (normal == null || oilseed == null) {
      return AppCard(
        child: Text(
          'Not enough price data yet to estimate the gain from switching.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final diff = oilseed.pricePerQuintal - normal.pricePerQuintal;
    final isGain = diff >= 0;
    final percent = normal.pricePerQuintal == 0 ? null : (diff / normal.pricePerQuintal * 100);
    final color = isGain ? AppColors.primary : AppColors.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isGain ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Switching from $normalCropName to $oilseedCropName',
                  style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isGain ? '+' : '-'}₹${diff.abs().toStringAsFixed(0)} / quintal',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          if (percent != null)
            Text(
              '${isGain ? '+' : ''}${percent.toStringAsFixed(1)}% vs $normalCropName',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 8),
          Text(
            "Based on the latest market price per quintal only — doesn't account for "
            'yield, input costs, or other differences between crops.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({
    required this.normalCrop,
    required this.oilseedCrop,
    required this.normalPrices,
    required this.oilseedPrices,
  });

  final String normalCrop;
  final String oilseedCrop;
  final List<PriceEntry> normalPrices;
  final List<PriceEntry> oilseedPrices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final allDates = <DateTime>{
      ...normalPrices.map((e) => e.reportedDate),
      ...oilseedPrices.map((e) => e.reportedDate),
    }.toList()
      ..sort();

    final allValues = [
      ...normalPrices.map((e) => e.pricePerQuintal),
      ...oilseedPrices.map((e) => e.pricePerQuintal),
    ];
    final maxY = allValues.isEmpty ? 100.0 : allValues.reduce((a, b) => a > b ? a : b) * 1.2;

    final groups = List.generate(allDates.length, (i) {
      final date = allDates[i];
      final normalPrice = _priceOn(normalPrices, date) ?? 0.0;
      final oilseedPrice = _priceOn(oilseedPrices, date) ?? 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: normalPrice,
            width: 14,
            color: _normalCropColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: oilseedPrice,
            width: 14,
            color: _oilseedColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
        ],
      );
    });

    return AppCard(
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barGroups: groups,
            barTouchData: BarTouchData(enabled: true),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= allDates.length) return const SizedBox();
                    final d = allDates[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${d.day}/${d.month}', style: theme.textTheme.labelSmall),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double? _priceOn(List<PriceEntry> list, DateTime date) {
    for (final entry in list) {
      if (entry.reportedDate == date) return entry.pricePerQuintal;
    }
    return null;
  }
}

class _LatestPriceCard extends StatelessWidget {
  const _LatestPriceCard({required this.label, required this.color, required this.entries});

  final String label;
  final Color color;
  final List<PriceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = entries.isEmpty ? null : entries.first;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            latest != null ? '₹${latest.pricePerQuintal.toStringAsFixed(0)}' : '—',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            latest != null ? 'per quintal · ${latest.reportedDate.day}/${latest.reportedDate.month}' : 'No data yet',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
