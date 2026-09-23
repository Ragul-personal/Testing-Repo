import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/daily_task.dart';
import '../providers/daily_task_providers.dart';
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
    final streak = ref.watch(dailyTaskStreakProvider);
    final avg7 = ref.watch(dailyTask7DayAvgProvider);
    final avg30 = ref.watch(dailyTask30DayAvgProvider);
    final history = ref.watch(dailyTaskHistoryProvider);
    final commands = ref.read(dailyTaskCommandsProvider);
    final today = ref.watch(currentDayProvider);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
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
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: 'Manage tasks',
                      onPressed: () => context.push('/daily-tasks/manage'),
                    ),
                  ],
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
                                  backgroundColor:
                                      cs.surfaceContainerHighest,
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

                // ── Stats row ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Row(
                      children: [
                        _StatChip(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: Colors.orange,
                          value: '$streak',
                          label: 'streak',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _StatChip(
                          icon: Icons.trending_up_rounded,
                          iconColor: cs.primary,
                          value: '${avg7.round()}%',
                          label: '7-day',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _StatChip(
                          icon: Icons.calendar_month_rounded,
                          iconColor: cs.tertiary,
                          value: '${avg30.round()}%',
                          label: '30-day',
                        ),
                      ],
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
                        Text(
                          'Last 7 days',
                          style: tt.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        DailyTaskChart(data: history, maxDays: 7),
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
                      final done =
                          completions[task.id]?.completed == true;
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

class _TaskTile extends StatelessWidget {
  final DailyTaskTemplate task;
  final bool done;
  final VoidCallback onToggle;

  const _TaskTile({
    required this.task,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: done ? cs.primary : cs.outline,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    task.title,
                    style: tt.bodyLarge?.copyWith(
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                      color: done
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
