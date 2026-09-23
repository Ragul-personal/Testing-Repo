/// Template for a recurring daily task.
///
/// This is NOT a spaced-repetition item. It represents a fixed thing the user
/// wants to accomplish every day (e.g. "Engineering Mathematics", "Mock Test").
/// Templates are persistent: archiving one hides it from new days without
/// erasing the completion history it accumulated.
class DailyTaskTemplate {
  final String id;
  final String title;
  final String? description;

  /// Optional link to an existing [Subject]. Not required — a daily task can
  /// exist independently.
  final String? subjectId;
  final bool active;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? archivedAt;

  const DailyTaskTemplate({
    required this.id,
    required this.title,
    this.description,
    this.subjectId,
    required this.active,
    required this.sortOrder,
    required this.createdAt,
    this.archivedAt,
  });

  /// Supports clearing nullable fields via a `true` flag (e.g.
  /// `clearArchivedAt: true`).
  DailyTaskTemplate copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    String? subjectId,
    bool clearSubjectId = false,
    bool? active,
    int? sortOrder,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) {
    return DailyTaskTemplate(
      id: id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }
}

/// Record of a daily task's completion status for a specific calendar date.
///
/// The [date] is always stripped to midnight (year, month, day only) so that
/// "2026-09-23" identifies the same record regardless of the time of day.
///
/// There must be at most one completion record per (taskTemplateId, date) pair.
class DailyTaskCompletion {
  final String id;
  final String taskTemplateId;

  /// Calendar date with time zeroed out.
  final DateTime date;
  final bool completed;
  final DateTime? completedAt;

  DailyTaskCompletion({
    required this.id,
    required this.taskTemplateId,
    required DateTime date,
    required this.completed,
    this.completedAt,
  }) : date = DateTime(date.year, date.month, date.day);

  DailyTaskCompletion copyWith({
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return DailyTaskCompletion(
      id: id,
      taskTemplateId: taskTemplateId,
      date: date,
      completed: completed ?? this.completed,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
