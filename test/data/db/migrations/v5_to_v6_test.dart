import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v5.dart' as v5;
import 'app/generated/schema_v6.dart' as v6;

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
      await verifier.migrateAndValidate(db, 6);
      await db.close();

      final db6 = v6.DatabaseAtV6(schema.newConnection());
      addTearDown(db6.close);
      expect((await db6.select(db6.tasks).getSingle()).title, 'Estudar física');
      expect((await db6.select(db6.notebooks).getSingle()).title, 'Física');
      expect(await db6.select(db6.taskNotebookLinks).get(), isEmpty);
      expect(await db6.select(db6.taskDeckLinks).get(), isEmpty);
    },
  );
}
