import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/daily_task.dart';
import '../providers/daily_task_providers.dart';
import '../providers/providers.dart';
import '../widgets/daily_task_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/tab_app_bar.dart';

/// The main Daily Tasks tab screen.
///
/// Shows today's checklist, progress, stats, and a 7-day chart.
/// The user's daily interaction is: open → see tasks → tick → see progress.
class DailyTasksPage extends ConsumerWidget {
  const DailyTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(activeDailyTasksProvider);
    final completions = ref.watch(todayCompletionsProvider);
    final progress = ref.watch(dailyTaskProgressProvider);
    final commands = ref.read(dailyTaskCommandsProvider);
    final today = ref.watch(currentDayProvider);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, commands),
        child: const Icon(Icons.add_rounded),
      ),
      body: tasks.isEmpty
          ? CustomScrollView(
              slivers: [
                TabAppBar(
                  title: 'Daily Tasks',
                  subtitle: DateLabels.fullDate(today),
                ),
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'No daily tasks yet',
                    subtitle: 'Add recurring tasks you want to\n'
                        'accomplish every day.',
                    action: FilledButton.icon(
                      onPressed: () => _showAddDialog(context, commands),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add task'),
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                TabAppBar(
                  title: 'Daily Tasks',
                  subtitle: DateLabels.fullDate(today),
                ),

                // ── Progress card ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.sm,
                      AppSpacing.gutter,
                      AppSpacing.lg,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: CircularProgressIndicator(
                                  value: progress.total > 0
                                      ? progress.completed / progress.total
                                      : 0,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  color: cs.primary,
                                  strokeWidth: 6,
                                ),
                              ),
                              Text(
                                '${progress.percentage.round()}%',
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.gutter),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${progress.completed} / ${progress.total} completed',
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  progress.total == 0
                                      ? 'No tasks for today'
                                      : progress.completed == progress.total
                                          ? 'All done for today! 🎉'
                                          : 'Keep going!',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Chart ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => context.push(
                            '/daily-tasks/history/day/${today.toIso8601String()}',
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text('Recent Progress', style: tt.titleSmall),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        DailyTaskChart(
                          data: ref.watch(dailyTaskHistoryDaysProvider(7)),
                          maxDays: 7,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Section header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.sm,
                      AppSpacing.gutter,
                      AppSpacing.md,
                    ),
                    child: Text("Today's Tasks", style: tt.titleSmall),
                  ),
                ),

                // ── Checklist ───────────────────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      final done = completions[task.id]?.completed == true;
                      return _TaskTile(
                        task: task,
                        done: done,
                        onToggle: () {
                          HapticFeedback.lightImpact();
                          commands.toggleCompletion(
                            taskTemplateId: task.id,
                            date: today,
                          );
                        },
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),

                // Bottom padding so the FAB doesn't cover the last item.
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.bottomInset),
                ),
              ],
            ),
    );
  }

  void _showAddDialog(BuildContext context, DailyTaskCommands commands) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.gutter,
          AppSpacing.gutter,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New daily task',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task name',
                hintText: 'e.g. Engineering Mathematics',
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  commands.createTemplate(title: v.trim());
                  Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isNotEmpty) {
                  commands.createTemplate(title: v);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Private widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _TaskTile extends ConsumerWidget {
  final DailyTaskTemplate task;
  final bool done;
  final VoidCallback onToggle;

  const _TaskTile({
    required this.task,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final streak = ref.watch(taskStreakProvider(task.id));
    final commands = ref.read(dailyTaskCommandsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.xs,
      ),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.error,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(Icons.delete_rounded, color: cs.onError),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete task?'),
              content: const Text('Are you sure you want to delete this task?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          commands.deleteTemplate(task.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  commands.createTemplate(
                    title: task.title,
                  ); // Basic undo
                },
              ),
            ),
          );
        },
        child: Material(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onToggle,
            onLongPress: () {
              _showEditDialog(context, commands, task);
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    done ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: done ? cs.primary : cs.outline,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: tt.bodyLarge?.copyWith(
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            color: done ? cs.onSurfaceVariant : cs.onSurface,
                          ),
                        ),
                        if (streak > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '🔥 $streak day streak',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    DailyTaskCommands commands,
    DailyTaskTemplate task,
  ) {
    final controller = TextEditingController(text: task.title);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.gutter,
          AppSpacing.gutter,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit task',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task name',
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  commands.updateTemplate(task.copyWith(title: v.trim()));
                  Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isNotEmpty) {
                  commands.updateTemplate(task.copyWith(title: v));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
