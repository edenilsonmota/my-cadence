import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late TasksRepository repo;

  setUp(() {
    db = openTestDb();
    repo = TasksRepository(db.tasksDao, db.tagsDao);
  });

  test('inserção gera UUID v7 e marca dirty', () async {
    final id = await repo.createTask(title: 'Ler');
    final row = await rawRow(db, 'tasks', id);

    expect(id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-')));
    expect(row['dirty'], 1);
    expect(row['created_at'], isNotNull);
    expect(row['updated_at'], isNotNull);
    expect(row['deleted_at'], isNull);
    expect(row['server_version'], isNull);
  });

  test('atualização renova updatedAt e volta a marcar dirty', () async {
    final id = await repo.createTask(title: 'Ler');
    await markAllSynced(db, 'tasks');

    final task = (await repo.getTask(id))!;
    expect(task.dirty, isFalse);
    await repo.saveTask(task.copyWith(title: 'Ler capítulo 2'));

    final saved = (await repo.getTask(id))!;
    expect(saved.title, 'Ler capítulo 2');
    expect(saved.dirty, isTrue);
    expect(saved.updatedAt.isAfter(DateTime(2000)), isTrue);
  });

  test('salvar não sobrescreve as colunas de sync', () async {
    final id = await repo.createTask(title: 'Ler');
    await db.customUpdate('UPDATE tasks SET server_version = 42');
    final stale = (await repo.getTask(id))!
        .copyWith(serverVersion: const Value(null));

    await repo.saveTask(stale);

    expect((await repo.getTask(id))!.serverVersion, 42);
  });

  test('exclusão é lógica: a linha fica com deletedAt e dirty', () async {
    final id = await repo.createTask(title: 'Ler');
    await markAllSynced(db, 'tasks');

    await repo.deleteTask(id);

    expect(await repo.getTask(id), isNull);
    final row = await rawRow(db, 'tasks', id);
    expect(row['deleted_at'], isNotNull);
    expect(row['dirty'], 1);
  });

  test('foreign keys estão ativas', () async {
    expect(
      () => repo.addCompletion('não-existe', DateTime(2026)),
      throwsA(isA<SqliteException>()),
    );
  });

  test('enums são gravados pelo nome', () async {
    final id = await repo.createTask(title: 'Ler');
    final row = await rawRow(db, 'tasks', id);
    expect(row['kind'], 'simples');
    expect(row['status'], 'aFazer');
  });
}
