import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/calendar/calendar_entries.dart';

import '../tasks/fixtures.dart';

DateTime d(int day, [int h = 0, int m = 0]) => DateTime(2026, 11, day, h, m);

TaskCompletion completion(String taskId, DateTime occurrence) => TaskCompletion(
  id: 'c-$taskId-${occurrence.day}',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  dirty: true,
  taskId: taskId,
  occurrence: occurrence,
);

void main() {
  final weekFrom = d(23), weekTo = d(30);

  group('taskSpan', () {
    test('início e prazo com hora viram o bloco', () {
      final s = taskSpan(
        makeTask('a', startAt: d(24, 9), dueAt: d(24, 10, 30), hasTime: true),
      )!;
      expect((s.start, s.end, s.allDay), (d(24, 9), d(24, 10, 30), false));
    });

    test('só prazo com hora: bloco de 30 min a partir do prazo', () {
      final s = taskSpan(makeTask('a', dueAt: d(24, 14), hasTime: true))!;
      expect((s.start, s.end), (d(24, 14), d(24, 14, 30)));
    });

    test('dia inteiro cobre do início ao prazo, inclusive', () {
      final s = taskSpan(makeTask('a', startAt: d(24), dueAt: d(26)))!;
      expect((s.start, s.end, s.allDay), (d(24), d(27), true));
    });

    test('sem data: fora do calendário', () {
      expect(taskSpan(makeTask('a')), isNull);
    });
  });

  group('expandOccurrences', () {
    test('tarefas simples dentro e fora do intervalo', () {
      final entries = expandOccurrences(
        [
          makeTask('dentro', dueAt: d(24, 9), hasTime: true),
          makeTask('antes', dueAt: d(20, 9), hasTime: true),
          makeTask('depois', dueAt: d(30, 9), hasTime: true),
          makeTask('sem data'),
        ],
        weekFrom,
        weekTo,
      );
      expect(entries.map((e) => e.task.id), ['dentro']);
    });

    test('tarefa de vários dias que começa antes entra', () {
      final entries = expandOccurrences(
        [makeTask('viagem', startAt: d(20), dueAt: d(24))],
        weekFrom,
        weekTo,
      );
      expect(entries.single.start, d(20));
      expect(entries.single.occursOn(d(23)), isTrue);
      expect(entries.single.occursOn(d(25)), isFalse);
    });

    test('rotina diária: real no prazo e virtuais até o fim da semana', () {
      final entries = expandOccurrences(
        [
          makeTask(
            'r',
            kind: TaskKind.rotina,
            startAt: d(25, 7),
            dueAt: d(25, 7, 45),
            hasTime: true,
            recurrenceRule: 'FREQ=DAILY',
          ),
        ],
        weekFrom,
        weekTo,
      );
      expect(entries.map((e) => e.start), [
        for (var day = 25; day <= 29; day++) d(day, 7),
      ]);
      expect(entries.map((e) => e.virtual), [false, true, true, true, true]);
      expect(
        entries.every((e) => e.end.difference(e.start).inMinutes == 45),
        isTrue,
      );
    });

    test('rotina semanal com BYDAY e UNTIL', () {
      final entries = expandOccurrences(
        [
          makeTask(
            'r',
            dueAt: d(23), // segunda, dia inteiro
            recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20261125',
          ),
        ],
        weekFrom,
        weekTo,
      );
      expect(entries.map((e) => e.start), [d(23), d(25)]);
      expect(entries.every((e) => e.allDay), isTrue);
    });

    test('rotina atrasada continua gerando as ocorrências seguintes', () {
      final entries = expandOccurrences(
        [
          makeTask(
            'r',
            dueAt: d(10, 8),
            hasTime: true,
            recurrenceRule: 'FREQ=DAILY;INTERVAL=2',
          ),
        ],
        weekFrom,
        weekTo,
      );
      // 10, 12, ..., 22 ficam antes; 24, 26 e 28 aparecem como virtuais.
      expect(entries.map((e) => e.start), [d(24, 8), d(26, 8), d(28, 8)]);
      expect(entries.every((e) => e.virtual), isTrue);
    });

    test('rotina concluída de vez (feita) aparece uma vez, esmaecida', () {
      final entries = expandOccurrences(
        [
          makeTask(
            'r',
            dueAt: d(24, 8),
            hasTime: true,
            status: TaskStatus.feita,
            recurrenceRule: 'FREQ=DAILY',
          ),
        ],
        weekFrom,
        weekTo,
      );
      expect(entries.single.done, isTrue);
      expect(entries.single.virtual, isFalse);
    });

    test('histórico da rotina vira ocorrências concluídas', () {
      final routine = makeTask(
        'r',
        startAt: d(26, 6, 30),
        dueAt: d(26, 7),
        hasTime: true,
        recurrenceRule: 'FREQ=DAILY',
      );
      final entries = expandOccurrences(
        [routine],
        weekFrom,
        d(27),
        completions: [
          completion('r', d(24, 7)),
          completion('r', d(25, 7)),
          completion('outra', d(25, 7)),
        ],
      );
      expect(entries.map((e) => (e.start, e.end, e.done)), [
        (d(24, 6, 30), d(24, 7), true),
        (d(25, 6, 30), d(25, 7), true),
        (d(26, 6, 30), d(26, 7), false),
      ]);
      expect(entries.first.movable, isFalse);
      expect(entries.last.movable, isTrue);
    });

    test('regra inválida mostra só a ocorrência atual', () {
      final entries = expandOccurrences(
        [makeTask('r', dueAt: d(24), recurrenceRule: 'FREQ=MONTHLY')],
        weekFrom,
        weekTo,
      );
      expect(entries, hasLength(1));
    });
  });

  test('entriesOfDay separa dia inteiro e com hora', () {
    final entries = expandOccurrences(
      [
        makeTask('a', dueAt: d(24)),
        makeTask('b', dueAt: d(24, 9), hasTime: true),
        makeTask('c', dueAt: d(25, 9), hasTime: true),
      ],
      weekFrom,
      weekTo,
    );
    final day = entriesOfDay(entries, d(24));
    expect(day.allDay.map((e) => e.task.id), ['a']);
    expect(day.timed.map((e) => e.task.id), ['b']);
  });

  group('reagendar', () {
    test('mover desloca início e prazo juntos', () {
      final entry = expandOccurrences(
        [makeTask('a', startAt: d(24, 9), dueAt: d(24, 10), hasTime: true)],
        weekFrom,
        weekTo,
      ).single;
      expect(moveEntry(entry, d(25, 14, 15)), (
        startAt: d(25, 14, 15),
        dueAt: d(25, 15, 15),
      ));
    });

    test('mover só com prazo mantém o início vazio', () {
      final entry = expandOccurrences(
        [makeTask('a', dueAt: d(24, 9), hasTime: true)],
        weekFrom,
        weekTo,
      ).single;
      expect(moveEntry(entry, d(24, 11)), (startAt: null, dueAt: d(24, 11)));
    });

    test('mover ocorrência virtual da rotina move a série toda', () {
      final virtual = expandOccurrences(
        [
          makeTask(
            'r',
            dueAt: d(24, 7),
            hasTime: true,
            recurrenceRule: 'FREQ=DAILY',
          ),
        ],
        weekFrom,
        weekTo,
      )[2]; // dia 26
      expect(virtual.virtual, isTrue);
      expect(moveEntry(virtual, d(26, 8)), (startAt: null, dueAt: d(24, 8)));
    });

    test('redimensionar dá início e prazo explícitos', () {
      final entry = expandOccurrences(
        [makeTask('a', dueAt: d(24, 9), hasTime: true)],
        weekFrom,
        weekTo,
      ).single;
      expect(resizeEntry(entry, d(24, 10, 15)), (
        startAt: d(24, 9),
        dueAt: d(24, 10, 15),
      ));
      // Nunca menos de 15 min.
      expect(resizeEntry(entry, d(24, 8)), (
        startAt: d(24, 9),
        dueAt: d(24, 9, 15),
      ));
    });

    test('redimensionar ocorrência virtual usa a duração na série', () {
      final virtual = expandOccurrences(
        [
          makeTask(
            'r',
            startAt: d(24, 7),
            dueAt: d(24, 7, 30),
            hasTime: true,
            recurrenceRule: 'FREQ=DAILY',
          ),
        ],
        weekFrom,
        weekTo,
      )[1]; // dia 25
      expect(resizeEntry(virtual, d(25, 8)), (
        startAt: d(24, 7),
        dueAt: d(24, 8),
      ));
    });
  });

  test('nextUpcoming ignora passadas, concluídas e dia inteiro', () {
    final entries = expandOccurrences(
      [
        makeTask('passada', dueAt: d(24, 9), hasTime: true),
        makeTask(
          'feita',
          dueAt: d(24, 13),
          hasTime: true,
          status: TaskStatus.feita,
        ),
        makeTask('dia', dueAt: d(24)),
        makeTask('depois', dueAt: d(24, 16), hasTime: true),
        makeTask('proxima', dueAt: d(24, 14), hasTime: true),
      ],
      weekFrom,
      weekTo,
    );
    expect(nextUpcoming(entries, d(24, 12))?.task.id, 'proxima');
    expect(nextUpcoming(entries, d(24, 17)), isNull);
  });
}
