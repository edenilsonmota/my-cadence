import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late TasksRepository repo;

  setUp(() {
    db = openTestDb();
    repo = TasksRepository(db.tasksDao, db.tagsDao);
  });

  group('tarefas', () {
    test('cria com todos os campos e lê de volta', () async {
      final due = DateTime(2026, 11, 24, 18);
      final id = await repo.createTask(
        title: 'Estudar FSRS',
        kind: TaskKind.estudo,
        notes: 'Ler o paper',
        priority: 3,
        startAt: DateTime(2026, 11, 24, 17),
        dueAt: due,
        hasTime: true,
        recurrenceRule: 'FREQ=DAILY',
        reminderMinutesBefore: 10,
        estimatedPomodoros: 4,
        colorKey: 'teal',
        iconKey: 'brain',
      );

      final task = (await repo.getTask(id))!;
      expect(task.title, 'Estudar FSRS');
      expect(task.kind, TaskKind.estudo);
      expect(task.status, TaskStatus.aFazer);
      expect(task.priority, 3);
      expect(task.dueAt, due);
      expect(task.hasTime, isTrue);
      expect(task.recurrenceRule, 'FREQ=DAILY');
      expect(task.reminderMinutesBefore, 10);
      expect(task.estimatedPomodoros, 4);
      expect((task.colorKey, task.iconKey), ('teal', 'brain'));
    });

    test('prioridade fora de 0..3 é rejeitada pelo banco', () async {
      expect(
        () => repo.createTask(title: 'x', priority: 4),
        throwsA(isA<SqliteException>()),
      );
    });

    test('salva status e conclusão', () async {
      final id = await repo.createTask(title: 'Ler');
      final done = DateTime(2026, 11, 23, 20);
      final task = (await repo.getTask(id))!;

      await repo.saveTask(
        task.copyWith(status: TaskStatus.feita, completedAt: Value(done)),
      );

      final saved = (await repo.getTask(id))!;
      expect(saved.status, TaskStatus.feita);
      expect(saved.completedAt, done);
    });

    test('raízes, subtarefas e ordenação', () async {
      final root = await repo.createTask(title: 'Projeto');
      await repo.createTask(title: 'B', parentId: root, sortOrder: 2);
      await repo.createTask(title: 'A', parentId: root, sortOrder: 1);
      await repo.createTask(title: 'Outra raiz', sortOrder: 1);

      final roots = await repo.watchRootTasks().first;
      expect(roots.map((t) => t.title), ['Projeto', 'Outra raiz']);

      final subtasks = await repo.watchSubtasks(root).first;
      expect(subtasks.map((t) => t.title), ['A', 'B']);
    });

    test('excluir apaga a árvore inteira e só ela', () async {
      final root = await repo.createTask(title: 'Raiz');
      final child = await repo.createTask(title: 'Filha', parentId: root);
      final grandchild = await repo.createTask(title: 'Neta', parentId: child);
      final other = await repo.createTask(title: 'Outra');

      expect(await repo.taskTreeIds(root), [root, child, grandchild]);
      await repo.deleteTask(root);

      for (final id in [root, child, grandchild]) {
        expect(await repo.getTask(id), isNull);
        expect((await rawRow(db, 'tasks', id))['deleted_at'], isNotNull);
      }
      expect(await repo.getTask(other), isNotNull);
    });

    test('prazo no intervalo [de, até)', () async {
      await repo.createTask(title: 'Ontem', dueAt: DateTime(2026, 11, 22, 23));
      await repo.createTask(title: 'Hoje cedo', dueAt: DateTime(2026, 11, 23));
      await repo.createTask(title: 'Hoje', dueAt: DateTime(2026, 11, 23, 15));
      await repo.createTask(title: 'Amanhã', dueAt: DateTime(2026, 11, 24));
      await repo.createTask(title: 'Sem data');

      final today = await repo
          .watchTasksDueBetween(DateTime(2026, 11, 23), DateTime(2026, 11, 24))
          .first;
      expect(today.map((t) => t.title), ['Hoje cedo', 'Hoje']);
    });

    test('watch emite de novo quando a tarefa muda', () async {
      final id = await repo.createTask(title: 'Ler');
      final titles = repo.watchTask(id).map((t) => t?.title);
      final expectation = expectLater(
        titles,
        emitsInOrder(['Ler', 'Ler mais', null]),
      );

      await pumpEventQueue();
      final task = (await repo.getTask(id))!;
      await repo.saveTask(task.copyWith(title: 'Ler mais'));
      await pumpEventQueue();
      await repo.deleteTask(id);
      await expectation;
    });
  });

  group('conclusões de rotina', () {
    test('tarefa simples: completeTask marca feita', () async {
      final id = await repo.createTask(title: 'Ler');
      final done = await repo.completeTask(id, now: DateTime(2026, 11, 23, 8));
      expect(done!.status, TaskStatus.feita);
      expect(done.completedAt, DateTime(2026, 11, 23, 8));
      expect(await repo.watchCompletions(id).first, isEmpty);
    });

    test('rotina: registra, avança o prazo e reabre o checklist', () async {
      final id = await repo.createTask(
        title: 'Treino',
        kind: TaskKind.rotina,
        dueAt: DateTime(2026, 11, 23, 7),
        startAt: DateTime(2026, 11, 23, 6),
        hasTime: true,
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,TH',
      );
      final sub = await repo.createTask(title: 'Alongar', parentId: id);
      await repo.setStatus(sub, TaskStatus.feita);

      final updated = await repo.completeTask(
        id,
        now: DateTime(2026, 11, 23, 7, 30),
      );

      expect(updated!.status, TaskStatus.aFazer);
      expect(updated.completedAt, isNull);
      expect(updated.dueAt, DateTime(2026, 11, 26, 7));
      expect(updated.startAt, DateTime(2026, 11, 26, 6));
      expect((await repo.getTask(sub))!.status, TaskStatus.aFazer);
      final history = await repo.watchCompletions(id).first;
      expect(history.single.occurrence, DateTime(2026, 11, 23, 7));
    });

    test('rotina na última ocorrência fica feita', () async {
      final id = await repo.createTask(
        title: 'Curso',
        dueAt: DateTime(2026, 11, 23),
        recurrenceRule: 'FREQ=DAILY;UNTIL=20261123',
      );
      final updated = await repo.completeTask(
        id,
        now: DateTime(2026, 11, 23, 9),
      );
      expect(updated!.status, TaskStatus.feita);
      expect(updated.dueAt, DateTime(2026, 11, 23));
      expect(await repo.watchCompletions(id).first, hasLength(1));
    });

    test('registra, lista da mais recente e desfaz', () async {
      final id = await repo.createTask(title: 'Correr', kind: TaskKind.rotina);
      await repo.addCompletion(id, DateTime(2026, 11, 21));
      final last = await repo.addCompletion(id, DateTime(2026, 11, 22));

      var list = await repo.watchCompletions(id).first;
      expect(list.map((c) => c.occurrence), [
        DateTime(2026, 11, 22),
        DateTime(2026, 11, 21),
      ]);

      await repo.deleteCompletion(last);
      list = await repo.watchCompletions(id).first;
      expect(list.map((c) => c.occurrence), [DateTime(2026, 11, 21)]);
    });
  });

  group('tags', () {
    test('CRUD e ordenação por nome', () async {
      final b = await repo.createTag(name: 'trabalho', colorKey: 'azul');
      await repo.createTag(name: 'estudo', colorKey: 'verde');

      var tags = await repo.watchTags().first;
      expect(tags.map((t) => t.name), ['estudo', 'trabalho']);

      final tag = tags.firstWhere((t) => t.id == b);
      await repo.saveTag(tag.copyWith(name: 'aulas', colorKey: 'rosa'));
      tags = await repo.watchTags().first;
      expect(tags.map((t) => t.name), ['aulas', 'estudo']);
      expect(tags.first.colorKey, 'rosa');
    });

    test('vincular, desvincular e revincular reaproveita a linha', () async {
      final task = await repo.createTask(title: 'Ler');
      final tag = await repo.createTag(name: 'estudo', colorKey: 'azul');

      await repo.addTagToTask(task, tag);
      await repo.addTagToTask(task, tag); // repetir não duplica
      expect((await repo.watchTagsOfTask(task).first).map((t) => t.id), [tag]);

      await repo.removeTagFromTask(task, tag);
      expect(await repo.watchTagsOfTask(task).first, isEmpty);

      await repo.addTagToTask(task, tag);
      expect((await repo.watchTagsOfTask(task).first).map((t) => t.id), [tag]);

      final links = await db.select(db.taskTags).get();
      expect(links, hasLength(1));
      expect(links.single.deletedAt, isNull);
    });

    test('excluir a tag remove os vínculos', () async {
      final task = await repo.createTask(title: 'Ler');
      final tag = await repo.createTag(name: 'estudo', colorKey: 'azul');
      await repo.addTagToTask(task, tag);

      await repo.deleteTag(tag);

      expect(await repo.watchTags().first, isEmpty);
      expect(await repo.watchTagsOfTask(task).first, isEmpty);
      final link = await db.select(db.taskTags).getSingle();
      expect(link.deletedAt, isNotNull);
    });
  });

  group('calendário', () {
    DateTime d(int day, [int h = 0]) => DateTime(2026, 11, day, h);

    test(
      'watchTasksInRange pega o que toca o intervalo e as rotinas',
      () async {
        await repo.createTask(title: 'dentro', dueAt: d(24, 9), hasTime: true);
        await repo.createTask(title: 'só início', startAt: d(25, 9));
        await repo.createTask(
          title: 'vários dias',
          startAt: d(20),
          dueAt: d(23),
        );
        await repo.createTask(title: 'antes', dueAt: d(20));
        await repo.createTask(title: 'depois', dueAt: d(30));
        await repo.createTask(title: 'sem data');
        await repo.createTask(
          title: 'rotina antiga',
          dueAt: d(1),
          recurrenceRule: 'FREQ=DAILY',
        );
        await repo.createTask(
          title: 'rotina futura',
          dueAt: d(30),
          recurrenceRule: 'FREQ=DAILY',
        );
        final excluded = await repo.createTask(title: 'excluída', dueAt: d(24));
        await repo.deleteTask(excluded);

        final tasks = await repo.watchTasksInRange(d(23), d(30)).first;
        expect(tasks.map((t) => t.title).toSet(), {
          'dentro',
          'só início',
          'vários dias',
          'rotina antiga',
        });
      },
    );

    test('conclusões por intervalo', () async {
      final id = await repo.createTask(
        title: 'r',
        dueAt: d(20),
        recurrenceRule: 'FREQ=DAILY',
      );
      await repo.addCompletion(id, d(22));
      await repo.addCompletion(id, d(24));
      final list = await repo.watchCompletionsBetween(d(23), d(30)).first;
      expect(list.map((c) => c.occurrence), [d(24)]);
    });

    test('rescheduleTask grava só início, prazo e hora', () async {
      final id = await repo.createTask(
        title: 'a',
        notes: 'n',
        dueAt: d(24),
        reminderMinutesBefore: 10,
      );
      await repo.rescheduleTask(id, startAt: d(25, 9), dueAt: d(25, 10));
      final task = (await repo.getTask(id))!;
      expect(
        (task.startAt, task.dueAt, task.hasTime),
        (d(25, 9), d(25, 10), true),
      );
      expect(
        (task.notes, task.reminderMinutesBefore, task.dirty),
        ('n', 10, true),
      );
    });
  });
}
