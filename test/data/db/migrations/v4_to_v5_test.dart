import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v4.dart' as v4;

/// v4 → v5: tarefas ganham `reminderOffsets` e `nagIntervalMinutes` (nulos),
/// preservando todos os dados existentes.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  final t0 = DateTime(2026, 11, 24).millisecondsSinceEpoch ~/ 1000;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'tarefas preservam lembrete e modo alarme e recebem novas colunas nulas',
    () async {
      final schema = await verifier.schemaAt(4);
      final old = v4.DatabaseAtV4(schema.newConnection());
      await old
          .into(old.tasks)
          .insert(
            v4.TasksData(
              id: 't1',
              createdAt: t0,
              updatedAt: t0,
              dirty: 1,
              title: 'Consulta',
              kind: 'evento',
              status: 'aFazer',
              priority: 3,
              hasTime: 1,
              reminderMinutesBefore: 30,
              reminderMode: 'alarme',
              sortOrder: 0,
            ),
          );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 5);
      final task = await db.select(db.tasks).getSingle();
      expect(
        (
          task.title,
          task.reminderMinutesBefore,
          task.reminderMode,
          task.reminderOffsets,
          task.nagIntervalMinutes,
        ),
        ('Consulta', 30, ReminderMode.alarme, null, null),
      );
    },
  );
}
