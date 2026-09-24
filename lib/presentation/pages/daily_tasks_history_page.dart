import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../providers/daily_task_providers.dart';
import '../providers/daily_task_analytics_providers.dart';
import '../widgets/empty_state.dart';

/// Historical progress screen with Day / Week / Month modes.
class DailyTasksHistoryPage extends ConsumerStatefulWidget {
  final String initialMode; // 'day', 'week', 'month'
  final DateTime initialDate;

  const DailyTasksHistoryPage({
    super.key,
    required this.initialMode,
    required this.initialDate,
  });

  @override
  ConsumerState<DailyTasksHistoryPage> createState() =>
      _DailyTasksHistoryPageState();
}

class _DailyTasksHistoryPageState extends ConsumerState<DailyTasksHistoryPage> {
  late String _mode;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  void _previous() {
    setState(() {
      if (_mode == 'day') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      } else if (_mode == 'week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else if (_mode == 'month') {
        _selectedDate =
            DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
      }
    });
  }

  void _next() {
    setState(() {
      if (_mode == 'day') {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      } else if (_mode == 'week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else if (_mode == 'month') {
        _selectedDate =
            DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      }
    });
  }

  List<DateTime> _getWeekDates(DateTime date) {
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  List<DateTime> _getMonthDates(DateTime date) {
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    return List.generate(
      daysInMonth,
      (i) => DateTime(date.year, date.month, i + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historical Progress'),
      ),
      body: Column(
        children: [
          // Segmented control
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'day', label: Text('Day')),
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'month', label: Text('Month')),
              ],
              selected: {_mode},
              onSelectionChanged: (set) {
                setState(() => _mode = set.first);
              },
            ),
          ),

          // Date selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _previous,
                ),
                Expanded(
                  child: Text(
                    _formatDateTitle(),
                    textAlign: TextAlign.center,
                    style:
                        tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _next,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  String _formatDateTitle() {
    if (_mode == 'day') {
      return DateLabels.fullDate(_selectedDate);
    }
    if (_mode == 'week') {
      final dates = _getWeekDates(_selectedDate);
      final formatter = DateFormat('MMM');
      return '${dates.first.day} ${formatter.format(dates.first)} – '
          '${dates.last.day} ${formatter.format(dates.last)}';
    }
    return DateFormat('MMMM yyyy').format(_selectedDate);
  }

  Widget _buildContent() {
    if (_mode == 'day') {
      return _buildDayView();
    }
    if (_mode == 'week') {
      return _buildWeekView();
    }
    return _buildMonthView();
  }

  Widget _buildDayView() {
    final tasks = ref.watch(historicalScheduledTasksProvider(_selectedDate));
    final progress = ref.watch(historicalProgressProvider(_selectedDate));
    final completions = ref.watch(historicalCompletionsProvider(_selectedDate));
    final commands = ref.read(dailyTaskCommandsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No tasks scheduled',
        subtitle: 'No tasks were active on this date.',
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress.total > 0
                            ? progress.completed / progress.total
                            : 0,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: cs.primary,
                      ),
                      Text(
                        '${progress.percentage.round()}%',
                        style: tt.labelSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${progress.completed} / ${progress.total} completed',
                  style: tt.titleMedium,
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = tasks[index];
              final done = completions[task.id]?.completed == true;
              final streak = ref.watch(taskStreakProvider(task.id));

              return ListTile(
                leading: Icon(
                  done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: done ? cs.primary : cs.outline,
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: streak > 0 ? Text('🔥 $streak day streak') : null,
                onTap: () {
                  commands.toggleCompletion(
                    taskTemplateId: task.id,
                    date: _selectedDate,
                  );
                },
              );
            },
            childCount: tasks.length,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    final dates = _getWeekDates(_selectedDate);
    return _buildAggregateList(dates, 'Week');
  }

  Widget _buildMonthView() {
    final dates = _getMonthDates(_selectedDate);
    return _buildAggregateList(dates, 'Month');
  }

  Widget _buildAggregateList(List<DateTime> dates, String label) {
    final agg = ref.watch(aggregateProgressProvider(dates));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (agg.taskRecords.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_graph_rounded,
        title: 'No data',
        subtitle: 'No tasks were scheduled during this period.',
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Text(
                    'Overall Progress',
                    style: tt.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${agg.percentage.round()}%',
                    style: tt.headlineMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${agg.completed} / ${agg.totalScheduled} tasks',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final rec = agg.taskRecords[index];
              final allTemplates =
                  ref.watch(dailyTaskTemplatesProvider).valueOrNull ?? [];
              final t =
                  allTemplates.where((x) => x.id == rec.taskId).firstOrNull;
              if (t == null) return const SizedBox.shrink();

              return ListTile(
                title: Text(t.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${rec.percentage.round()}%',
                      style: tt.titleMedium?.copyWith(color: cs.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () {
                  _showTaskDrillDown(context, t.id, t.title, dates);
                },
              );
            },
            childCount: agg.taskRecords.length,
          ),
        ),
      ],
    );
  }

  void _showTaskDrillDown(
      BuildContext context, String taskId, String title, List<DateTime> dates) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TaskDrillDownSheet(
        taskId: taskId,
        title: title,
        dates: dates,
      ),
    );
  }
}

class _TaskDrillDownSheet extends ConsumerWidget {
  final String taskId;
  final String title;
  final List<DateTime> dates;

  const _TaskDrillDownSheet({
    required this.taskId,
    required this.title,
    required this.dates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commands = ref.read(dailyTaskCommandsProvider);
    final cs = Theme.of(context).colorScheme;
    final formatter = DateFormat('E, MMM d');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isScheduled =
                      ref.watch(isTaskScheduledOnDateProvider(taskId, date));

                  if (!isScheduled) return const SizedBox.shrink();

                  final completions =
                      ref.watch(historicalCompletionsProvider(date));
                  final done = completions[taskId]?.completed == true;

                  return ListTile(
                    leading: Icon(
                      done ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: done ? cs.primary : cs.outline,
                    ),
                    title: Text(formatter.format(date)),
                    onTap: () {
                      commands.toggleCompletion(
                        taskTemplateId: taskId,
                        date: date,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
