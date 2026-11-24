import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v3.dart' as v3;

/// v3 → v4: tarefas ganham `reminderMode` com padrão `notificacao`, sem perder
/// nada.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  final t0 = DateTime(2026, 11, 24).millisecondsSinceEpoch ~/ 1000;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'tarefas mantêm lembrete e recebem modo notificacao por padrão',
    () async {
      final schema = await verifier.schemaAt(3);
      final old = v3.DatabaseAtV3(schema.newConnection());
      await old
          .into(old.tasks)
          .insert(
            v3.TasksData(
              id: 't1',
              createdAt: t0,
              updatedAt: t0,
              dirty: 1,
              title: 'Remédio',
              kind: 'rotina',
              status: 'aFazer',
              priority: 2,
              hasTime: 1,
              reminderMinutesBefore: 15,
              sortOrder: 1,
            ),
          );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 4);
      final task = await db.select(db.tasks).getSingle();
      expect(
        (task.title, task.reminderMinutesBefore, task.reminderMode),
        ('Remédio', 15, ReminderMode.notificacao),
      );
    },
  );
}
