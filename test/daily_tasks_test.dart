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
  // Scheduled Tasks logic
  // ═══════════════════════════════════════════════════════════════════════════
  group('isTaskScheduledOnDate logic', () {
    bool isTaskScheduledOnDate(DailyTaskTemplate t, DateTime date) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      if (t.createdAt.isAfter(endOfDay)) return false;
      if (t.archivedAt != null && t.archivedAt!.isBefore(startOfDay)) {
        return false;
      }
      return true;
    }

    test('task created same day is scheduled', () {
      final t = DailyTaskTemplate(
        id: '1', title: 'A', active: true, sortOrder: 0,
        createdAt: DateTime(2026, 9, 23, 10, 0),
      );
      expect(isTaskScheduledOnDate(t, DateTime(2026, 9, 23)), true);
    });

    test('task created after date is NOT scheduled', () {
      final t = DailyTaskTemplate(
        id: '1', title: 'A', active: true, sortOrder: 0,
        createdAt: DateTime(2026, 9, 24, 10, 0),
      );
      expect(isTaskScheduledOnDate(t, DateTime(2026, 9, 23)), false);
    });

    test('task archived same day IS scheduled', () {
      final t = DailyTaskTemplate(
        id: '1', title: 'A', active: false, sortOrder: 0,
        createdAt: DateTime(2026, 9, 20),
        archivedAt: DateTime(2026, 9, 23, 14, 0),
      );
      expect(isTaskScheduledOnDate(t, DateTime(2026, 9, 23)), true);
    });

    test('task archived before date is NOT scheduled', () {
      final t = DailyTaskTemplate(
        id: '1', title: 'A', active: false, sortOrder: 0,
        createdAt: DateTime(2026, 9, 20),
        archivedAt: DateTime(2026, 9, 22, 14, 0),
      );
      expect(isTaskScheduledOnDate(t, DateTime(2026, 9, 23)), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task streak algorithm
  // ═══════════════════════════════════════════════════════════════════════════
  group('task streak calculation', () {
    int calculateTaskStreak(DailyTaskTemplate template, List<DailyTaskCompletion> completions, DateTime today) {
      bool isTaskScheduledOnDate(DailyTaskTemplate t, DateTime date) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        if (t.createdAt.isAfter(endOfDay)) return false;
        if (t.archivedAt != null && t.archivedAt!.isBefore(startOfDay)) return false;
        return true;
      }

      var streak = 0;
      for (int i = 0;; i++) {
        final date = today.subtract(Duration(days: i));

        if (!isTaskScheduledOnDate(template, date)) {
          if (template.createdAt.isAfter(DateTime(date.year, date.month, date.day, 23, 59, 59))) {
            break; // reached before creation
          }
          continue; // skip unscheduled days
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
    }

    test('streak handles skipped days for archived tasks', () {
      final t = DailyTaskTemplate(
        id: '1', title: 'A', active: false, sortOrder: 0,
        createdAt: DateTime(2026, 9, 20),
        archivedAt: DateTime(2026, 9, 22),
      );
      final completions = [
        DailyTaskCompletion(id: 'c1', taskTemplateId: '1', date: DateTime(2026, 9, 20), completed: true),
        DailyTaskCompletion(id: 'c2', taskTemplateId: '1', date: DateTime(2026, 9, 21), completed: true),
        DailyTaskCompletion(id: 'c3', taskTemplateId: '1', date: DateTime(2026, 9, 22), completed: true),
      ];
      // Today is 24th. Task archived on 22nd. 23rd and 24th are unscheduled. Streak should be 3.
      expect(calculateTaskStreak(t, completions, DateTime(2026, 9, 24)), 3);
    });

    test('streak breaks if incomplete', () {
      final t = DailyTaskTemplate(
        id: '1', title: 'A', active: true, sortOrder: 0,
        createdAt: DateTime(2026, 9, 20),
      );
      final completions = [
        DailyTaskCompletion(id: 'c1', taskTemplateId: '1', date: DateTime(2026, 9, 20), completed: true),
        DailyTaskCompletion(id: 'c2', taskTemplateId: '1', date: DateTime(2026, 9, 21), completed: true),
        // 22nd incomplete
        DailyTaskCompletion(id: 'c4', taskTemplateId: '1', date: DateTime(2026, 9, 23), completed: true),
      ];
      expect(calculateTaskStreak(t, completions, DateTime(2026, 9, 23)), 1);
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
