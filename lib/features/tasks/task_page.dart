import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../core/recurrence.dart';
import '../../core/routine.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../../shared/widgets/appearance_badge.dart';
import '../../shared/widgets/appearance_picker.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tag_chip.dart';
import 'hub/hub_tools.dart';
import 'task_draft.dart';
import 'task_labels.dart';
import 'task_providers.dart';
import 'widgets/task_tile.dart';

/// Hub da tarefa. Nesta etapa: dados da tarefa, status e subtarefas. Cards,
/// pomodoro e páginas entram na Etapa 4.
class TaskPage extends ConsumerWidget {
  const TaskPage({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final task = ref.watch(taskProvider(taskId));
    return task.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonPage()),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: AppIcons.error, message: l10n.taskLoadOneError),
      ),
      data: (task) => task == null
          ? Scaffold(
              appBar: AppBar(),
              body: EmptyState(
                icon: AppIcons.searchEmpty,
                message: l10n.taskNotFound,
              ),
            )
          : _TaskHub(task: task),
    );
  }
}

class _TaskHub extends ConsumerWidget {
  const _TaskHub({required this.task});

  final Task task;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    await deleteWithUndo(messenger, ref, task);
  }

  Future<void> _pickAppearance(BuildContext context, WidgetRef ref) async {
    final resolver = ref.read(appearanceResolverProvider);
    // O que vale sem escolha própria: herança sem a cor/ícone da tarefa.
    final inherited = task.copyWith(
      colorKey: const Value(null),
      iconKey: const Value(null),
    );
    final choice = await showAppearancePicker(
      context,
      colorKey: task.colorKey,
      iconKey: task.iconKey,
      inheritedColor: resolver.colorKeyOf(inherited),
      inheritedIcon: AppIcons.of(
        resolver.iconKeyOf(inherited),
        fallback: AppIcons.kind(task.kind),
      ),
    );
    if (choice == null) return;
    await ref
        .read(tasksRepositoryProvider)
        .saveTask(
          task.copyWith(
            colorKey: Value(choice.colorKey),
            iconKey: Value(choice.iconKey),
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = context.lang;
    final theme = Theme.of(context);
    final space = context.space;
    final resolver = ref.watch(appearanceResolverProvider);
    final today = ref.watch(todayProvider);
    final tags = ref.watch(taskTagsProvider(task.id)).value ?? const [];
    final parent = task.parentId == null
        ? null
        : ref.watch(taskProvider(task.parentId!)).value;
    final done = task.status == TaskStatus.feita;
    final repo = ref.read(tasksRepositoryProvider);

    String when(DateTime d) => task.hasTime
        ? '${formatDate(d, today, lang: lang)}, ${formatTime(d)}'
        : formatDate(d, today, lang: lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(parent == null ? l10n.taskSingular : l10n.subtaskSingular),
        actions: [
          IconButton(
            tooltip: l10n.actionEdit,
            icon: const Icon(AppIcons.edit),
            onPressed: () => context.push(Routes.editTask(task.id)),
          ),
          IconButton(
            tooltip: l10n.actionDelete,
            icon: const Icon(AppIcons.delete),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: space.xxl),
        children: [
          if (parent != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: space.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(AppIcons.subtask),
                  label: Text(l10n.subtaskOf(parent.title)),
                  onPressed: () => context.push(Routes.task(parent.id)),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(space.page, space.sm, space.page, 0),
            child: Row(
              children: [
                Tooltip(
                  message: l10n.fieldIconAndColor,
                  child: InkWell(
                    borderRadius: context.radius.lgAll,
                    onTap: () => _pickAppearance(context, ref),
                    child: AppearanceBadge(
                      colorKey: resolver.colorKeyOf(task),
                      icon: AppIcons.of(
                        resolver.iconKeyOf(task),
                        fallback: AppIcons.kind(task.kind),
                      ),
                      size: AppIconSize.feature,
                    ),
                  ),
                ),
                SizedBox(width: space.lg),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.headlineSmall!.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(space.page, space.lg, space.page, 0),
            child: Wrap(
              spacing: space.sm,
              runSpacing: space.sm,
              children: [
                Chip(
                  avatar: Icon(task.kind.icon),
                  label: Text(task.kind.labelFor(l10n)),
                ),
                PopupMenuButton<TaskStatus>(
                  tooltip: l10n.taskChangeStatus,
                  initialValue: task.status,
                  onSelected: (s) => s == TaskStatus.feita
                      ? completeAndAnnounce(
                          ScaffoldMessenger.of(context),
                          ref,
                          task,
                        )
                      : repo.setStatus(task.id, s),
                  itemBuilder: (_) => [
                    for (final s in TaskStatus.values)
                      PopupMenuItem(value: s, child: Text(s.labelFor(l10n))),
                  ],
                  // A setinha fica dentro do rótulo: o `deleteIcon` do Chip
                  // anunciaria "Excluir" para o leitor de tela.
                  child: Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(task.status.labelFor(l10n)),
                        const ExcludeSemantics(
                          child: Icon(
                            AppIcons.dropdown,
                            size: AppIconSize.meta,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (task.priority > 0)
                  Chip(
                    avatar: Icon(
                      AppIcons.priority,
                      color: switch (task.priority) {
                        3 => context.palette.danger.strong,
                        2 => context.palette.warning.strong,
                        _ => null,
                      },
                    ),
                    label: Text(
                      l10n.taskPriorityBadge(
                        priorityLabel(task.priority, l10n),
                      ),
                    ),
                  ),
                for (final tag in tags)
                  TagChip(name: tag.name, colorKey: tag.colorKey),
              ],
            ),
          ),
          SizedBox(height: space.sm),
          if (task.startAt case final start?)
            _Info(AppIcons.start, l10n.fieldStart, when(start)),
          if (task.dueAt case final due?)
            _Info(AppIcons.date, l10n.fieldDue, when(due)),
          if (task.recurrenceRule case final rule?)
            _Info(
              AppIcons.repeat,
              l10n.fieldRecurrence,
              RecurrenceRule.parse(rule).describe(lang: lang),
            ),
          if (task.reminderMinutesBefore != null)
            _Info(
              task.reminderMode == ReminderMode.alarme
                  ? AppIcons.alarm
                  : AppIcons.notification,
              task.reminderMode == ReminderMode.alarme
                  ? l10n.fieldAlarm
                  : l10n.fieldReminder,
              '${reminderOptions.containsKey(task.reminderMinutesBefore) ? reminderOptionLabel(task.reminderMinutesBefore, l10n) : l10n.reminderMinutesBefore(task.reminderMinutesBefore!)}'
              '${task.reminderMode == ReminderMode.alarme ? ' · ${l10n.reminderModeAlarm}' : ''}',
            ),
          if (task.notes case final notes?)
            Padding(
              padding: EdgeInsets.fromLTRB(space.page, space.sm, space.page, 0),
              child: Text(notes, style: theme.textTheme.bodyMedium),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              space.page,
              space.lg,
              space.page,
              space.sm,
            ),
            child: done
                ? OutlinedButton.icon(
                    icon: const Icon(AppIcons.undo),
                    label: Text(l10n.actionReopen),
                    onPressed: () =>
                        toggleDone(ScaffoldMessenger.of(context), ref, task),
                  )
                : FilledButton.icon(
                    icon: const Icon(AppIcons.check),
                    label: Text(l10n.actionComplete),
                    onPressed: () =>
                        toggleDone(ScaffoldMessenger.of(context), ref, task),
                  ),
          ),
          HubTools(task: task, part: HubToolsPart.shortcuts),
          if (task.recurrenceRule case final rule?)
            _RoutineHistory(
              taskId: task.id,
              rule: RecurrenceRule.parse(rule),
              today: today,
            ),
          _Subtasks(task: task, today: today),
          HubTools(task: task, part: HubToolsPart.sections),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _Subtasks extends ConsumerStatefulWidget {
  const _Subtasks({required this.task, required this.today});

  final Task task;
  final DateTime today;

  @override
  ConsumerState<_Subtasks> createState() => _SubtasksState();
}

class _SubtasksState extends ConsumerState<_Subtasks> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  /// Ordem local logo após arrastar, até o banco devolver a nova ordem.
  List<Task>? _reordered;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final title = _input.text.trim();
    if (title.isEmpty) return;
    _input.clear();
    _focus.requestFocus(); // continua digitando a próxima
    await ref
        .read(tasksRepositoryProvider)
        .createTask(title: title, parentId: widget.task.id);
  }

  Future<void> _reorder(List<Task> current, int from, int to) async {
    final list = [...current];
    final moved = list.removeAt(from);
    list.insert(to, moved); // `onReorderItem` já ajusta o índice
    setState(() => _reordered = list);
    await ref.read(tasksRepositoryProvider).reorder([
      for (final t in list) t.id,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final fromDb =
        ref.watch(subtasksProvider(widget.task.id)).value ?? const [];
    // Descarta a ordem local assim que o banco confirma a mesma ordem.
    if (_reordered != null &&
        _reordered!.map((t) => t.id).join() == fromDb.map((t) => t.id).join()) {
      _reordered = null;
    }
    final subtasks = _reordered ?? fromDb;
    final doneCount = subtasks
        .where((t) => t.status == TaskStatus.feita)
        .length;

    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l10n.subtasksSection,
          detail: subtasks.isEmpty ? null : '$doneCount/${subtasks.length}',
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) => _reorder(subtasks, from, to),
          children: [
            for (final (index, sub) in subtasks.indexed)
              SwipeableTaskTile(
                key: ValueKey(sub.id),
                tile: TaskTile(
                  task: sub,
                  today: widget.today,
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.all(context.space.sm),
                      child: Icon(
                        AppIcons.dragHandle,
                        semanticLabel: l10n.actionDrag,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.space.page,
            context.space.xs,
            context.space.page,
            0,
          ),
          child: TextField(
            controller: _input,
            focusNode: _focus,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: l10n.subtasksAddHint,
              prefixIcon: const Icon(AppIcons.add),
              suffixIcon: IconButton(
                tooltip: l10n.actionAdd,
                icon: const Icon(AppIcons.send),
                onPressed: _add,
              ),
            ),
            onSubmitted: (_) => _add(),
          ),
        ),
      ],
    );
  }
}

/// Sequência atual e últimas conclusões de uma rotina.
class _RoutineHistory extends ConsumerWidget {
  const _RoutineHistory({
    required this.taskId,
    required this.rule,
    required this.today,
  });

  final String taskId;
  final RecurrenceRule rule;
  final DateTime today;

  static const _shown = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = context.lang;
    final completions =
        ref.watch(completionsProvider(taskId)).value ?? const [];
    final theme = Theme.of(context);
    final streak = routineStreak(
      rule,
      completions.map((c) => c.occurrence),
      today,
    );
    final daily = rule.frequency == Frequency.daily && rule.interval == 1;
    final streakText = streak == 0
        ? l10n.routineNoStreak
        : daily
        ? l10n.routineStreakDays(
            streak,
            streak == 1 ? l10n.routineDaySingular : l10n.routineDayPlural,
          )
        : l10n.routineStreakDays(
            streak,
            streak == 1 ? l10n.routineTimeSingular : l10n.routineTimePlural,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.routineHistory),
        ListTile(
          leading: Icon(
            AppIcons.streak,
            color: streak > 0 ? theme.colorScheme.tertiary : null,
          ),
          title: Text(streakText),
          subtitle: Text(
            completions.isEmpty
                ? l10n.routineNotCompletedYet
                : l10n.routineTotalCompletions(
                    completions.length,
                    completions.length == 1
                        ? l10n.unitCompletion
                        : l10n.unitCompletions,
                  ),
          ),
        ),
        if (completions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in completions.take(_shown))
                  Chip(
                    avatar: const Icon(AppIcons.check, size: 16),
                    label: Text(formatDate(c.occurrence, today, lang: lang)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
