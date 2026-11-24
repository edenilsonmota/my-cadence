import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/dates.dart';
import '../../core/recurrence.dart';
import '../../core/routine.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
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
    final task = ref.watch(taskProvider(taskId));
    return task.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline,
          message: 'Não foi possível carregar a tarefa.',
        ),
      ),
      data: (task) => task == null
          ? Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                icon: Icons.search_off,
                message: 'Tarefa não encontrada.',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final tags = ref.watch(taskTagsProvider(task.id)).value ?? const [];
    final parent = task.parentId == null
        ? null
        : ref.watch(taskProvider(task.parentId!)).value;
    final done = task.status == TaskStatus.feita;
    final repo = ref.read(tasksRepositoryProvider);

    String when(DateTime d) => task.hasTime
        ? '${formatDate(d, today)}, ${formatTime(d)}'
        : formatDate(d, today);

    return Scaffold(
      appBar: AppBar(
        title: Text(parent == null ? 'Tarefa' : 'Subtarefa'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.editTask(task.id)),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (parent != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.subdirectory_arrow_right),
              title: Text('Subtarefa de ${parent.title}'),
              onTap: () => context.push(Routes.task(parent.id)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              task.title,
              style: theme.textTheme.headlineSmall!.copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(task.kind.icon),
                  label: Text(task.kind.label),
                ),
                PopupMenuButton<TaskStatus>(
                  tooltip: 'Mudar status',
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
                      PopupMenuItem(value: s, child: Text(s.label)),
                  ],
                  // A setinha fica dentro do rótulo: o `deleteIcon` do Chip
                  // anunciaria "Excluir" para o leitor de tela.
                  child: Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(task.status.label),
                        const ExcludeSemantics(
                          child: Icon(Icons.arrow_drop_down, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                if (task.priority > 0)
                  Chip(
                    avatar: Icon(
                      Icons.flag,
                      color: priorityColor(task.priority, theme.colorScheme),
                    ),
                    label: Text('Prioridade ${priorityLabels[task.priority]}'),
                  ),
                for (final tag in tags)
                  Chip(
                    avatar: CircleAvatar(backgroundColor: Color(tag.color)),
                    label: Text(tag.name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (task.startAt case final start?)
            _Info(Icons.play_arrow_outlined, 'Início', when(start)),
          if (task.dueAt case final due?)
            _Info(Icons.event_outlined, 'Prazo', when(due)),
          if (task.recurrenceRule case final rule?)
            _Info(
              Icons.repeat,
              'Repetição',
              RecurrenceRule.parse(rule).describe(),
            ),
          if (task.reminderMinutesBefore != null)
            _Info(
              Icons.alarm,
              'Alarme',
              reminderOptions[task.reminderMinutesBefore] ??
                  '${task.reminderMinutesBefore} min antes',
            ),
          if (task.notes case final notes?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(notes, style: theme.textTheme.bodyMedium),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: done
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.undo),
                    label: const Text('Reabrir'),
                    onPressed: () =>
                        toggleDone(ScaffoldMessenger.of(context), ref, task),
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Concluir'),
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
          const Divider(height: 24),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            subtasks.isEmpty
                ? 'Subtarefas'
                : 'Subtarefas · $doneCount/${subtasks.length}',
            style: Theme.of(context).textTheme.titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.primary),
          ),
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
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle, semanticLabel: 'Arrastar'),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: TextField(
            controller: _input,
            focusNode: _focus,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Adicionar subtarefa',
              prefixIcon: const Icon(Icons.add),
              suffixIcon: IconButton(
                tooltip: 'Adicionar',
                icon: const Icon(Icons.send),
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
        ? 'Nenhuma sequência em andamento'
        : daily
        ? '$streak ${streak == 1 ? 'dia seguido' : 'dias seguidos'}'
        : '$streak ${streak == 1 ? 'vez seguida' : 'vezes seguidas'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Histórico',
            style: theme.textTheme.titleSmall!.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.local_fire_department_outlined,
            color: streak > 0 ? theme.colorScheme.tertiary : null,
          ),
          title: Text(streakText),
          subtitle: Text(
            completions.isEmpty
                ? 'Ainda não concluída'
                : '${completions.length} '
                      '${completions.length == 1 ? 'conclusão' : 'conclusões'} no total',
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
                    avatar: const Icon(Icons.check, size: 16),
                    label: Text(formatDate(c.occurrence, today)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
