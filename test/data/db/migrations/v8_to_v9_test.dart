import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v8.dart' as v8;

/// v8 → v9: tarefas ganham `skip_missed` (`true`) e conclusões de rotina
/// ganham `status` (`concluida`).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  final t0 = DateTime(2026, 11, 25, 9).millisecondsSinceEpoch ~/ 1000;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'rotina antiga vira não acumulativa e histórico fica concluído',
    () async {
      final schema = await verifier.schemaAt(8);
      final old = v8.DatabaseAtV8(schema.newConnection());
      await old
          .into(old.tasks)
          .insert(
            v8.TasksData(
              id: 'r1',
              createdAt: t0,
              updatedAt: t0,
              dirty: 1,
              title: 'Estudar inglês',
              kind: 'simples',
              status: 'aFazer',
              priority: 0,
              hasTime: 0,
              recurrenceRule: 'FREQ=DAILY',
              reminderMode: 'notificacao',
              sortOrder: 0,
            ),
          );
      await old
          .into(old.taskCompletions)
          .insert(
            v8.TaskCompletionsData(
              id: 'c1',
              createdAt: t0,
              updatedAt: t0,
              dirty: 1,
              taskId: 'r1',
              occurrence: t0,
            ),
          );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 9);

      final task = await db.select(db.tasks).getSingle();
      expect(task.skipMissed, isTrue);

      final completion = await db.select(db.taskCompletions).getSingle();
      expect(completion.status, OccurrenceStatus.concluida);
    },
  );
}
