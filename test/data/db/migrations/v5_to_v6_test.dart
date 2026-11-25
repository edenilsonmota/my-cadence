import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v5.dart' as v5;

/// v5 → v6: novas tabelas de vínculo tarefa ↔ book e tarefa ↔ deck, sem
/// mexer nos dados.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  final t0 = DateTime(2026, 11, 25).millisecondsSinceEpoch ~/ 1000;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'tarefas e books seguem intactos e a tabela nova começa vazia',
    () async {
      final schema = await verifier.schemaAt(5);
      final old = v5.DatabaseAtV5(schema.newConnection());
      await old
          .into(old.tasks)
          .insert(
            v5.TasksData(
              id: 't1',
              createdAt: t0,
              updatedAt: t0,
              dirty: 1,
              title: 'Estudar física',
              kind: 'estudo',
              status: 'aFazer',
              priority: 2,
              hasTime: 0,
              reminderMode: 'notificacao',
              sortOrder: 0,
            ),
          );
      await old
          .into(old.notebooks)
          .insert(
            v5.NotebooksData(
              id: 'n1',
              createdAt: t0,
              updatedAt: t0,
              dirty: 1,
              title: 'Física',
            ),
          );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 6);
      expect((await db.select(db.tasks).getSingle()).title, 'Estudar física');
      expect((await db.select(db.notebooks).getSingle()).title, 'Física');
      expect(await db.select(db.taskNotebookLinks).get(), isEmpty);
      expect(await db.select(db.taskDeckLinks).get(), isEmpty);

      await db.booksDao.setTaskNotebooks('t1', {'n1'});
      expect(
        (await db.booksDao.watchLinkedNotebooks('t1').first).single.id,
        'n1',
      );
    },
  );
}
