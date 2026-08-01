import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/async_error_view.dart';
import 'package:tilahan_saathi/models/scheme_recommendation.dart';
import 'package:tilahan_saathi/providers/schemes_provider.dart';

class GovernmentSchemesScreen extends ConsumerStatefulWidget {
  const GovernmentSchemesScreen({super.key});

  @override
  ConsumerState<GovernmentSchemesScreen> createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends ConsumerState<GovernmentSchemesScreen> {
  bool _isLoading = true;
  SchemeRecommendationResponse? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSchemes();
  }

  Future<void> _fetchSchemes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(schemesRepositoryProvider).recommendSchemes();
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
      appBar: AppBar(
        title: const Text('Government Schemes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchSchemes,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? AsyncErrorView(message: _errorMessage!, onRetry: _fetchSchemes)
                : _buildResult(Theme.of(context), _result!),
      ),
    );
  }

  Widget _buildResult(ThemeData theme, SchemeRecommendationResponse result) {
    final hasNoSchemes = result.suggestions.isEmpty && result.possiblyRelevant.isEmpty;

    return RefreshIndicator(
      onRefresh: _fetchSchemes,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (hasNoSchemes)
            AppCard(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'No matching schemes found for your farm yet.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (result.suggestions.isNotEmpty) ...[
            Text(
              'Recommended for You',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...result.suggestions.map(
              (scheme) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SchemeCard(scheme: scheme, isCertain: true),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (result.possiblyRelevant.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Might Also Apply',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...result.possiblyRelevant.map(
              (scheme) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SchemeCard(scheme: scheme, isCertain: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  const _SchemeCard({required this.scheme, required this.isCertain});

  final SchemeSuggestion scheme;
  final bool isCertain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = isCertain ? AppColors.primary : AppColors.earthBrown;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  scheme.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (!isCertain)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.earthBrown.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Check Eligibility',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.earthBrown,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(scheme.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.card_giftcard_rounded, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scheme.keyBenefit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            scheme.reason,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (scheme.url != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scheme.url!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.skyBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
