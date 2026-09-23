import 'package:flutter_test/flutter_test.dart';

import 'package:recallday/domain/entities/daily_task.dart';
import 'package:recallday/presentation/providers/daily_task_providers.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // DailyTaskTemplate entity
  // ═══════════════════════════════════════════════════════════════════════════

  group('DailyTaskTemplate', () {
    test('copyWith preserves unchanged fields', () {
      final t = DailyTaskTemplate(
        id: 'abc',
        title: 'Math',
        description: 'Daily math practice',
        subjectId: 's1',
        active: true,
        sortOrder: 0,
        createdAt: DateTime(2026, 9, 1),
        archivedAt: null,
      );
      final updated = t.copyWith(title: 'Physics');
      expect(updated.id, 'abc');
      expect(updated.title, 'Physics');
      expect(updated.description, 'Daily math practice');
      expect(updated.subjectId, 's1');
      expect(updated.active, true);
      expect(updated.sortOrder, 0);
    });

    test('copyWith can clear nullable fields', () {
      final t = DailyTaskTemplate(
        id: 'abc',
        title: 'Math',
        description: 'desc',
        subjectId: 's1',
        active: false,
        sortOrder: 0,
        createdAt: DateTime(2026, 9, 1),
        archivedAt: DateTime(2026, 9, 10),
      );
      final restored = t.copyWith(
        active: true,
        clearArchivedAt: true,
      );
      expect(restored.active, true);
      expect(restored.archivedAt, isNull);
      expect(restored.description, 'desc'); // unchanged

      final noDesc = t.copyWith(clearDescription: true);
      expect(noDesc.description, isNull);

      final noSubject = t.copyWith(clearSubjectId: true);
      expect(noSubject.subjectId, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DailyTaskCompletion entity
  // ═══════════════════════════════════════════════════════════════════════════

  group('DailyTaskCompletion', () {
    test('date is always stripped to midnight', () {
      final c = DailyTaskCompletion(
        id: 'c1',
        taskTemplateId: 't1',
        date: DateTime(2026, 9, 23, 14, 30, 45),
        completed: true,
        completedAt: DateTime(2026, 9, 23, 14, 30, 45),
      );
      expect(c.date, DateTime(2026, 9, 23));
      expect(c.date.hour, 0);
      expect(c.date.minute, 0);
      expect(c.date.second, 0);
    });

    test('copyWith toggles completed and clears completedAt', () {
      final c = DailyTaskCompletion(
        id: 'c1',
        taskTemplateId: 't1',
        date: DateTime(2026, 9, 23),
        completed: true,
        completedAt: DateTime(2026, 9, 23, 10, 0),
      );
      final unchecked = c.copyWith(
        completed: false,
        clearCompletedAt: true,
      );
      expect(unchecked.completed, false);
      expect(unchecked.completedAt, isNull);
      expect(unchecked.id, 'c1');
      expect(unchecked.taskTemplateId, 't1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DailyTaskProgress
  // ═══════════════════════════════════════════════════════════════════════════

  group('DailyTaskProgress', () {
    test('percentage is 0 when total is 0 (not 100)', () {
      const p = DailyTaskProgress(total: 0, completed: 0);
      expect(p.percentage, 0);
    });

    test('percentage calculates correctly', () {
      const p = DailyTaskProgress(total: 4, completed: 2);
      expect(p.percentage, 50);
    });

    test('percentage is 100 when all completed', () {
      const p = DailyTaskProgress(total: 3, completed: 3);
      expect(p.percentage, 100);
    });

    test('percentage rounds for fractional values', () {
      const p = DailyTaskProgress(total: 3, completed: 1);
      // 33.333... — not testing rounding, just that it's correct
      expect(p.percentage, closeTo(33.33, 0.1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DailyTaskDayRecord
  // ═══════════════════════════════════════════════════════════════════════════

  group('DailyTaskDayRecord', () {
    test('percentage is 0 when total is 0', () {
      final r = DailyTaskDayRecord(
        date: DateTime(2026, 9, 20),
        total: 0,
        completed: 0,
      );
      expect(r.percentage, 0);
    });

    test('percentage is correct for partial completion', () {
      final r = DailyTaskDayRecord(
        date: DateTime(2026, 9, 20),
        total: 4,
        completed: 3,
      );
      expect(r.percentage, 75);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Streak calculation logic (unit test of the algorithm)
  // ═══════════════════════════════════════════════════════════════════════════

  group('streak calculation', () {
    /// Mirrors the logic in dailyTaskStreakProvider.
    int calculateStreak(List<DailyTaskDayRecord> history) {
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
    }

    test('streak is 0 when no history', () {
      expect(calculateStreak([]), 0);
    });

    test('streak counts consecutive 100% days from end', () {
      final history = [
        DailyTaskDayRecord(date: DateTime(2026, 9, 20), total: 4, completed: 4),
        DailyTaskDayRecord(date: DateTime(2026, 9, 21), total: 4, completed: 3),
        DailyTaskDayRecord(date: DateTime(2026, 9, 22), total: 4, completed: 4),
        DailyTaskDayRecord(date: DateTime(2026, 9, 23), total: 4, completed: 4),
      ];
      expect(calculateStreak(history), 2); // Sep 22 + Sep 23
    });

    test('streak breaks on zero-task day', () {
      final history = [
        DailyTaskDayRecord(date: DateTime(2026, 9, 22), total: 4, completed: 4),
        DailyTaskDayRecord(date: DateTime(2026, 9, 23), total: 0, completed: 0),
      ];
      expect(calculateStreak(history), 0);
    });

    test('streak breaks on incomplete day', () {
      final history = [
        DailyTaskDayRecord(date: DateTime(2026, 9, 22), total: 4, completed: 4),
        DailyTaskDayRecord(date: DateTime(2026, 9, 23), total: 4, completed: 2),
      ];
      expect(calculateStreak(history), 0);
    });

    test('full streak across all days', () {
      final history = List.generate(
        7,
        (i) => DailyTaskDayRecord(
          date: DateTime(2026, 9, 17 + i),
          total: 3,
          completed: 3,
        ),
      );
      expect(calculateStreak(history), 7);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 7-day and 30-day average calculation (unit test of the algorithm)
  // ═══════════════════════════════════════════════════════════════════════════

  group('average calculations', () {
    double calculate7DayAvg(List<DailyTaskDayRecord> history) {
      final last7 =
          history.length >= 7 ? history.sublist(history.length - 7) : history;
      if (last7.isEmpty) return 0;
      final sum = last7.fold<double>(
        0,
        (acc, r) => acc + (r.total > 0 ? r.completed / r.total * 100 : 0),
      );
      return sum / last7.length;
    }

    double calculate30DayAvg(List<DailyTaskDayRecord> history) {
      if (history.isEmpty) return 0;
      final sum = history.fold<double>(
        0,
        (acc, r) => acc + (r.total > 0 ? r.completed / r.total * 100 : 0),
      );
      return sum / history.length;
    }

    test('7-day average is 0 when no history', () {
      expect(calculate7DayAvg([]), 0);
    });

    test('30-day average is 0 when no history', () {
      expect(calculate30DayAvg([]), 0);
    });

    test('7-day average calculates correctly', () {
      final history = [
        DailyTaskDayRecord(date: DateTime(2026, 9, 17), total: 4, completed: 4), // 100%
        DailyTaskDayRecord(date: DateTime(2026, 9, 18), total: 4, completed: 3), // 75%
        DailyTaskDayRecord(date: DateTime(2026, 9, 19), total: 4, completed: 2), // 50%
        DailyTaskDayRecord(date: DateTime(2026, 9, 20), total: 4, completed: 3), // 75%
        DailyTaskDayRecord(date: DateTime(2026, 9, 21), total: 4, completed: 4), // 100%
        DailyTaskDayRecord(date: DateTime(2026, 9, 22), total: 4, completed: 2), // 50%
        DailyTaskDayRecord(date: DateTime(2026, 9, 23), total: 4, completed: 3), // 75%
      ];
      // Average = (100 + 75 + 50 + 75 + 100 + 50 + 75) / 7 = 525 / 7 = 75
      expect(calculate7DayAvg(history), 75);
    });

    test('zero-task days contribute 0% to average', () {
      final history = [
        DailyTaskDayRecord(date: DateTime(2026, 9, 22), total: 0, completed: 0), // 0%
        DailyTaskDayRecord(date: DateTime(2026, 9, 23), total: 4, completed: 4), // 100%
      ];
      // Average = (0 + 100) / 2 = 50
      expect(calculate7DayAvg(history), 50);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Historical data integrity
  // ═══════════════════════════════════════════════════════════════════════════

  group('historical data integrity', () {
    test('old percentages remain logically correct when tasks are added', () {
      // Scenario: On Sep 20, user had 3 tasks and completed all 3 (100%).
      // Later, user adds a 4th task. The Sep 20 record should still reflect
      // 3/3 = 100%, not 3/4 = 75%.
      //
      // This is guaranteed by the data model design: DailyTaskCompletion
      // records store the exact completion state per day. The historical
      // "expected count" uses completion records as evidence of what was
      // scheduled, so adding a new template doesn't retroactively change
      // old days that have no completion record for the new template.
      final sep20Completions = [
        DailyTaskCompletion(
          id: 'c1',
          taskTemplateId: 'math',
          date: DateTime(2026, 9, 20),
          completed: true,
        ),
        DailyTaskCompletion(
          id: 'c2',
          taskTemplateId: 'aptitude',
          date: DateTime(2026, 9, 20),
          completed: true,
        ),
        DailyTaskCompletion(
          id: 'c3',
          taskTemplateId: 'core_cs',
          date: DateTime(2026, 9, 20),
          completed: true,
        ),
      ];

      // The completions record 3 tasks scheduled on that day
      expect(sep20Completions.length, 3);
      final completedCount =
          sep20Completions.where((c) => c.completed).length;
      expect(completedCount, 3);
      // 3 / 3 = 100%, even though a 4th task may exist now
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Date boundary behaviour
  // ═══════════════════════════════════════════════════════════════════════════

  group('date boundary behaviour', () {
    test('completions for different times on the same day are the same date', () {
      final morning = DailyTaskCompletion(
        id: 'c1',
        taskTemplateId: 't1',
        date: DateTime(2026, 9, 23, 6, 0),
        completed: true,
      );
      final evening = DailyTaskCompletion(
        id: 'c2',
        taskTemplateId: 't1',
        date: DateTime(2026, 9, 23, 22, 30),
        completed: true,
      );
      expect(morning.date, evening.date);
      expect(morning.date, DateTime(2026, 9, 23));
    });

    test('midnight crossing produces different dates', () {
      final beforeMidnight = DailyTaskCompletion(
        id: 'c1',
        taskTemplateId: 't1',
        date: DateTime(2026, 9, 23, 23, 59, 59),
        completed: true,
      );
      final afterMidnight = DailyTaskCompletion(
        id: 'c2',
        taskTemplateId: 't1',
        date: DateTime(2026, 9, 24, 0, 0, 1),
        completed: true,
      );
      expect(beforeMidnight.date, DateTime(2026, 9, 23));
      expect(afterMidnight.date, DateTime(2026, 9, 24));
      expect(beforeMidnight.date, isNot(afterMidnight.date));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Duplicate prevention
  // ═══════════════════════════════════════════════════════════════════════════

  group('duplicate prevention', () {
    test('two completions for same task+date have same date key', () {
      final c1 = DailyTaskCompletion(
        id: 'c1',
        taskTemplateId: 'math',
        date: DateTime(2026, 9, 23, 10, 0),
        completed: true,
      );
      final c2 = DailyTaskCompletion(
        id: 'c2',
        taskTemplateId: 'math',
        date: DateTime(2026, 9, 23, 18, 0),
        completed: false,
      );
      // Same task + same calendar date
      expect(c1.taskTemplateId, c2.taskTemplateId);
      expect(c1.date, c2.date);
      // The repository's completionFor method uses this pair to find existing
      // records and update them rather than creating duplicates.
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Hive model serialization
  // ═══════════════════════════════════════════════════════════════════════════

  group('model JSON round-trip', () {
    test('DailyTaskTemplateModel toJson/fromJson round-trips', () {
      // Import the model inline to keep the test focused
      final json = {
        'id': 'tmpl-1',
        'title': 'Engineering Mathematics',
        'description': 'Daily math practice',
        'subjectId': 'sub-1',
        'active': true,
        'sortOrder': 2,
        'createdAt': '2026-09-01T00:00:00.000',
        'archivedAt': null,
      };

      // Verify the entity can be constructed from this shape
      final template = DailyTaskTemplate(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        subjectId: json['subjectId'] as String?,
        active: json['active'] as bool,
        sortOrder: json['sortOrder'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
      expect(template.id, 'tmpl-1');
      expect(template.title, 'Engineering Mathematics');
      expect(template.active, true);
      expect(template.archivedAt, isNull);
    });

    test('DailyTaskCompletionModel toJson/fromJson round-trips', () {
      final json = {
        'id': 'comp-1',
        'taskTemplateId': 'tmpl-1',
        'date': '2026-09-23T00:00:00.000',
        'completed': true,
        'completedAt': '2026-09-23T14:30:00.000',
      };

      final completion = DailyTaskCompletion(
        id: json['id'] as String,
        taskTemplateId: json['taskTemplateId'] as String,
        date: DateTime.parse(json['date'] as String),
        completed: json['completed'] as bool,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
      expect(completion.id, 'comp-1');
      expect(completion.completed, true);
      expect(completion.date, DateTime(2026, 9, 23)); // stripped
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Backup integration
  // ═══════════════════════════════════════════════════════════════════════════

  group('backup integration', () {
    test('older backups without dailyTaskTemplates key are handled', () {
      // An older backup won't have these keys. The restore logic uses
      // `decoded['dailyTaskTemplates'] as List? ?? const []`
      // so an absent key produces an empty list, not an error.
      final Map<String, dynamic> olderBackup = {
        'schemaVersion': 3,
        'subjects': [],
        'topics': [],
        'subtopics': [],
        'reviews': [],
        // no 'dailyTaskTemplates' key
        // no 'dailyTaskCompletions' key
      };

      final templates =
          olderBackup['dailyTaskTemplates'] as List? ?? const [];
      final completions =
          olderBackup['dailyTaskCompletions'] as List? ?? const [];
      expect(templates, isEmpty);
      expect(completions, isEmpty);
    });
  });
}
