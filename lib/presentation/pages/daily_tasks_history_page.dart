import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../providers/daily_task_analytics_providers.dart';
import '../providers/daily_task_providers.dart';
import '../providers/providers.dart';
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
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
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
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      }
    });
  }

  List<DateTime> _getWeekDates(DateTime date) {
    // Assuming Monday is start of week
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
    final cs = Theme.of(context).colorScheme;
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
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    } else if (_mode == 'week') {
      final dates = _getWeekDates(_selectedDate);
      return '${dates.first.day} ${DateLabels.monthAbbr(dates.first)} – ${dates.last.day} ${DateLabels.monthAbbr(dates.last)}';
    } else {
      return '${DateLabels.monthFull(_selectedDate)} ${_selectedDate.year}';
    }
  }

  Widget _buildContent() {
    if (_mode == 'day') return _buildDayView();
    if (_mode == 'week') return _buildAggregateView(_getWeekDates(_selectedDate));
    return _buildAggregateView(_getMonthDates(_selectedDate));
  }

  Widget _buildDayView() {
    final tasks = ref.watch(historicalScheduledTasksProvider(_selectedDate));
    final progress = ref.watch(historicalProgressProvider(_selectedDate));
    final completions = ref.watch(historicalCompletionsProvider(_selectedDate));
    final commands = ref.read(dailyTaskCommandsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (tasks.isEmpty) {
      return EmptyState(
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
                        style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold),
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
                subtitle: streak > 1
                    ? Text('🔥 $streak day streak')
                    : null,
                onTap: () {
                  commands.toggleCompletion(
                    taskTemplateId: task.id,
                    date: _selectedDate,
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.bar_chart_rounded),
                  onPressed: () {
                    // Navigate to task specific history
                    context.push('/daily-tasks/history/task/${task.id}');
                  },
                ),
              );
            },
            childCount: tasks.length,
          ),
        ),
      ],
    );
  }

  Widget _buildAggregateView(List<DateTime> dates) {
    final agg = ref.watch(aggregateProgressProvider(dates));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (agg.taskRecords.isEmpty) {
      return EmptyState(
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
              // To get task title we need all templates.
              final allTemplates = ref.watch(dailyTaskTemplatesProvider).valueOrNull ?? [];
              final t = allTemplates.where((x) => x.id == rec.taskId).firstOrNull;
              if (t == null) return const SizedBox.shrink();

              return ListTile(
                title: Text(t.title),
                subtitle: Text(
                  '${rec.completed} / ${rec.totalScheduled} scheduled days',
                ),
                trailing: Text(
                  '${rec.percentage.round()}%',
                  style: tt.titleMedium?.copyWith(color: cs.primary),
                ),
                onTap: () {
                  context.push('/daily-tasks/history/task/${t.id}');
                },
              );
            },
            childCount: agg.taskRecords.length,
          ),
        ),
      ],
    );
  }
}
