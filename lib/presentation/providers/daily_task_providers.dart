import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/daily_task_repository_impl.dart';
import '../../domain/entities/daily_task.dart';
import '../../domain/repositories/daily_task_repository.dart';
import 'providers.dart';

/// Re-exported so screens need a single import for both read and write.
export 'daily_task_analytics_providers.dart';
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

final dailyTaskCompletionsProvider = StreamProvider<List<DailyTaskCompletion>>(
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
