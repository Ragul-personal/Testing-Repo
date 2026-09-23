import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_task.dart';
import 'daily_task_providers.dart';
import 'providers.dart';

class TaskAggregateProgress {
  final String taskId;
  final int totalScheduled;
  final int completed;
  double get percentage =>
      totalScheduled == 0 ? 0 : completed / totalScheduled * 100;
  const TaskAggregateProgress({
    required this.taskId,
    required this.totalScheduled,
    required this.completed,
  });
}

class DailyAggregateProgress {
  final List<DailyTaskDayRecord> dailyRecords;
  final List<TaskAggregateProgress> taskRecords;
  final int totalScheduled;
  final int completed;
  double get percentage =>
      totalScheduled == 0 ? 0 : completed / totalScheduled * 100;

  const DailyAggregateProgress({
    required this.dailyRecords,
    required this.taskRecords,
    required this.totalScheduled,
    required this.completed,
  });
}

/// Returns true if the template was scheduled (active/expected) on the given date.
bool isTaskScheduledOnDate(DailyTaskTemplate t, DateTime date) {
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

  if (t.createdAt.isAfter(endOfDay)) return false;
  if (t.archivedAt != null && t.archivedAt!.isBefore(startOfDay)) return false;
  return true;
}

/// Returns the templates that were scheduled on a given date.
final historicalScheduledTasksProvider =
    Provider.family<List<DailyTaskTemplate>, DateTime>((ref, date) {
  final allTemplates =
      ref.watch(dailyTaskTemplatesProvider).valueOrNull ?? const [];
  return allTemplates
      .where((t) => isTaskScheduledOnDate(t, date))
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// Returns completions for a given date, keyed by task ID.
final historicalCompletionsProvider =
    Provider.family<Map<String, DailyTaskCompletion>, DateTime>((ref, date) {
  final completions =
      ref.watch(dailyTaskCompletionsProvider).valueOrNull ?? const [];
  final map = <String, DailyTaskCompletion>{};
  for (final c in completions) {
    if (c.date.year == date.year &&
        c.date.month == date.month &&
        c.date.day == date.day) {
      map[c.taskTemplateId] = c;
    }
  }
  return map;
});

/// Returns the progress summary for a specific date.
final historicalProgressProvider =
    Provider.family<DailyTaskDayRecord, DateTime>((ref, date) {
  final tasks = ref.watch(historicalScheduledTasksProvider(date));
  final completions = ref.watch(historicalCompletionsProvider(date));

  final total = tasks.length;
  final completed =
      tasks.where((t) => completions[t.id]?.completed == true).length;

  return DailyTaskDayRecord(
    date: date,
    total: total,
    completed: completed,
  );
});

/// Returns the last N days of progress.
final dailyTaskHistoryDaysProvider =
    Provider.family<List<DailyTaskDayRecord>, int>((ref, days) {
  final today = ref.watch(currentDayProvider);
  final records = <DailyTaskDayRecord>[];
  for (int i = days - 1; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    records.add(ref.watch(historicalProgressProvider(date)));
  }
  return records;
});

/// Calculates the streak for a specific task.
/// A task's streak increments when completed on consecutive scheduled days.
final taskStreakProvider = Provider.family<int, String>((ref, taskId) {
  final allTemplates =
      ref.watch(dailyTaskTemplatesProvider).valueOrNull ?? const [];
  final template = allTemplates.where((t) => t.id == taskId).firstOrNull;
  if (template == null) return 0;

  final allCompletions =
      ref.watch(dailyTaskCompletionsProvider).valueOrNull ?? const [];
  final completions =
      allCompletions.where((c) => c.taskTemplateId == taskId).toList();

  final today = ref.watch(currentDayProvider);

  var streak = 0;
  for (int i = 0;; i++) {
    final date = today.subtract(Duration(days: i));

    if (!isTaskScheduledOnDate(template, date)) {
      if (template.createdAt.isAfter(DateTime(date.year, date.month, date.day, 23, 59, 59))) {
        break; // reached before creation
      }
      continue; // skip unscheduled days (e.g. while archived)
    }

    final c = completions.where((c) =>
        c.date.year == date.year &&
        c.date.month == date.month &&
        c.date.day == date.day).firstOrNull;

    if (c != null && c.completed) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
});

/// Calculates progress for a specific range of dates.
final aggregateProgressProvider =
    Provider.family<DailyAggregateProgress, List<DateTime>>((ref, dates) {
  final dailyRecords = <DailyTaskDayRecord>[];
  final taskMap = <String, TaskAggregateProgress>{};
  
  var totalRangeScheduled = 0;
  var totalRangeCompleted = 0;

  for (final date in dates) {
    final daily = ref.watch(historicalProgressProvider(date));
    dailyRecords.add(daily);
    
    totalRangeScheduled += daily.total;
    totalRangeCompleted += daily.completed;

    final tasks = ref.watch(historicalScheduledTasksProvider(date));
    final completions = ref.watch(historicalCompletionsProvider(date));
    
    for (final t in tasks) {
      final isCompleted = completions[t.id]?.completed == true;
      final existing = taskMap[t.id] ??
          TaskAggregateProgress(
            taskId: t.id,
            totalScheduled: 0,
            completed: 0,
          );
      taskMap[t.id] = TaskAggregateProgress(
        taskId: t.id,
        totalScheduled: existing.totalScheduled + 1,
        completed: existing.completed + (isCompleted ? 1 : 0),
      );
    }
  }

  return DailyAggregateProgress(
    dailyRecords: dailyRecords,
    taskRecords: taskMap.values.toList(),
    totalScheduled: totalRangeScheduled,
    completed: totalRangeCompleted,
  );
});
