import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/async_error_view.dart';
import 'package:tilahan_saathi/models/activity.dart';
import 'package:tilahan_saathi/models/enums.dart';
import 'package:tilahan_saathi/models/oilseed_calendar.dart';
import 'package:tilahan_saathi/providers/calendar_provider.dart';
import 'package:tilahan_saathi/providers/oilseeds_provider.dart';

class OilseedCalendarScreen extends ConsumerStatefulWidget {
  const OilseedCalendarScreen({super.key, required this.landId, required this.oilseedId});

  final int landId;
  final int oilseedId;

  @override
  ConsumerState<OilseedCalendarScreen> createState() => _OilseedCalendarScreenState();
}

class _OilseedCalendarScreenState extends ConsumerState<OilseedCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isDeleting = false;

  CalendarKey get _key => (landId: widget.landId, oilseedId: widget.oilseedId);

  Future<void> _toggleActivity(Activity activity) async {
    try {
      await ref
          .read(calendarProvider(_key).notifier)
          .completeActivity(activity.id, completed: !activity.isCompleted);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error))),
        );
      }
    }
  }

  Future<void> _confirmDelete(OilseedCalendar calendar) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this crop?'),
        content: Text(
          'This will permanently remove ${calendar.crop.label} and its calendar from this land. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(oilseedsRepositoryProvider).deleteOilseed(widget.landId, widget.oilseedId);
      ref.invalidate(oilseedsForLandProvider(widget.landId));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error))),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarProvider(_key));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crop Calendar'),
        actions: [
          if (_isDeleting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            calendarAsync.maybeWhen(
              data: (calendar) => IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Remove crop',
                onPressed: () => _confirmDelete(calendar),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: SafeArea(
        child: calendarAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.invalidate(calendarProvider(_key)),
          ),
          data: _buildContent,
        ),
      ),
    );
  }

  Widget _buildContent(OilseedCalendar calendar) {
    final theme = Theme.of(context);
    final activities = calendar.activities;

    final allDates = <DateTime>[
      calendar.sowingDate,
      ...activities.expand((a) => [a.startDate, a.endDate]),
    ];
    final firstDay = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
    var lastDay = allDates.reduce((a, b) => a.isAfter(b) ? a : b);
    if (!lastDay.isAfter(firstDay.add(const Duration(days: 30)))) {
      lastDay = firstDay.add(const Duration(days: 180));
    }
    final focusedDay = _focusedDay.isBefore(firstDay)
        ? firstDay
        : (_focusedDay.isAfter(lastDay) ? lastDay : _focusedDay);

    final selectedDay = _selectedDay;
    final visibleActivities = selectedDay == null ? activities : calendar.activitiesOn(selectedDay);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: calendar.crop.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(calendar.crop.icon, color: calendar.crop.color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calendar.crop.label,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          calendar.stageAndDayLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: calendar.progress,
                        minHeight: 8,
                        backgroundColor: calendar.crop.color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(calendar.crop.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(calendar.progress * 100).round()}%',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(8),
          child: TableCalendar<Activity>(
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay, day),
            eventLoader: calendar.activitiesOn,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = isSameDay(_selectedDay, selected) ? null : selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Color(0x4D3FA34D), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDay == null ? 'All Tasks' : 'Tasks on ${_formatDate(selectedDay)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (selectedDay != null)
              TextButton(
                onPressed: () => setState(() => _selectedDay = null),
                child: const Text('Show All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleActivities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No tasks here.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...visibleActivities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityCard(activity: activity, onToggle: () => _toggleActivity(activity)),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onToggle});

  final Activity activity;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Checkbox(
            value: activity.isCompleted,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.primary,
          ),
          title: Text(
            activity.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: activity.isCompleted ? TextDecoration.lineThrough : null,
              color: activity.isCompleted ? AppColors.textSecondary : null,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(activity.category.icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  activity.category.label,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: _StatusBadge(status: activity.status),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PriorityBadge(priority: activity.priority),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatShortDate(activity.startDate)} – ${_formatShortDate(activity.endDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(activity.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    activity.guidance,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortDate(DateTime date) => '${date.day}/${date.month}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: status.color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final ActivityPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: priority.color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
