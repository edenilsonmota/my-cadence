import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/tasks/task_metrics.dart';

import 'fixtures.dart';

void main() {
  final now = DateTime(2026, 11, 24, 12);

  Flashcard card(String task, DateTime due, {bool suspended = false}) =>
      Flashcard(
        id: 'c$task$due',
        createdAt: now,
        updatedAt: now,
        dirty: true,
        taskId: task,
        front: 'f',
        back: 'b',
        state: CardState.review,
        due: due,
        suspended: suspended,
      );

  PomodoroSession focus(String task, int minutes, {PomodoroKind? kind}) =>
      PomodoroSession(
        id: 's$task$minutes',
        createdAt: now,
        updatedAt: now,
        dirty: true,
        taskId: task,
        kind: kind ?? PomodoroKind.foco,
        startedAt: DateTime(2026, 11, 24, 8),
        endedAt: DateTime(2026, 11, 24, 8, minutes),
        plannedMinutes: 25,
        pausedTotalMs: 0,
        completed: true,
        manual: false,
      );

  test('subtarefas, cards vencidos e foco por tarefa', () {
    final m = computeTaskMetrics(
      tasks: [
        makeTask('a'),
        makeTask('a1', parentId: 'a', status: TaskStatus.feita),
        makeTask('a2', parentId: 'a'),
        makeTask('b'),
      ],
      cards: [
        card('a', DateTime(2026, 11, 20)),
        card('a', DateTime(2026, 11, 30)), // ainda não venceu
        card('a', DateTime(2026, 11, 1), suspended: true),
        card('b', DateTime(2026, 11, 24, 9)),
      ],
      sessions: [
        focus('a', 25),
        focus('a', 10),
        focus('a', 5, kind: PomodoroKind.pausaCurta),
      ],
      now: now,
    );
    final a = m['a']!;
    expect(
      (a.subtasksDone, a.subtasks, a.dueCards, a.focus.inMinutes),
      (1, 2, 1, 35),
    );
    expect(m['b']!.dueCards, 1);
    expect(m.containsKey('a1'), isFalse); // nada a mostrar
  });
}
