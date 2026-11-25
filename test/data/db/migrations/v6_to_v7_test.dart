import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v6.dart' as v6;

/// v6 → v7: sessões de pomodoro ganham `manual` (falso), preservando o resto.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  final t0 = DateTime(2026, 11, 25, 9).millisecondsSinceEpoch ~/ 1000;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('sessão antiga continua igual e não é manual', () async {
    final schema = await verifier.schemaAt(6);
    final old = v6.DatabaseAtV6(schema.newConnection());
    await old
        .into(old.pomodoroSessions)
        .insert(
          v6.PomodoroSessionsData(
            id: 's1',
            createdAt: t0,
            updatedAt: t0,
            dirty: 1,
            kind: 'foco',
            startedAt: t0,
            endedAt: t0 + 25 * 60,
            plannedMinutes: 25,
            pausedTotalMs: 0,
            completed: 1,
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 7);
    final s = await db.select(db.pomodoroSessions).getSingle();
    expect((s.plannedMinutes, s.completed, s.manual), (25, true, false));
  });
}
