
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/data/oilseeds/oilseed_agronomy.dart';
import 'package:tilahan_saathi/models/enums.dart';
import 'package:tilahan_saathi/providers/calendar_provider.dart';
import 'package:tilahan_saathi/providers/oilseeds_provider.dart';
import 'package:tilahan_saathi/providers/selected_land_provider.dart';

class AddOilseedScreen extends ConsumerStatefulWidget {
  const AddOilseedScreen({super.key, this.preselectedCrop});

  final OilseedCrop? preselectedCrop;

  @override
  ConsumerState<AddOilseedScreen> createState() => _AddOilseedScreenState();
}

class _AddOilseedScreenState extends ConsumerState<AddOilseedScreen> {
  OilseedCrop? _selectedCrop;
  DateTime _sowingDate = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCrop = widget.preselectedCrop;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _sowingDate = picked);
  }

  /// Whether the currently selected crop is agronomically unsuitable for the
  /// season implied by the chosen sowing date — and if so, the message
  /// explaining why.
  String? get _seasonMismatchMessage {
    final crop = _selectedCrop;
    if (crop == null) return null;

    final season = seasonForMonth(_sowingDate.month);
    final agronomy = oilseedAgronomyKnowledge[crop]!;
    if (agronomy.suitableSeason.contains(season)) return null;

    final suitableSeasons = agronomy.suitableSeason.map((s) => s.label).join(', ');
    return '${crop.label} is not usually sown in ${season.label} '
        '(sowing month: ${_monthName(_sowingDate.month)}). '
        'Suitable seasons for ${crop.label}: $suitableSeasons.';
  }

  Future<void> _submit() async {
    final crop = _selectedCrop;
    if (crop == null) return;

    final seasonMismatch = _seasonMismatchMessage;
    if (seasonMismatch != null) {
      setState(() => _errorMessage = seasonMismatch);
      return;
    }

    final land = ref.read(selectedLandProvider).value;
    if (land == null) {
      setState(() => _errorMessage = 'No land selected.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final oilseed = await ref.read(oilseedsRepositoryProvider).createOilseed(
            land.id,
            crop: crop,
            sowingDate: _sowingDate,
          );
      await ref.read(calendarRepositoryProvider).createCalendar(land.id, oilseed.id);
      ref.invalidate(oilseedsForLandProvider(land.id));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) setState(() => _errorMessage = friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Oilseed')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Which oilseed are you planting?',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: OilseedCrop.values.map((crop) {
                  final isSelected = _selectedCrop == crop;
                  return FilterChip(
                    avatar: Icon(crop.icon, size: 18, color: isSelected ? Colors.white : crop.color),
                    label: Text(crop.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCrop = crop),
                    backgroundColor: AppColors.surface,
                    selectedColor: crop.color,
                    checkmarkColor: Colors.white,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? crop.color : AppColors.primary.withValues(alpha: 0.25),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Sowing date',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              AppCard(
                onTap: _pickDate,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(_formatDate(_sowingDate), style: theme.textTheme.bodyLarge),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
              if (_seasonMismatchMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _seasonMismatchMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                      label: 'Add Oilseed',
                      onPressed:
                          (_selectedCrop == null || _seasonMismatchMessage != null) ? null : _submit,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _monthName(int month) => _monthNames[month - 1];
}
