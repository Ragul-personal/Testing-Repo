# RecallDay — Daily Tasks Module

> **⚠️ This is the Testing-Repo branch.** This code is pushed here for CI
> validation. **Do NOT use this as the production codebase.** The canonical
> repository is [Ragul-personal/RecallDay](https://github.com/Ragul-personal/RecallDay).

## Feature: Daily Tasks

A new module for tracking recurring daily tasks alongside RecallDay's
existing spaced-repetition functionality.

### What it does

- **Create daily task templates** — fixed things you want to accomplish every
  day (e.g. "Engineering Mathematics", "Core CS", "Mock Test").
- **Automatic daily appearance** — active templates appear on today's screen.
- **Check / uncheck** — tap to toggle completion, with immediate percentage
  update.
- **Completion percentage** — `completed / total × 100`, displayed as a
  circular progress indicator.
- **Historical data** — past completion records are preserved. Adding or
  archiving tasks does NOT rewrite old percentages.
- **Streak tracking** — consecutive days of 100% completion, separate from
  the spaced-repetition streak.
- **7-day and 30-day averages** — displayed as stats on the Daily tab.
- **Simple bar chart** — last 7 days, custom-painted with no third-party
  chart library.
- **Task management** — add, edit, archive, restore, reorder, delete.
- **Backup integration** — daily task data is included in all exports/imports.

### Architecture

The module is isolated and follows the existing clean-architecture pattern:

```
lib/domain/entities/daily_task.dart
lib/domain/repositories/daily_task_repository.dart
lib/data/models/daily_task_template_model.dart    (TypeID 5)
lib/data/models/daily_task_completion_model.dart   (TypeID 6)
lib/data/repositories/daily_task_repository_impl.dart
lib/presentation/providers/daily_task_providers.dart
lib/presentation/providers/daily_task_commands.dart
lib/presentation/pages/daily_tasks_page.dart
lib/presentation/pages/daily_tasks_manage_page.dart
lib/presentation/widgets/daily_task_chart.dart
```

**Modified existing files:**
- `storage_service.dart` — registers TypeID 5/6 adapters, opens new boxes
- `backup_service.dart` — includes daily task data in snapshots and restores
- `app_router.dart` — adds 5th tab branch + manage page route
- `home_shell.dart` — adds "Daily" navigation destination

### Running locally

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

### CI

The `.github/workflows/daily-tasks-ci.yml` workflow:
1. Installs dependencies
2. Runs `flutter analyze`
3. Runs `flutter test`
4. Builds a debug APK
5. Uploads it as `RecallDay-DailyTasks-debug.apk`

### Design decisions

- **Successful day = 100% completion** — used for streak calculation.
- **Daily task streak is separate** from the spaced-repetition streak.
- **Historical percentages are logically correct** — completion records serve
  as evidence of what was scheduled on each day.
- **No third-party chart library** — the bar chart uses `CustomPainter`.
- **No notifications** for daily tasks in this first version.
- **Hive TypeIDs 5 and 6** — chosen as the next unused IDs after existing
  1–4.
