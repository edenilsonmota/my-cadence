import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/dates.dart';
import '../../../data/db/database.dart';
import '../../../data/db/enums.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/appearance_badge.dart';
import '../../../shared/widgets/pressable.dart';
import '../hub/hub_stats.dart' show formatDuration;
import '../reminder_offsets.dart';
import '../task_delete.dart';
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
  final l10n = messenger.context.l10n;
  final lang = messenger.context.lang;
  final next = updated.dueAt;
  final message = updated.status == TaskStatus.feita || next == null
      ? l10n.routineEnded
      : l10n.routineNext(
          formatRelative(next, today, withTime: updated.hasTime, lang: lang),
        );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Exclui a tarefa (e subtarefas) e oferece "Desfazer" no SnackBar.
Future<void> deleteWithUndo(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
  Task task, {
  TaskDeletePlan plan = TaskDeletePlan.none,
}) async {
  final l10n = messenger.context.l10n;
  // Lidos antes de qualquer await: quem chamou pode sair da árvore.
  final repo = ref.read(tasksRepositoryProvider);
  final books = ref.read(booksRepositoryProvider);
  final cards = ref.read(cardsRepositoryProvider);
  final ids = await repo.deleteTask(task.id);
  for (final id in plan.notebookIds) {
    await books.deleteNotebook(id);
  }
  for (final id in plan.pageIds) {
    await books.deletePage(id);
  }
  for (final id in plan.deckIds) {
    await cards.deleteDeck(id);
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          ids.length > 1
              ? l10n.taskDeletedWithSubtasks(task.title, ids.length - 1)
              : l10n.taskDeleted(task.title),
        ),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => repo.restoreTasks(ids),
        ),
      ),
    );
}

/// Item de tarefa: checkbox circular na cor da tarefa, ícone no quadrado
/// suave, título e uma linha de metadados (só o que existe).
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

  /// Destaca o prazo em cor de perigo quando já passou.
  final bool showOverdue;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  /// Estado mostrado durante a animação, antes de gravar no banco.
  bool? _pendingDone;

  bool get _done => _pendingDone ?? widget.task.status == TaskStatus.feita;

  Future<void> _toggle() async {
    final completing = !_done;
    setState(() => _pendingDone = completing);
    if (completing) unawaited(HapticFeedback.lightImpact());
    await Future<void>.delayed(context.motion.base);
    if (!mounted) return;
    await toggleDone(ScaffoldMessenger.of(context), ref, widget.task);
    if (mounted) setState(() => _pendingDone = null);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final colors = context.colors;
    final space = context.space;
    final palette = context.palette;
    final resolver = ref.watch(appearanceResolverProvider);
    final metrics = ref.watch(taskMetricsProvider)[task.id];
    final tones = palette.byName(resolver.colorKeyOf(task));
    final icon = AppIcons.of(
      resolver.iconKeyOf(task),
      fallback: AppIcons.taskDefault(repeats: task.recurrenceRule != null),
    );
    final overdue =
        widget.showOverdue &&
        !_done &&
        task.dueAt != null &&
        task.dueAt!.isBefore(widget.today);

    final l10n = context.l10n;
    final lang = context.lang;
    final meta = <Widget>[
      if (task.dueAt case final due?)
        _Meta(
          icon: task.hasTime ? AppIcons.time : AppIcons.date,
          text: formatRelative(
            due,
            widget.today,
            withTime: task.hasTime,
            lang: lang,
          ),
          color: overdue ? palette.danger.strong : null,
        ),
      if (task.recurrenceRule != null) const _Meta(icon: AppIcons.repeat),
      if (effectiveReminderOffsets(task).isNotEmpty)
        const _Meta(icon: AppIcons.alarm),
      if (metrics != null && metrics.subtasks > 0)
        _Meta(
          icon: AppIcons.subtask,
          text: '${metrics.subtasksDone}/${metrics.subtasks}',
        ),
      if (metrics != null && metrics.dueCards > 0)
        _Meta(icon: AppIcons.flashcard, text: '${metrics.dueCards}'),
      if (metrics != null && metrics.focus.inMinutes > 0)
        _Meta(icon: AppIcons.pomodoro, text: formatDuration(metrics.focus)),
      if (task.status == TaskStatus.fazendo)
        _Meta(icon: AppIcons.play, text: task.status.labelFor(l10n)),
      if (task.status == TaskStatus.pausada)
        _Meta(icon: AppIcons.pause, text: task.status.labelFor(l10n)),
    ];
    final flag = switch (task.priority) {
      3 => palette.danger.strong,
      2 => palette.warning.strong,
      1 => colors.onSurfaceVariant,
      _ => null,
    };

    return Pressable(
      child: InkWell(
        onTap: () => context.push(Routes.task(task.id)),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            space.xs + 24.0 * widget.depth,
            space.sm,
            space.sm,
            space.sm,
          ),
          child: Row(
            children: [
              _CircleCheck(done: _done, color: tones.strong, onTap: _toggle),
              SizedBox(width: space.xs),
              Opacity(
                opacity: _done ? 0.5 : 1,
                child: AppearanceBadge(
                  colorKey: resolver.colorKeyOf(task),
                  icon: icon,
                  size: AppIconSize.meta,
                ),
              ),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: context.motion.base,
                      style: context.text.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _done
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                        decoration: _done ? TextDecoration.lineThrough : null,
                        decorationColor: colors.onSurfaceVariant,
                      ),
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      SizedBox(height: space.xxs),
                      Wrap(
                        spacing: space.md,
                        runSpacing: space.xxs,
                        children: meta,
                      ),
                    ],
                  ],
                ),
              ),
              if (flag != null)
                Padding(
                  padding: EdgeInsets.only(left: space.sm),
                  child: Icon(
                    AppIcons.priority,
                    size: AppIconSize.meta,
                    color: flag,
                    semanticLabel: l10n.fieldPriority,
                  ),
                ),
              ?widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Checkbox redondo na cor da tarefa, com o check animado.
