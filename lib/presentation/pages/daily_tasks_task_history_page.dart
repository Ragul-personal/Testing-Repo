import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../providers/daily_task_providers.dart';
import '../widgets/empty_state.dart';

class DailyTasksTaskHistoryPage extends ConsumerWidget {
  final String taskId;

  const DailyTasksTaskHistoryPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTemplates =
        ref.watch(dailyTaskTemplatesProvider).valueOrNull ?? [];
    final template = allTemplates.where((t) => t.id == taskId).firstOrNull;

    if (template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task History')),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Task not found',
          subtitle: 'The task may have been deleted.',
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final streak = ref.watch(taskStreakProvider(taskId));

    // Get all completions for this task to show history list
    final allCompletions =
        ref.watch(dailyTaskCompletionsProvider).valueOrNull ?? [];
    final myCompletions = allCompletions
        .where((c) => c.taskTemplateId == taskId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // descending

    return Scaffold(
      appBar: AppBar(title: Text(template.title)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.orange,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '$streak Day Streak',
                            style: tt.headlineSmall?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Recent History', style: tt.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
          if (myCompletions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No completions yet.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = myCompletions[index];
                  return ListTile(
                    leading: Icon(
                      Icons.check_circle_rounded,
                      color: cs.primary,
                    ),
                    title: Text(DateLabels.fullDate(c.date)),
                  );
                },
                childCount: myCompletions.length,
              ),
            ),
        ],
      ),
    );
  }
}
