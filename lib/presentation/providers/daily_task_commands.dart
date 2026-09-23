import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/daily_task.dart';
import '../../domain/repositories/daily_task_repository.dart';
import '../../services/backup_service.dart';
import 'daily_task_providers.dart';

/// Write-side commands for the Daily Tasks module.
///
/// Follows the same pattern as [TopicCommands]: every mutation persists first,
/// then triggers a backup snapshot so the new data is durable before the user
/// moves on.
class DailyTaskCommands {
  DailyTaskCommands(this._repo);
  final DailyTaskRepository _repo;
  static const _uuid = Uuid();

  void _backup() => BackupService.instance.scheduleAutoBackup();

  Future<void> createTemplate({
    required String title,
    String? description,
    String? subjectId,
  }) async {
    final existing = _repo.allTemplates();
    final maxOrder = existing.isEmpty
        ? 0
        : existing.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b);
    final template = DailyTaskTemplate(
      id: _uuid.v4(),
      title: title,
      description: description,
      subjectId: subjectId,
      active: true,
      sortOrder: maxOrder + 1,
      createdAt: DateTime.now(),
    );
    await _repo.upsertTemplate(template);
    _backup();
  }

  Future<void> updateTemplate(DailyTaskTemplate template) async {
    await _repo.upsertTemplate(template);
    _backup();
  }

  Future<void> archiveTemplate(String id) async {
    final t = _repo.templateById(id);
    if (t == null) return;
    await _repo.upsertTemplate(
      t.copyWith(
        active: false,
        archivedAt: DateTime.now(),
      ),
    );
    _backup();
  }

  Future<void> restoreTemplate(String id) async {
    final t = _repo.templateById(id);
    if (t == null) return;
    await _repo.upsertTemplate(
      t.copyWith(
        active: true,
        clearArchivedAt: true,
      ),
    );
    _backup();
  }

  Future<void> reorderTemplates(List<DailyTaskTemplate> ordered) async {
    for (int i = 0; i < ordered.length; i++) {
      await _repo.upsertTemplate(ordered[i].copyWith(sortOrder: i));
    }
    _backup();
  }

  /// Toggle a daily task's completion for the given date.
  ///
  /// Creates a new completion record if none exists, or flips the existing one.
  /// Prevents duplicate records for the same (taskTemplateId, date) pair.
  Future<void> toggleCompletion({
    required String taskTemplateId,
    required DateTime date,
  }) async {
    final d = DateTime(date.year, date.month, date.day);
    final existing = _repo.completionFor(taskTemplateId, d);
    if (existing != null) {
      await _repo.upsertCompletion(
        existing.copyWith(
          completed: !existing.completed,
          completedAt: !existing.completed ? DateTime.now() : null,
          clearCompletedAt: existing.completed,
        ),
      );
    } else {
      await _repo.upsertCompletion(
        DailyTaskCompletion(
          id: _uuid.v4(),
          taskTemplateId: taskTemplateId,
          date: d,
          completed: true,
          completedAt: DateTime.now(),
        ),
      );
    }
    _backup();
  }

  Future<void> deleteTemplate(String id) async {
    await _repo.deleteCompletionsForTemplate(id);
    await _repo.deleteTemplate(id);
    _backup();
  }
}

final dailyTaskCommandsProvider = Provider<DailyTaskCommands>(
  (ref) => DailyTaskCommands(ref.watch(dailyTaskRepositoryProvider)),
);
