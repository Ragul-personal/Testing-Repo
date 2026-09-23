import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/daily_task_repository_impl.dart';
import '../../domain/entities/daily_task.dart';
import '../../domain/repositories/daily_task_repository.dart';
import 'providers.dart';

/// Re-exported so screens need a single import for both read and write.
export 'daily_task_commands.dart';

// ═════════════════════════════════════════════════════════════════════════════
// READ-ONLY providers for the Daily Tasks module.
//
// All writes live in DailyTaskCommands (daily_task_commands.dart), which is
// re-exported above.
// ═════════════════════════════════════════════════════════════════════════════

// ---------- helper types ----------

class DailyTaskProgress {
  final int total;
  final int completed;
  double get percentage => total == 0 ? 0 : completed / total * 100;
  const DailyTaskProgress({required this.total, required this.completed});
}

class DailyTaskDayRecord {
  final DateTime date;
  final int total;
  final int completed;
  double get percentage => total == 0 ? 0 : completed / total * 100;
  const DailyTaskDayRecord({
    required this.date,
    required this.total,
    required this.completed,
  });
}

// ---------- repository ----------

final dailyTaskRepositoryProvider = Provider<DailyTaskRepository>(
  (_) => DailyTaskRepositoryImpl(),
);

// ---------- streams ----------

final dailyTaskTemplatesProvider = StreamProvider<List<DailyTaskTemplate>>(
  (ref) => ref.watch(dailyTaskRepositoryProvider).watchTemplates(),
);

final dailyTaskCompletionsProvider =
    StreamProvider<List<DailyTaskCompletion>>(
  (ref) => ref.watch(dailyTaskRepositoryProvider).watchCompletions(),
);

// ---------- derived ----------

/// Active templates only, sorted by user order.
final activeDailyTasksProvider = Provider<List<DailyTaskTemplate>>((ref) {
  final all = ref.watch(dailyTaskTemplatesProvider).valueOrNull ?? const [];
  return all.where((t) => t.active).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// Today's completions keyed by template id for O(1) lookup.
final todayCompletionsProvider =
    Provider<Map<String, DailyTaskCompletion>>((ref) {
  final today = ref.watch(currentDayProvider);
  final completions =
      ref.watch(dailyTaskCompletionsProvider).valueOrNull ?? const [];
  final map = <String, DailyTaskCompletion>{};
  for (final c in completions) {
    if (c.date.year == today.year &&
        c.date.month == today.month &&
        c.date.day == today.day) {
      map[c.taskTemplateId] = c;
    }
  }
  return map;
});

/// Today's progress: completed / total with percentage.
final dailyTaskProgressProvider = Provider<DailyTaskProgress>((ref) {
  final tasks = ref.watch(activeDailyTasksProvider);
  final completions = ref.watch(todayCompletionsProvider);
  final total = tasks.length;
  final completed =
      tasks.where((t) => completions[t.id]?.completed == true).length;
  return DailyTaskProgress(total: total, completed: completed);
});

/// Last 30 days of daily completion history.
///
/// Historical percentages are logically correct:
/// - Completion records serve as evidence of tasks that were scheduled on that
///   day (even if the template has since been archived).
/// - Active templates created on or before that date are also counted as
///   scheduled.
/// This means archiving or adding a task does NOT rewrite old percentages.
final dailyTaskHistoryProvider = Provider<List<DailyTaskDayRecord>>((ref) {
  final today = ref.watch(currentDayProvider);
  final allCompletions =
      ref.watch(dailyTaskCompletionsProvider).valueOrNull ?? const [];
  final allTemplates =
      ref.watch(dailyTaskTemplatesProvider).valueOrNull ?? const [];

  final records = <DailyTaskDayRecord>[];
  for (int i = 29; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final dayCompletions = allCompletions.where((c) =>
        c.date.year == date.year &&
        c.date.month == date.month &&
        c.date.day == date.day);

    // The set of tasks that were "scheduled" on this date:
    // 1. Any task that has a completion record for this day (historical proof).
    // 2. Any currently active template created on or before this date.
    final scheduledIds = <String>{};
    for (final c in dayCompletions) {
      scheduledIds.add(c.taskTemplateId);
    }
    for (final t in allTemplates) {
      final endOfDate =
          DateTime(date.year, date.month, date.day, 23, 59, 59);
      if (t.active && !t.createdAt.isAfter(endOfDate)) {
        scheduledIds.add(t.id);
      }
    }

    final total = scheduledIds.length;
    final completed = dayCompletions.where((c) => c.completed).length;

    records.add(DailyTaskDayRecord(
      date: date,
      total: total,
      completed: completed,
    ));
  }
  return records;
});

/// Consecutive days of 100% completion, counting back from today.
///
/// Design decision: a "successful day" is defined as 100% completion of all
/// scheduled tasks. Days with zero tasks break the streak. This is a
/// separate metric from the spaced-repetition streak in [streakDaysProvider].
final dailyTaskStreakProvider = Provider<int>((ref) {
  final history = ref.watch(dailyTaskHistoryProvider);
  var streak = 0;
  for (int i = history.length - 1; i >= 0; i--) {
    final r = history[i];
    if (r.total == 0) break;
    if (r.completed == r.total) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

/// 7-day average completion percentage.
final dailyTask7DayAvgProvider = Provider<double>((ref) {
  final history = ref.watch(dailyTaskHistoryProvider);
  final last7 =
      history.length >= 7 ? history.sublist(history.length - 7) : history;
  if (last7.isEmpty) return 0;
  final sum = last7.fold<double>(
    0,
    (acc, r) => acc + (r.total > 0 ? r.completed / r.total * 100 : 0),
  );
  return sum / last7.length;
});

/// 30-day average completion percentage.
final dailyTask30DayAvgProvider = Provider<double>((ref) {
  final history = ref.watch(dailyTaskHistoryProvider);
  if (history.isEmpty) return 0;
  final sum = history.fold<double>(
    0,
    (acc, r) => acc + (r.total > 0 ? r.completed / r.total * 100 : 0),
  );
  return sum / history.length;
});
