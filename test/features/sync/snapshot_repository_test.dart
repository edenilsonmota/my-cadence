import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/card_schedule.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/sync/data/snapshot_repository.dart';
import 'package:my_cadence/features/sync/domain/merge.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';
import 'package:my_cadence/features/sync/domain/upgraders.dart';

import '../../data/test_db.dart';
import 'seed.dart';

final now = DateTime(2026, 11, 24, 12);

Future<Snapshot> roundTrip(Snapshot s) async => Snapshot.decode(s.encode());

void main() {
  test('esquema do snapshot anda junto com o do banco', () {
    final db = openTestDb();
    expect(currentSchemaVersion, db.schemaVersion);
  });

  test(
    'ida e volta banco → snapshot → banco sem perda, em todas as tabelas',
    () async {
      final a = openTestDb();
      await seedEverything(a);
      final source = SnapshotRepository(a);
      final sent = await roundTrip(await source.readLocal(now: now));

      for (final t in syncTables) {
        if (t == 'app_settings') continue;
        expect(sent.rows(t), isNotEmpty, reason: 'semente cobre $t');
      }
      // Colunas de estado local e ajustes do aparelho ficam de fora.
      expect(sent.rows('tasks').first.containsKey('dirty'), isFalse);
      expect(sent.rows('tasks').first.containsKey('server_version'), isFalse);
      final keys = sent.rows('app_settings').map((r) => r['key']).toSet();
      expect(keys, contains('pomodoro.focus'));
      expect(keys.where((k) => isLocalSetting(k! as String)), isEmpty);

      // Ordem invertida: filhas antes das mães (chaves estrangeiras adiadas).
      final reversed = sent.copyWith(
        tables: {for (final t in syncTables) t: sent.rows(t).reversed.toList()},
      );
      final b = openTestDb();
      final target = SnapshotRepository(b);
      final result = merge(
        await target.readLocal(now: now),
        reversed,
        now: now,
      );
      await target.apply(result);

      final copy = await target.readLocal(now: now);
      for (final t in syncTables) {
        expect(copy.rows(t), sent.rows(t), reason: 'tabela $t');
      }
      // Veio do remoto: já está sincronizado.
      expect(await target.hasDirty(), isFalse);

      // E o app lê normalmente (enums, datas, nulos e números).
      final task = (await TasksRepository(
        b.tasksDao,
        b.tagsDao,
      ).watchAllTasks().first).firstWhere((t) => t.title == 'Estudar');
      expect(task.kind, TaskKind.estudo);
      expect(task.dueAt, DateTime(2026, 11, 25, 14));
      expect(
        (task.colorKey, task.iconKey, task.notes),
        ('violeta', 'brain', null),
      );
      final card = (await CardsRepository(
        b.cardsDao,
      ).watchCards().first).single;
      expect((card.stability, card.state), (3.25, CardState.review));
    },
  );

  test(
    'aplicar avisa as consultas observadas (telas atualizam sozinhas)',
    () async {
      final a = openTestDb();
      await TasksRepository(a.tasksDao, a.tagsDao).createTask(title: 'Remota');
      final b = openTestDb();
      final tasksB = TasksRepository(b.tasksDao, b.tagsDao);
      final seen = <List<String>>[];
      final sub = tasksB.watchAllTasks().listen(
        (l) => seen.add([for (final t in l) t.title]),
      );
      addTearDown(sub.cancel);
      await pumpEventQueue();

      final target = SnapshotRepository(b);
      await target.apply(
        merge(
          await target.readLocal(now: now),
          await SnapshotRepository(a).readLocal(now: now),
          now: now,
        ),
      );
      await pumpEventQueue();
      expect(seen.last, ['Remota']);
    },
  );

  test('ajuste com o mesmo nome em dois aparelhos vira uma linha só', () async {
    final a = openTestDb();
    final b = openTestDb();
    await SettingsRepository(b.settingsDao).setString('pomodoro.focus', '25');
    // O de A é mais novo (criado depois).
    await Future<void>.delayed(const Duration(seconds: 1));
    await SettingsRepository(a.settingsDao).setString('pomodoro.focus', '50');

    final target = SnapshotRepository(b);
    await target.apply(
      merge(
        await target.readLocal(now: now),
        await SnapshotRepository(a).readLocal(now: now),
        now: now,
      ),
    );
    final rows = await b.select(b.appSettings).get();
    final focus = rows.where((r) => r.key == 'pomodoro.focus').toList();
    expect(focus, hasLength(1));
    expect(focus.single.value, '50');
  });

  test('tombstone vencido é removido de vez do banco', () async {
    final db = openTestDb();
    final tasks = TasksRepository(db.tasksDao, db.tagsDao);
    final id = await tasks.createTask(title: 'Antiga');
    await tasks.deleteTask(id);
    final repo = SnapshotRepository(db);
    final later = DateTime.now().add(const Duration(days: 200));
    final local = await repo.readLocal(now: later);
    await repo.apply(merge(local, local, now: later));
    final raw = await db.customSelect('SELECT id FROM tasks').get();
    expect(raw, isEmpty);
  });

  test('markClean só limpa o que não mudou depois do envio', () async {
    final db = openTestDb();
    final tasks = TasksRepository(db.tasksDao, db.tagsDao);
    final keep = await tasks.createTask(title: 'Enviada');
    final edited = await tasks.createTask(title: 'Editada durante o sync');
    final repo = SnapshotRepository(db);
    final sent = await repo.readLocal(now: now);

    // Edição depois do envio, com updated_at diferente.
    await Future<void>.delayed(const Duration(seconds: 1));
    final t = (await tasks.getTask(edited))!;
    await tasks.saveTask(t.copyWith(title: 'Nova'));

    await repo.markClean(sent);
    expect((await rawRow(db, 'tasks', keep))['dirty'], 0);
    expect((await rawRow(db, 'tasks', edited))['dirty'], 1);
  });

  test('escritas comuns marcam dirty e atualizam updated_at', () async {
    final db = openTestDb();
    final tasks = TasksRepository(db.tasksDao, db.tagsDao);
    final books = BooksRepository(db.booksDao);
    final cards = CardsRepository(db.cardsDao);
    final pomodoro = PomodoroRepository(db.pomodoroDao);
    final task = await tasks.createTask(title: 'T');
    final book = await books.createBook(title: 'B');
    final p1 = await books.createPage(notebookId: book, title: '1');
    final p2 = await books.createPage(notebookId: book, title: '2');
    final card = await cards.createCard(front: 'f', back: 'b', now: now);
    final session = await pomodoro.startSession(
      kind: PomodoroKind.foco,
      plannedMinutes: 25,
      startedAt: now,
    );
    for (final t in [
      'tasks',
      'note_pages',
      'flashcards',
      'pomodoro_sessions',
    ]) {
      await markAllSynced(db, t);
    }

    await tasks.completeTask(task, now: now);
    await books.reorderPages([p2, p1]);
    await cards.applyReview(
      cardId: card,
      next: CardSchedule(state: CardState.review, due: now),
      rating: 3,
      reviewedAt: now,
    );
    await pomodoro.finishSession(session, endedAt: now, completed: true);

    for (final (table, id) in [
      ('tasks', task),
      ('note_pages', p1),
      ('flashcards', card),
      ('pomodoro_sessions', session),
    ]) {
      final row = await rawRow(db, table, id);
      expect(
        (row['dirty'], (row['updated_at']! as int) > 0),
        (1, true),
        reason: table,
      );
    }
  });
}
