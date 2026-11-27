import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/week/week_review_logic.dart';

import '../tasks/fixtures.dart';

DateTime d(int day, [int h = 0]) => DateTime(2026, 11, day, h);

PomodoroSession focus(String task, DateTime start, int minutes) =>
    PomodoroSession(
      id: '$task$start',
      createdAt: start,
      updatedAt: start,
      dirty: true,
      taskId: task,
      kind: PomodoroKind.foco,
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      plannedMinutes: minutes,
      pausedTotalMs: 0,
      completed: true,
      manual: false,
    );

TaskCompletion done(
  String task,
  DateTime at, {
  OccurrenceStatus status = OccurrenceStatus.concluida,
}) => TaskCompletion(
  id: '$task$at',
  createdAt: at,
  updatedAt: at,
  dirty: true,
  taskId: task,
  occurrence: at,
  status: status,
);

void main() {
  // Quarta, 25/11/2026: a semana vai de 23 (segunda) a 29.
  final now = d(25, 15);

  test('resume a semana atual', () {
    final r = buildWeekReview(
      weekOf: now,
      now: now,
      tasks: [
        makeTask('feita')
            .copyWith(status: TaskStatus.feita, completedAt: Value(d(24, 10))),
        makeTask('antiga').copyWith(
          status: TaskStatus.feita,
          completedAt: Value(d(20, 10)), // semana passada
        ),
        makeTask('atrasada', dueAt: d(22)),
        makeTask('pausada', dueAt: d(21)).copyWith(status: TaskStatus.pausada),
        makeTask('futura', dueAt: d(27)),
        makeTask('estudo'),
      ],
      sessions: [
        focus('estudo', d(24, 9), 60),
        focus('estudo', d(18, 9), 30), // fora
      ],
      completions: [done('rotina', d(23)), done('rotina', d(24))],
      tagsOf: {
        'estudo': {'estudos', 'ingles'},
      },
    );
    expect(r.start, d(23));
    expect(r.completed.map((t) => t.id), ['feita']);
    expect(r.routineDone, 2);
    expect(r.focus.inMinutes, 60);
    expect(
      {for (final t in r.byTag) t.key: t.total.inMinutes},
      {'estudos': 60, 'ingles': 60},
    );
    expect(r.overdue.map((t) => t.id), ['atrasada']);
  });

  test('semana passada não lista atrasadas', () {
    final r = buildWeekReview(
      weekOf: d(18),
      now: now,
      tasks: [makeTask('atrasada', dueAt: d(17))],
      sessions: const [],
      completions: const [],
      tagsOf: const {},
    );
    expect(r.start, d(16));
    expect(r.overdue, isEmpty);
  });
}
