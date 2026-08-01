import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/async_error_view.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/models/crop_recommendation.dart';
import 'package:tilahan_saathi/providers/lands_provider.dart';
import 'package:tilahan_saathi/providers/oilseeds_provider.dart';
import 'package:tilahan_saathi/providers/selected_land_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class SuggestOilseedScreen extends ConsumerWidget {
  const SuggestOilseedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landAsync = ref.watch(selectedLandProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Suggested Oilseed')),
      body: SafeArea(
        child: landAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.invalidate(landsListProvider),
          ),
          data: (land) => land == null
              ? AsyncErrorView(
                  message: 'No land selected.',
                  onRetry: () => ref.invalidate(landsListProvider),
                )
              : _SuggestOilseedForm(landId: land.id),
        ),
      ),
    );
  }
}

class _SuggestOilseedForm extends ConsumerStatefulWidget {
  const _SuggestOilseedForm({required this.landId});

  final int landId;

  @override
  ConsumerState<_SuggestOilseedForm> createState() => _SuggestOilseedFormState();
}

class _SuggestOilseedFormState extends ConsumerState<_SuggestOilseedForm> {
  final _formKey = GlobalKey<FormState>();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _phController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  CropRecommendation? _result;

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _phController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$label is required';
    return null;
  }

  String? _validatePh(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'pH is required';
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0 || parsed > 14) return 'pH must be between 0 and 14';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(oilseedsRepositoryProvider).recommendCrop(
            widget.landId,
            nitrogen: int.parse(_nitrogenController.text.trim()),
            phosphorus: int.parse(_phosphorusController.text.trim()),
            potassium: int.parse(_potassiumController.text.trim()),
            ph: double.parse(_phController.text.trim()),
          );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _editValues() => setState(() => _result = null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    return result == null ? _buildForm(theme) : _buildResult(theme, result);
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your latest soil test results to get a tailored crop recommendation.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nitrogenController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Nitrogen (N)'),
                    validator: (value) => _validateRequired(value, 'Nitrogen'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phosphorusController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Phosphorus (P)'),
                    validator: (value) => _validateRequired(value, 'Phosphorus'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _potassiumController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Potassium (K)'),
                    validator: (value) => _validateRequired(value, 'Potassium'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                    decoration: const InputDecoration(labelText: 'Soil pH'),
                    validator: _validatePh,
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            _isSubmitting
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : PrimaryButton(
                    label: 'Get Recommendation',
                    icon: Icons.auto_awesome,
                    onPressed: _submit,
                  ),
          ],
        ),
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _editValues,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Soil Values'),
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Plant This Crop',
            icon: Icons.add_rounded,
            onPressed: () {
              context.pop();
              context.push(AppRoutes.addOilseed, extra: crop);
            },
          ),
        ],
      ),
    );
  }
}
