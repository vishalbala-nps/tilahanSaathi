import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/step_progress_bar.dart';
import 'package:tilahan_saathi/data/mock/india_locations.dart';
import 'package:tilahan_saathi/models/farm_profile.dart';
import 'package:tilahan_saathi/providers/farm_profile_provider.dart';
import 'package:tilahan_saathi/providers/lands_provider.dart';
import 'package:tilahan_saathi/providers/selected_land_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class FarmSetupScreen extends ConsumerStatefulWidget {
  const FarmSetupScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends ConsumerState<FarmSetupScreen> {
  static const _stepLabels = [
    'Land name',
    'Select your state',
    'Select your district',
    'Land area',
    'Soil type',
    'Water availability',
    'Current crop',
    'Planning season',
  ];

  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  void _next() {
    if (_currentStep < _stepLabels.length - 1) {
      setState(() => _currentStep++);
      return;
    }
    _submit();
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  Future<void> _submit() async {
    final profile = ref.read(farmProfileProvider);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final land = await ref.read(landsRepositoryProvider).createLand({
        'name': profile.landName,
        'farm_location': '${profile.district}, ${profile.state}',
        'area_acres': profile.landAreaAcres,
        'soil_type': LandApiMapping.soilType[profile.soilType],
        'water_availability': LandApiMapping.waterAvailability[profile.waterAvailability],
        'last_grown_crop': profile.currentCrop,
        'planting_season': LandApiMapping.plantingSeason[profile.planningSeason],
      });
      ref.invalidate(landsListProvider);
      ref.read(selectedLandIdProvider.notifier).state = land.id;
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool get _canProceed {
    final profile = ref.watch(farmProfileProvider);
    switch (_currentStep) {
      case 0:
        return (profile.landName ?? '').trim().isNotEmpty;
      case 1:
        return profile.state != null;
      case 2:
        return profile.district != null;
      case 3:
        return profile.landAreaAcres > 0;
      case 4:
        return profile.soilType != null;
      case 5:
        return profile.waterAvailability != null;
      case 6:
        return profile.currentCrop != null;
      case 7:
        return profile.planningSeason != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastStep = _currentStep == _stepLabels.length - 1;
    final profile = ref.watch(farmProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _back,
        ),
        title: const Text('Land Setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StepProgressBar(
                currentStep: _currentStep,
                totalSteps: _stepLabels.length,
                labels: _stepLabels,
              ),
              const SizedBox(height: 28),
              Expanded(child: _buildStepContent(theme, profile)),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              _isSubmitting
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : FilledButton(
                      onPressed: _canProceed ? _next : null,
                      child: Text(isLastStep ? 'Finish Setup' : 'Continue'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, FarmProfile profile) {
    return switch (_currentStep) {
      0 => _TextEntryStep(
          title: 'What would you like to name this land?',
          subtitle: 'e.g. "Home Field" or "North Plot"',
          hintText: 'Land name',
          initialValue: profile.landName ?? '',
          onChanged: (v) => ref.read(farmProfileProvider.notifier).setLandName(v),
        ),
      1 => _StateLocationStep(
          selected: profile.state,
          onSelected: (v) => ref.read(farmProfileProvider.notifier).setState(v),
          onLocationDetected: (state, district) {
            ref.read(farmProfileProvider.notifier).setState(state);
            if (district != null) {
              ref.read(farmProfileProvider.notifier).setDistrict(district);
            }
          },
        ),
      2 => _SearchableListStep(
          title: 'Select your district',
          subtitle: profile.state ?? '',
          items: IndiaLocations.districtsFor(profile.state),
          selected: profile.district,
          onSelected: (v) => ref.read(farmProfileProvider.notifier).setDistrict(v),
        ),
      3 => _LandAreaStep(
          key: ValueKey(profile.landAreaAcres),
          acres: profile.landAreaAcres,
          onChanged: (v) =>
              ref.read(farmProfileProvider.notifier).setLandAreaAcres(v),
        ),
      4 => _ChipSelectionStep(
          title: 'What type of soil do you have?',
          options: FarmOptions.soilTypes,
          selected: profile.soilType,
          onSelected: (v) => ref.read(farmProfileProvider.notifier).setSoilType(v),
        ),
      5 => _RadioSelectionStep(
          title: 'How do you irrigate your fields?',
          options: FarmOptions.waterOptions,
          selected: profile.waterAvailability,
          onSelected: (v) =>
              ref.read(farmProfileProvider.notifier).setWaterAvailability(v),
        ),
      6 => _SearchableListStep(
          title: 'What crop are you growing now?',
          items: FarmOptions.currentCrops,
          selected: profile.currentCrop,
          onSelected: (v) =>
              ref.read(farmProfileProvider.notifier).setCurrentCrop(v),
        ),
      7 => _ChipSelectionStep(
          title: 'Which season are you planning for?',
          options: FarmOptions.seasons,
          selected: profile.planningSeason,
          onSelected: (v) =>
              ref.read(farmProfileProvider.notifier).setPlanningSeason(v),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _TextEntryStep extends StatefulWidget {
  const _TextEntryStep({
    required this.title,
    required this.hintText,
    required this.onChanged,
    this.subtitle,
    this.initialValue = '',
  });

  final String title;
  final String? subtitle;
  final String hintText;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_TextEntryStep> createState() => _TextEntryStepState();
}

class _TextEntryStepState extends State<_TextEntryStep> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: widget.hintText),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _StateLocationStep extends StatefulWidget {
  const _StateLocationStep({
    required this.selected,
    required this.onSelected,
    required this.onLocationDetected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  /// Called when the device's current location was successfully matched to
  /// a supported state (and, if possible, a district within it).
  final void Function(String state, String? district) onLocationDetected;

  @override
  State<_StateLocationStep> createState() => _StateLocationStepState();
}

class _StateLocationStepState extends State<_StateLocationStep> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _SearchableListStep(
            title: 'Which state is your land in?',
            items: IndiaLocations.states,
            selected: widget.selected,
            onSelected: widget.onSelected,
          ),
        ),
      ],
    );
  }
}

class _SearchableListStep extends StatefulWidget {
  const _SearchableListStep({
    required this.title,
    required this.items,
    required this.onSelected,
    this.selected,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  State<_SearchableListStep> createState() => _SearchableListStepState();
}

class _SearchableListStepState extends State<_SearchableListStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.items
        .where((item) => item.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final isSelected = widget.selected == item;
              return Material(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => widget.onSelected(item),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LandAreaStep extends StatefulWidget {
  const _LandAreaStep({
    super.key,
    required this.acres,
    required this.onChanged,
  });

  final double acres;
  final ValueChanged<double> onChanged;

  @override
  State<_LandAreaStep> createState() => _LandAreaStepState();
}

class _LandAreaStepState extends State<_LandAreaStep> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.acres.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _LandAreaStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.acres != widget.acres &&
        _controller.text != widget.acres.toStringAsFixed(1)) {
      _controller.text = widget.acres.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acres = widget.acres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How much land do you farm?',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag the slider or enter area in acres',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${acres.toStringAsFixed(1)} acres',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Slider(
          value: acres,
          min: 0.5,
          max: 50,
          divisions: 99,
          label: '${acres.toStringAsFixed(1)} ac',
          onChanged: (v) {
            widget.onChanged(v);
            _controller.text = v.toStringAsFixed(1);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0.5 ac', style: theme.textTheme.bodySmall),
            Text('50 ac', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Or enter manually (acres)',
            suffixText: 'ac',
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null && parsed >= 0.5 && parsed <= 50) {
              widget.onChanged(parsed);
            }
          },
        ),
      ],
    );
  }
}

class _ChipSelectionStep extends StatelessWidget {
  const _ChipSelectionStep({
    required this.title,
    required this.options,
    required this.onSelected,
    this.selected,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = selected == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              showCheckmark: true,
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RadioSelectionStep extends StatelessWidget {
  const _RadioSelectionStep({
    required this.title,
    required this.options,
    required this.onSelected,
    this.selected,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        RadioGroup<String>(
          groupValue: selected,
          onChanged: (value) {
            if (value != null) onSelected(value);
          },
          child: Column(
            children: options.map((option) {
              final isSelected = selected == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => onSelected(option),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: RadioListTile<String>(
                        value: option,
                        title: Text(
                          option,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
