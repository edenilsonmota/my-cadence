import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/tasks/task_template.dart';

import 'fixtures.dart';

void main() {
  test('ida e volta do modelo, sem datas', () {
    final task =
        makeTask(
          'a',
          title: 'Prova',
          priority: 2,
          dueAt: DateTime(2026, 12, 1),
        ).copyWith(
          colorKey: const Value('rosa'),
          estimatedMinutes: const Value(90),
          reminderOffsets: const Value('0,1440'),
          reminderMode: ReminderMode.alarme,
        );
    final data = TaskTemplateData.fromTask(
      task,
      tagIds: ['t1'],
      deckIds: ['d1'],
      subtasks: ['Resumo', 'Exercícios'],
    );
    final back = TaskTemplateData.decode(data.encode());
    expect(back.title, 'Prova');
    expect(
      (back.priority, back.colorKey, back.estimatedMinutes),
      (2, 'rosa', 90),
    );
    expect(
      (back.reminderOffsets, back.reminderMode),
      ('0,1440', ReminderMode.alarme),
    );
    expect(back.tagIds, ['t1']);
    expect(back.deckIds, ['d1']);
    expect(back.subtasks, ['Resumo', 'Exercícios']);
    expect(data.encode().contains('dueAt'), isFalse);
  });

  test('JSON quebrado ou incompleto cai no padrão', () {
    final data = TaskTemplateData.decode('lixo', fallbackTitle: 'Nome');
    expect(data.title, 'Nome');
    expect(data.reminderMode, ReminderMode.notificacao);
    expect(TaskTemplateData.decode('{"priority": 9}').priority, 3);
  });
}
