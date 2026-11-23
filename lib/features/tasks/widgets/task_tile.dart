import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/dates.dart';
import '../../../data/db/database.dart';
import '../../../data/db/enums.dart';
import '../../../data/providers.dart';
import '../task_labels.dart';
import '../task_providers.dart';

/// Conclui ou reabre a tarefa. Rotina concluída avança para a próxima
/// ocorrência e o SnackBar avisa quando ela é.
Future<void> toggleDone(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
  Task task,
) async {
  final repo = ref.read(tasksRepositoryProvider);
  if (task.status == TaskStatus.feita) {
    await repo.setStatus(task.id, TaskStatus.aFazer);
    return;
  }
  await completeAndAnnounce(messenger, ref, task);
}

/// Conclui (via [TasksRepository.completeTask]) e, se for rotina, mostra a
/// próxima ocorrência.
Future<void> completeAndAnnounce(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
  Task task,
) async {
  final today = ref.read(todayProvider);
  final updated = await ref.read(tasksRepositoryProvider).completeTask(task.id);
  if (task.recurrenceRule == null || updated == null) return;
  final next = updated.dueAt;
  final message = updated.status == TaskStatus.feita || next == null
      ? 'Rotina encerrada: era a última ocorrência.'
      : 'Rotina concluída. Próxima: '
            '${formatRelative(next, today, withTime: updated.hasTime)}.';
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Exclui a tarefa (e subtarefas) e oferece "Desfazer" no SnackBar.
Future<void> deleteWithUndo(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
  Task task,
) async {
  final repo = ref.read(tasksRepositoryProvider);
  final ids = await repo.deleteTask(task.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          ids.length > 1
              ? '"${task.title}" e ${ids.length - 1} subtarefa(s) excluídas'
              : '"${task.title}" excluída',
        ),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => repo.restoreTasks(ids),
        ),
      ),
    );
}

/// Linha de tarefa: checkbox, título e um resumo (prazo, repetição, prioridade).
class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({
    required this.task,
    required this.today,
    this.depth = 0,
    this.trailing,
    this.showOverdue = true,
    super.key,
  });

  final Task task;
  final DateTime today;

  /// Nível na árvore (recuo à esquerda).
  final int depth;
  final Widget? trailing;

  /// Destaca o prazo em vermelho quando já passou.
  final bool showOverdue;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  /// Estado mostrado durante a animação, antes de gravar no banco.
  bool? _pendingDone;

  bool get _done => _pendingDone ?? widget.task.status == TaskStatus.feita;

  Future<void> _toggle() async {
    setState(() => _pendingDone = !_done);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await toggleDone(ScaffoldMessenger.of(context), ref, widget.task);
    if (mounted) setState(() => _pendingDone = null);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final overdue =
        widget.showOverdue &&
        !_done &&
        task.dueAt != null &&
        task.dueAt!.isBefore(widget.today);

    final details = <Widget>[
      if (task.dueAt case final due?)
        _Detail(
          icon: Icons.event_outlined,
          text: formatRelative(due, widget.today, withTime: task.hasTime),
          color: overdue ? colors.error : null,
        ),
      if (task.recurrenceRule != null) const _Detail(icon: Icons.repeat),
      if (task.kind != TaskKind.simples) _Detail(icon: task.kind.icon),
      if (task.status == TaskStatus.fazendo)
        _Detail(icon: Icons.play_circle_outline, text: task.status.label),
    ];
    final flag = priorityColor(task.priority, colors);

    return ListTile(
      contentPadding: EdgeInsetsDirectional.only(
        start: 8 + 24.0 * widget.depth,
        end: 8,
      ),
      onTap: () => context.push(Routes.task(task.id)),
      leading: Checkbox(
        value: _done,
        onChanged: (_) => _toggle(),
        semanticLabel: _done ? 'Reabrir' : 'Concluir',
      ),
      title: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: theme.textTheme.bodyLarge!.copyWith(
          color: _done ? colors.onSurfaceVariant : colors.onSurface,
          decoration: _done ? TextDecoration.lineThrough : null,
        ),
        child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      subtitle: details.isEmpty
          ? null
          : Wrap(spacing: 12, runSpacing: 2, children: details),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flag != null)
            Icon(
              Icons.flag,
              size: 18,
              color: flag,
              semanticLabel: 'Prioridade',
            ),
          ?widget.trailing,
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, this.text, this.color});

  final IconData icon;
  final String? text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall!.copyWith(
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: style.color),
        if (text != null) ...[
          const SizedBox(width: 4),
          Text(text!, style: style),
        ],
      ],
    );
  }
}

/// [TaskTile] com deslizar: para a direita conclui/reabre, para a esquerda
/// exclui (com desfazer).
class SwipeableTaskTile extends ConsumerStatefulWidget {
  const SwipeableTaskTile({required this.tile, super.key});

  final TaskTile tile;

  @override
  ConsumerState<SwipeableTaskTile> createState() => _SwipeableTaskTileState();
}

class _SwipeableTaskTileState extends ConsumerState<SwipeableTaskTile> {
  // Depois de deslizar para excluir, some da árvore na hora (a lista do banco
  // chega um instante depois).
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final task = widget.tile.task;
    final colors = Theme.of(context).colorScheme;
    final done = task.status == TaskStatus.feita;
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      background: _SwipeBackground(
        color: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
        icon: done ? Icons.undo : Icons.check,
        label: done ? 'Reabrir' : 'Concluir',
        alignment: AlignmentDirectional.centerStart,
      ),
      secondaryBackground: _SwipeBackground(
        color: colors.errorContainer,
        foreground: colors.onErrorContainer,
        icon: Icons.delete_outline,
        label: 'Excluir',
        alignment: AlignmentDirectional.centerEnd,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await toggleDone(ScaffoldMessenger.of(context), ref, task);
          return false; // a linha continua, só muda o estado
        }
        return true;
      },
      onDismissed: (_) {
        setState(() => _dismissed = true);
        deleteWithUndo(ScaffoldMessenger.of(context), ref, task);
      },
      child: widget.tile,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
