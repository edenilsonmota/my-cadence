import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/stats/stats_logic.dart';

import '../tasks/fixtures.dart';

DateTime d(int day, [int h = 0, int m = 0]) => DateTime(2026, 11, day, h, m);

var _n = 0;

PomodoroSession session(
  DateTime start,
  int minutes, {
  PomodoroKind kind = PomodoroKind.foco,
  String? taskId,
  bool completed = true,
  int pausedMs = 0,
}) => PomodoroSession(
  id: 's${_n++}',
  createdAt: start,
  updatedAt: start,
  dirty: true,
  taskId: taskId,
  kind: kind,
  startedAt: start,
  endedAt: start.add(Duration(minutes: minutes, milliseconds: pausedMs)),
  plannedMinutes: 25,
  pausedTotalMs: pausedMs,
  completed: completed,
);

ReviewLog review(DateTime at, int rating) => ReviewLog(
  id: 'r${_n++}',
  createdAt: at,
  updatedAt: at,
  dirty: true,
  cardId: 'c',
  rating: rating,
  reviewedAt: at,
);

Flashcard card(DateTime due, {bool suspended = false}) => Flashcard(
  id: 'c${_n++}',
  createdAt: d(1),
  updatedAt: d(1),
  dirty: true,
  front: 'f',
  back: 'b',
  state: CardState.review,
  due: due,
  suspended: suspended,
);

TaskCompletion done(DateTime occurrence) => TaskCompletion(
  id: 'k${_n++}',
  createdAt: occurrence,
  updatedAt: occurrence,
  dirty: true,
  taskId: 't',
  occurrence: occurrence,
);

void main() {
  final now = d(24, 12);

  group('períodos', () {
    test('últimos dias, semanas e meses terminam no atual', () {
      expect(lastBuckets(Bucket.dia, now, 3), [d(22), d(23), d(24)]);
      expect(lastBuckets(Bucket.semana, now, 2), [d(16), d(23)]);
      expect(lastBuckets(Bucket.mes, DateTime(2027, 1, 5), 3), [
        DateTime(2026, 11),
        DateTime(2026, 12),
        DateTime(2027),
      ]);
    });

    test('nextBucket', () {
      expect(nextBucket(Bucket.semana, d(23)), d(30));
      expect(nextBucket(Bucket.mes, DateTime(2026, 12)), DateTime(2027));
    });
  });

  group('foco', () {
    final sessions = [
      session(d(22, 9), 25, taskId: 'a'),
      session(d(24, 9), 25, taskId: 'a'),
      session(d(24, 10), 20, taskId: 'b', completed: false),
      // Pausa de 5 min não conta.
      session(d(24, 11), 25, taskId: 'b', pausedMs: 5 * 60000),
      session(d(24, 11, 30), 5, kind: PomodoroKind.pausaCurta),
      session(d(10, 9), 25), // semana anterior
    ];

    test('por dia, semana e mês, só foco e sem pausas', () {
      final days = lastBuckets(Bucket.dia, now, 3);
      expect(
        focusPerBucket(sessions, Bucket.dia, days, now).map((x) => x.inMinutes),
        [25, 0, 70],
      );
      final weeks = lastBuckets(Bucket.semana, now, 3);
      expect(
        focusPerBucket(
          sessions,
          Bucket.semana,
          weeks,
          now,
        ).map((x) => x.inMinutes),
        [25, 25, 70],
      );
      final months = lastBuckets(Bucket.mes, now, 1);
      expect(
        focusPerBucket(sessions, Bucket.mes, months, now).single.inMinutes,
        120,
      );
    });

    test('sessão em andamento conta até agora', () {
      final running = PomodoroSession(
        id: 'x',
        createdAt: now,
        updatedAt: now,
        dirty: true,
        kind: PomodoroKind.foco,
        startedAt: d(24, 11, 50),
        plannedMinutes: 25,
        pausedTotalMs: 0,
        completed: false,
      );
      expect(focusBetween([running], d(24), d(25), now).inMinutes, 10);
    });

    test('focusBy agrupa, inclui "sem chave" e ordena', () {
      final byTask = focusBy(sessions, (s) => [s.taskId], now);
      expect(byTask.map((r) => (r.key, r.total.inMinutes)), [
        ('a', 50),
        ('b', 45),
        (null, 25),
      ]);
      // Várias chaves (tags): o tempo conta para cada uma.
      final byTag = focusBy(
        sessions.where((s) => s.taskId == 'a'),
        (s) => ['x', 'y'],
        now,
      );
      expect(byTag.map((r) => r.total.inMinutes), [50, 50]);
    });

    test('estimado × realizado soma focos concluídos das subtarefas', () {
      final tasks = [
        makeTask('a').copyWith(estimatedPomodoros: const Value(4)),
        makeTask('a1', parentId: 'a'),
        makeTask('b'),
      ];
      final rows = estimatedVsDone(tasks, [
        session(d(24, 9), 25, taskId: 'a'),
        session(d(24, 10), 25, taskId: 'a1'),
        session(d(24, 11), 10, taskId: 'a1', completed: false),
        session(d(24, 12), 25, taskId: 'b'),
      ]);
      expect(rows.map((r) => (r.task.id, r.estimated, r.done)), [('a', 4, 2)]);
    });
  });

  group('revisões', () {
    final logs = [
      review(d(22, 9), 3),
      review(d(23, 9), 1),
      review(d(23, 10), 4),
      review(d(24, 8), 3),
    ];

    test('por dia e taxa de acerto', () {
      expect(reviewsPerDay(logs, [d(22), d(23), d(24)]), [1, 2, 1]);
      expect(accuracy(logs), 0.75);
      expect(accuracy([]), isNull);
    });

    test('previsão de vencidos: atrasados entram hoje, suspensos não', () {
      final cards = [
        card(d(20, 9)),
        card(d(24, 23)),
        card(d(25, 1)),
        card(d(30, 9)),
        card(d(27), suspended: true),
        card(d(31, 9)), // fora dos 7 dias
      ];
      expect(dueForecast(cards, now, 7), [2, 1, 0, 0, 0, 0, 1]);
    });

    test('sequência de dias estudando', () {
      expect(studyStreak(logs, now), 3);
      // Hoje ainda sem revisão: conta até ontem.
      expect(studyStreak(logs.take(3), now), 2);
      // Buraco ontem: zera.
      expect(studyStreak([review(d(22), 3)], now), 0);
      expect(studyStreak([], now), 0);
    });
  });

  test('heatmap de rotinas: semanas de seg a dom, futuro vazio', () {
    final grid = routineHeatmap(
      [done(d(16, 7)), done(d(24, 7)), done(d(24, 20)), done(d(1))],
      now,
      2,
    );
    expect(heatmapStart(now, 2), d(16));
    expect(grid, [
      [1, 0, 0, 0, 0, 0, 0],
      [0, 2, null, null, null, null, null],
    ]);
  });
}
