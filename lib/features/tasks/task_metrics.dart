/// Números da linha de metadados do item de tarefa. Puro, sem Flutter.
library;

import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../pomodoro/pomodoro_logic.dart';

class TaskMetrics {
  const TaskMetrics({
    this.subtasksDone = 0,
    this.subtasks = 0,
    this.dueCards = 0,
    this.focus = Duration.zero,
  });

  final int subtasksDone;
  final int subtasks;

  /// Cards da tarefa vencidos agora (não suspensos).
  final int dueCards;

  /// Tempo de foco nas sessões da tarefa.
  final Duration focus;
}

/// Métricas por id de tarefa (só as que têm algo a mostrar).
Map<String, TaskMetrics> computeTaskMetrics({
  required Iterable<Task> tasks,
  required Iterable<Flashcard> cards,
  required Iterable<PomodoroSession> sessions,
  required DateTime now,
}) {
  final subDone = <String, int>{}, subTotal = <String, int>{};
  for (final t in tasks) {
    final parent = t.parentId;
    if (parent == null) continue;
    subTotal[parent] = (subTotal[parent] ?? 0) + 1;
    if (t.status == TaskStatus.feita) {
      subDone[parent] = (subDone[parent] ?? 0) + 1;
    }
  }
  final due = <String, int>{};
  for (final c in cards) {
    final task = c.taskId;
    if (task == null || c.suspended || c.due.isAfter(now)) continue;
    due[task] = (due[task] ?? 0) + 1;
  }
  final focus = <String, Duration>{};
  for (final s in sessions) {
    final task = s.taskId;
    if (task == null || s.kind != PomodoroKind.foco) continue;
    focus[task] = (focus[task] ?? Duration.zero) + elapsed(s, now);
  }
  return {
    for (final id in {...subTotal.keys, ...due.keys, ...focus.keys})
      id: TaskMetrics(
        subtasksDone: subDone[id] ?? 0,
        subtasks: subTotal[id] ?? 0,
        dueCards: due[id] ?? 0,
        focus: focus[id] ?? Duration.zero,
      ),
  };
}
