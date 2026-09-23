import '../../domain/entities/daily_task.dart';
import '../../domain/repositories/daily_task_repository.dart';
import '../../services/storage_service.dart';
import '../models/daily_task_completion_model.dart';
import '../models/daily_task_template_model.dart';

class DailyTaskRepositoryImpl implements DailyTaskRepository {
  final _store = StorageService.instance;

  // ── Templates ──────────────────────────────────────────

  @override
  List<DailyTaskTemplate> allTemplates() =>
      _store.dailyTaskTemplates.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  List<DailyTaskTemplate> activeTemplates() =>
      _store.dailyTaskTemplates.values
          .where((m) => m.active)
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  DailyTaskTemplate? templateById(String id) =>
      _store.dailyTaskTemplates.get(id)?.toEntity();

  @override
  Future<void> upsertTemplate(DailyTaskTemplate t) async {
    await _store.dailyTaskTemplates
        .put(t.id, DailyTaskTemplateModel.fromEntity(t));
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _store.dailyTaskTemplates.delete(id);
  }

  @override
  Stream<List<DailyTaskTemplate>> watchTemplates() async* {
    yield allTemplates();
    yield* _store.dailyTaskTemplates.watch().map((_) => allTemplates());
  }

  // ── Completions ────────────────────────────────────────

  @override
  List<DailyTaskCompletion> allCompletions() =>
      _store.dailyTaskCompletions.values.map((m) => m.toEntity()).toList();

  @override
  List<DailyTaskCompletion> completionsForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _store.dailyTaskCompletions.values
        .where((m) {
          final md = DateTime(m.date.year, m.date.month, m.date.day);
          return md == d;
        })
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  DailyTaskCompletion? completionFor(String taskTemplateId, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (final m in _store.dailyTaskCompletions.values) {
      final md = DateTime(m.date.year, m.date.month, m.date.day);
      if (m.taskTemplateId == taskTemplateId && md == d) {
        return m.toEntity();
      }
    }
    return null;
  }

  @override
  Future<void> upsertCompletion(DailyTaskCompletion c) async {
    await _store.dailyTaskCompletions
        .put(c.id, DailyTaskCompletionModel.fromEntity(c));
  }

  @override
  Future<void> deleteCompletion(String id) async {
    await _store.dailyTaskCompletions.delete(id);
  }

  @override
  Future<void> deleteCompletionsForTemplate(String taskTemplateId) async {
    final keys = _store.dailyTaskCompletions.keys
        .where(
          (k) =>
              _store.dailyTaskCompletions.get(k)?.taskTemplateId ==
              taskTemplateId,
        )
        .toList();
    if (keys.isNotEmpty) await _store.dailyTaskCompletions.deleteAll(keys);
  }

  @override
  Stream<List<DailyTaskCompletion>> watchCompletions() async* {
    yield allCompletions();
    yield* _store.dailyTaskCompletions.watch().map((_) => allCompletions());
  }
}
