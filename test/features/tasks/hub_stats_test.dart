import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/tasks/hub/hub_stats.dart';
import 'package:my_cadence/features/tasks/hub/hub_tools.dart';

import 'fixtures.dart';

final now = DateTime(2026, 11, 23, 12);

PomodoroSession session(
  String id, {
  PomodoroKind kind = PomodoroKind.foco,
  required DateTime start,
  DateTime? end,
  DateTime? pausedAt,
  int pausedMs = 0,
  bool completed = false,
}) => PomodoroSession(
  id: id,
  createdAt: start,
  updatedAt: start,
  dirty: true,
  kind: kind,
  startedAt: start,
  endedAt: end,
  plannedMinutes: 25,
  pausedAt: pausedAt,
  pausedTotalMs: pausedMs,
  completed: completed,
  manual: false,
);

Flashcard card(String id, {required DateTime due, bool suspended = false}) =>
    Flashcard(
      id: id,
      createdAt: now,
      updatedAt: now,
      dirty: true,
      front: 'f',
      back: 'v',
      state: CardState.review,
      due: due,
      suspended: suspended,
    );

void main() {
  test('subtreeIds pega todos os níveis e só a árvore pedida', () {
    final tasks = [
      makeTask('raiz'),
      makeTask('a', parentId: 'raiz'),
      makeTask('a1', parentId: 'a'),
      makeTask('b', parentId: 'raiz'),
      makeTask('outra'),
      makeTask('x', parentId: 'outra'),
    ];
    expect(
      subtreeIds(tasks, 'raiz'),
      unorderedEquals(['raiz', 'a', 'b', 'a1']),
    );
    expect(subtreeIds(tasks, 'a1'), ['a1']);
  });

  group('foco', () {
    test(
      'desconta pausas, conta a sessão em andamento e ignora pausas do ciclo',
      () {
        final summary = summarizeFocus([
          session(
            '1',
            start: DateTime(2026, 11, 23, 9),
            end: DateTime(2026, 11, 23, 9, 25),
            completed: true,
          ),
          session(
            '2',
            start: DateTime(2026, 11, 23, 10),
            end: DateTime(2026, 11, 23, 10, 30),
            pausedMs: 10 * 60 * 1000,
          ),
          session('3', start: DateTime(2026, 11, 23, 11, 50)), // em andamento
          session(
            '4',
            start: DateTime(2026, 11, 23, 11),
            pausedAt: DateTime(2026, 11, 23, 11, 5),
          ), // pausada
          session(
            'pausa',
            kind: PomodoroKind.pausaCurta,
            start: DateTime(2026, 11, 23, 9, 25),
            end: DateTime(2026, 11, 23, 9, 30),
            completed: true,
          ),
        ], now);

        expect(summary.sessions, 4);
        expect(summary.completed, 1);
        // 25 + (30 - 10) + 10 (até agora) + 5 (até a pausa) = 60 min
        expect(summary.total, const Duration(minutes: 60));
      },
    );

    test('formatDuration', () {
      expect(formatDuration(Duration.zero), '0 min');
      expect(formatDuration(const Duration(minutes: 25)), '25 min');
      expect(formatDuration(const Duration(minutes: 65)), '1 h 05 min');
    });
  });

  test('countCards: vencidos até agora e não suspensos', () {
    final counts = countCards([
      card('a', due: now.subtract(const Duration(days: 1))),
      card('b', due: now),
      card('c', due: now.add(const Duration(minutes: 1))),
      card('d', due: now.subtract(const Duration(days: 1)), suspended: true),
    ], now);
    expect(counts.total, 4);
    expect(counts.due, 2);
  });

  test(
    'estudo mostra sempre as três ferramentas; os outros só com conteúdo',
    () {
      final study = visibleTools(
        kind: TaskKind.estudo,
        hasCards: false,
        hasPomodoro: false,
        hasPages: false,
      );
      expect(study, (cards: true, pomodoro: true, pages: true));

      final simple = visibleTools(
        kind: TaskKind.simples,
        hasCards: true,
        hasPomodoro: false,
        hasPages: false,
      );
      expect(simple, (cards: true, pomodoro: false, pages: false));
    },
  );
}
