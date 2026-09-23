import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../domain/entities/daily_task.dart';
import '../providers/daily_task_providers.dart';

/// Task management screen: add, edit, reorder, archive, and restore templates.
class DailyTasksManagePage extends ConsumerWidget {
  const DailyTasksManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTemplates =
        ref.watch(dailyTaskTemplatesProvider).valueOrNull ?? const [];
    final active = allTemplates.where((t) => t.active).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final archived = allTemplates.where((t) => !t.active).toList();
    final commands = ref.read(dailyTaskCommandsProvider);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add task',
            onPressed: () => _showAddDialog(context, commands),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.bottomInset),
        children: [
          // ── Active tasks (reorderable) ────────────────────────
          if (active.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: Text(
                'ACTIVE',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: active.length,
              onReorder: (oldIdx, newIdx) {
                if (newIdx > oldIdx) newIdx--;
                final reordered = List<DailyTaskTemplate>.from(active);
                final item = reordered.removeAt(oldIdx);
                reordered.insert(newIdx, item);
                commands.reorderTemplates(reordered);
              },
              itemBuilder: (context, index) {
                final t = active[index];
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(right: AppSpacing.gutter),
                    color: cs.errorContainer,
                    child: Icon(
                      Icons.archive_outlined,
                      color: cs.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) => commands.archiveTemplate(t.id),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    title: Text(t.title),
                    subtitle: t.description != null
                        ? Text(
                            t.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _showEditDialog(context, commands, t),
                    ),
                  ),
                );
              },
            ),
          ],

          // ── Archived tasks ────────────────────────────────────
          if (archived.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.xxl,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: Text(
                'ARCHIVED',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            for (final t in archived)
              ListTile(
                leading: Icon(
                  Icons.archive_outlined,
                  color: cs.onSurfaceVariant,
                ),
                title: Text(
                  t.title,
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => commands.restoreTemplate(t.id),
                      child: const Text('Restore'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: cs.error,
                      ),
                      onPressed: () => _confirmDelete(
                        context,
                        commands,
                        t,
                      ),
                    ),
                  ],
                ),
              ),
          ],

          if (active.isEmpty && archived.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 48,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No tasks yet',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tap + to add your first daily task.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
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
            Text('New daily task',
                style: Theme.of(ctx).textTheme.titleMedium),
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
            Text('Edit task',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Task name'),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  commands
                      .updateTemplate(task.copyWith(title: v.trim()));
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

  void _confirmDelete(
    BuildContext context,
    DailyTaskCommands commands,
    DailyTaskTemplate task,
  ) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'This will permanently delete "${task.title}" and all its '
          'completion history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              commands.deleteTemplate(task.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
