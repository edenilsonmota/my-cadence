/// Revisão da semana: o que foi feito, o tempo por tag e o que ficou para
/// trás. Puro, sem Flutter.
library;

import '../../core/calendar_layout.dart' show weekStart;
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../stats/stats_logic.dart';

class WeekReview {
  const WeekReview({
    required this.start,
    required this.completed,
    required this.routineDone,
    required this.focus,
    required this.byTag,
    required this.overdue,
  });

  /// Segunda-feira da semana.
  final DateTime start;
  DateTime get end => addDays(start, 7);

  /// Tarefas (não rotinas) concluídas na semana, da mais recente à mais antiga.
  final List<Task> completed;

  /// Ocorrências de rotina concluídas na semana.
  final int routineDone;

  /// Tempo de foco (pomodoros e tempo manual) iniciado na semana.
  final Duration focus;

  /// Foco por tag (cada tag recebe o tempo inteiro; subtarefa herda da mãe);
  /// chave `null` = sem tag.
  final List<({String? key, Duration total})> byTag;

  /// Ativas com prazo antes de hoje (só na semana atual), da mais antiga.
  final List<Task> overdue;
}

WeekReview buildWeekReview({
  required DateTime weekOf,
  required DateTime now,
  required Iterable<Task> tasks,
  required Iterable<PomodoroSession> sessions,
  required Iterable<TaskCompletion> completions,
  required Map<String, Set<String>> tagsOf,
}) {
  final start = weekStart(startOfDay(weekOf));
  final end = addDays(start, 7);
  bool inWeek(DateTime? d) =>
      d != null && !d.isBefore(start) && d.isBefore(end);

  final live = [
    for (final t in tasks)
      if (t.deletedAt == null) t,
  ];
  final completed = [
    for (final t in live)
      if (t.status == TaskStatus.feita &&
          t.recurrenceRule == null &&
          inWeek(t.completedAt))
        t,
  ]..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

  final weekSessions = [
    for (final s in sessions)
      if (s.deletedAt == null && inWeek(s.startedAt)) s,
  ];
  final parentOf = {for (final t in live) t.id: t.parentId};
  final today = startOfDay(now);
  final current = !today.isBefore(start) && today.isBefore(end);

  return WeekReview(
    start: start,
    completed: completed,
    routineDone: [
      for (final c in completions)
        if (c.deletedAt == null && inWeek(c.occurrence)) c,
    ].length,
    focus: focusBetween(weekSessions, start, end, now),
    byTag: focusBy(
      weekSessions,
      (s) => tagsWithAncestors(s.taskId, parentOf, tagsOf),
      now,
    ),
    overdue: current
        ? ([
            for (final t in live)
              if (t.status.isActive &&
                  t.dueAt != null &&
                  t.dueAt!.isBefore(today))
                t,
          ]..sort((a, b) => a.dueAt!.compareTo(b.dueAt!)))
        : const [],
  );
}
