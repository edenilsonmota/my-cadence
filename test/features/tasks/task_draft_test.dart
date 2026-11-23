import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/tasks/task_draft.dart';

import 'fixtures.dart';

final now = DateTime(2026, 11, 23, 10, 15);

void main() {
  test('título obrigatório', () {
    expect(TaskDraft().validate(now), 'Informe o título.');
    expect(TaskDraft(title: '  ').validate(now), 'Informe o título.');
    expect(TaskDraft(title: 'Ler').validate(now), isNull);
  });

  test('dia inteiro grava só a data', () {
    final fields = TaskDraft(
      title: 'Ler',
      dueDate: DateTime(2026, 11, 25),
      dueTime: (hour: 14, minute: 0),
    ).toFields(now);
    expect(fields.hasTime, isFalse);
    expect(fields.dueAt, DateTime(2026, 11, 25));
  });

  test('com hora combina data e hora; sem hora escolhida usa 9h', () {
    final fields = TaskDraft(
      title: 'Reunião',
      allDay: false,
      startDate: DateTime(2026, 11, 25),
      dueDate: DateTime(2026, 11, 25),
      dueTime: (hour: 14, minute: 30),
    ).toFields(now);
    expect(fields.hasTime, isTrue);
    expect(fields.startAt, DateTime(2026, 11, 25, 9));
    expect(fields.dueAt, DateTime(2026, 11, 25, 14, 30));
  });

  test('recorrência sem prazo define o prazo como hoje', () {
    final fields = TaskDraft(
      title: 'Correr',
      repeat: Repeat.semanal,
      interval: 2,
      weekdays: {DateTime.monday, DateTime.thursday},
    ).toFields(now);
    expect(fields.dueAt, DateTime(2026, 11, 23));
    expect(fields.recurrenceRule, 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,TH');
  });

  test('alarme sem prazo é descartado', () {
    final fields = TaskDraft(
      title: 'Ler',
      reminderMinutesBefore: 10,
    ).toFields(now);
    expect(fields.reminderMinutesBefore, isNull);
  });

  test('início depois do prazo é inválido', () {
    final draft = TaskDraft(
      title: 'Ler',
      startDate: DateTime(2026, 11, 26),
      dueDate: DateTime(2026, 11, 25),
    );
    expect(draft.validate(now), 'O início deve ser antes do prazo.');
  });

  test('fim da repetição antes do prazo é inválido', () {
    final draft = TaskDraft(
      title: 'Ler',
      dueDate: DateTime(2026, 11, 25),
      repeat: Repeat.diaria,
      until: DateTime(2026, 11, 24),
    );
    expect(
      draft.validate(now),
      'A data final da repetição é anterior ao prazo.',
    );
  });

  test('ida e volta a partir de uma tarefa', () {
    final task =
        makeTask(
          'x',
          title: 'Estudar',
          kind: TaskKind.estudo,
          priority: 2,
          dueAt: DateTime(2026, 11, 25, 18, 45),
          hasTime: true,
        ).copyWith(
          recurrenceRule: const Value('FREQ=DAILY;INTERVAL=2;UNTIL=20261231'),
          reminderMinutesBefore: const Value(15),
          estimatedPomodoros: const Value(3),
        );

    final draft = TaskDraft.fromTask(task, {'tag1'});
    expect(draft.allDay, isFalse);
    expect(draft.dueTime, (hour: 18, minute: 45));
    expect(draft.repeat, Repeat.diaria);
    expect(draft.interval, 2);
    expect(draft.until, DateTime(2026, 12, 31));
    expect(draft.tagIds, {'tag1'});

    final fields = draft.toFields(now);
    final saved = fields.applyTo(task);
    expect(saved.dueAt, task.dueAt);
    expect(saved.hasTime, isTrue);
    expect(saved.recurrenceRule, task.recurrenceRule);
    expect(saved.reminderMinutesBefore, 15);
    expect(saved.estimatedPomodoros, 3);
    expect(saved.kind, TaskKind.estudo);
    expect(saved.priority, 2);
  });
}
