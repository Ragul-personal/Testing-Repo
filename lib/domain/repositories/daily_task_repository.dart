import '../entities/daily_task.dart';

/// Repository interface for daily task templates and their completion records.
///
/// Follows the same pattern as [SubjectRepository] / [TopicRepository]:
/// synchronous reads from the in-memory Hive cache, asynchronous writes, and
/// reactive streams via [watch] methods.
abstract class DailyTaskRepository {
  // ── Templates ──────────────────────────────────────────

  List<DailyTaskTemplate> allTemplates();
  List<DailyTaskTemplate> activeTemplates();
  DailyTaskTemplate? templateById(String id);
  Future<void> upsertTemplate(DailyTaskTemplate t);
  Future<void> deleteTemplate(String id);
  Stream<List<DailyTaskTemplate>> watchTemplates();

  // ── Completions ────────────────────────────────────────

  List<DailyTaskCompletion> allCompletions();
  List<DailyTaskCompletion> completionsForDate(DateTime date);
  DailyTaskCompletion? completionFor(String taskTemplateId, DateTime date);
  Future<void> upsertCompletion(DailyTaskCompletion c);
  Future<void> deleteCompletion(String id);
  Future<void> deleteCompletionsForTemplate(String taskTemplateId);
  Stream<List<DailyTaskCompletion>> watchCompletions();
}