class _CircleCheck extends StatelessWidget {
  const _CircleCheck({
    required this.done,
    required this.color,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final motion = context.motion;
    return Semantics(
      checked: done,
      button: true,
      label: done ? l10n.actionReopen : l10n.actionComplete,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: motion.base,
              curve: motion.standard,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? color : null,
                border: Border.all(color: color, width: 2),
              ),
              child: AnimatedScale(
                scale: done ? 1 : 0,
                duration: motion.base,
                curve: motion.enter,
                child: Icon(
                  AppIcons.check,
                  size: AppIconSize.meta,
                  color: context.colors.surface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, this.text, this.color});

  final IconData icon;
  final String? text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodySmall!.copyWith(
      color: color ?? context.colors.onSurfaceVariant,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIconSize.meta - 2, color: style.color),
        if (text != null) ...[
          SizedBox(width: context.space.xs),
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
  TaskDeletePlan _plan = TaskDeletePlan.none;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final l10n = context.l10n;
    final task = widget.tile.task;
    final colors = Theme.of(context).colorScheme;
    final done = task.status == TaskStatus.feita;
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      background: _SwipeBackground(
        color: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
        icon: done ? AppIcons.undo : AppIcons.check,
        label: done ? l10n.actionReopen : l10n.actionComplete,
        alignment: AlignmentDirectional.centerStart,
      ),
      secondaryBackground: _SwipeBackground(
        color: colors.errorContainer,
        foreground: colors.onErrorContainer,
        icon: AppIcons.delete,
        label: l10n.actionDelete,
        alignment: AlignmentDirectional.centerEnd,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await toggleDone(ScaffoldMessenger.of(context), ref, task);
          return false; // a linha continua, só muda o estado
        }
        final plan = await askDeleteExtras(context, ref, task);
        if (plan == null) return false;
        _plan = plan;
        return true;
      },
      onDismissed: (_) {
        setState(() => _dismissed = true);
        deleteWithUndo(ScaffoldMessenger.of(context), ref, task, plan: _plan);
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
          padding: EdgeInsets.symmetric(horizontal: context.space.xl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground),
              SizedBox(width: context.space.sm),
              Text(
                label,
                style: context.text.labelLarge!.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
