import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/async_error_view.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/models/crop_recommendation.dart';
import 'package:tilahan_saathi/models/enums.dart';
import 'package:tilahan_saathi/providers/oilseeds_provider.dart';
import 'package:tilahan_saathi/providers/selected_land_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class SuggestOilseedScreen extends ConsumerStatefulWidget {
  const SuggestOilseedScreen({super.key});

  @override
  ConsumerState<SuggestOilseedScreen> createState() => _SuggestOilseedScreenState();
}

class _SuggestOilseedScreenState extends ConsumerState<SuggestOilseedScreen> {
  bool _isLoading = true;
  CropRecommendation? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final land = ref.read(selectedLandProvider).value;
    if (land == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No land selected.';
      });
      return;
    }

    try {
      final result = await ref.read(oilseedsRepositoryProvider).recommendCrop(land.id);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Suggested Oilseed')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? AsyncErrorView(message: _errorMessage!, onRetry: _fetchRecommendation)
                : _buildResult(Theme.of(context), _result!),
      ),
    );
  }

  Widget _buildResult(ThemeData theme, CropRecommendation result) {
    final crop = result.recommendedCrop;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: crop.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(crop.icon, color: crop.color, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  crop.label,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ConfidenceBadge(confidence: result.confidence),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this crop?',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(result.reasoning, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...result.positiveFactors.map(
            (factor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(factor.factor.icon, color: factor.assessment.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            factor.factor.label,
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            factor.reason,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (result.alternatives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Alternatives Considered',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...result.alternatives.map(
              (alt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(alt.crop.icon, color: alt.crop.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alt.crop.label,
                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              alt.reasonNotChosen,
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Plant This Crop',
            icon: Icons.add_rounded,
            onPressed: () => context.push(AppRoutes.addOilseed, extra: crop),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final ConfidenceLevel confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: confidence.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${confidence.label} Confidence',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: confidence.color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
