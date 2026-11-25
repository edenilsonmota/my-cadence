import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v7.dart' as v7;

/// v7 → v8: sem tipo na interface (cor/ícone gravados onde a aparência
/// mudaria), tempo estimado a partir dos pomodoros e tabela de modelos.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  final t0 = DateTime(2026, 11, 25, 9).millisecondsSinceEpoch ~/ 1000;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  v7.TasksData task(
    String id, {
    String kind = 'simples',
    String? parentId,
    int? pomodoros,
  }) => v7.TasksData(
    id: id,
    createdAt: t0,
    updatedAt: t0,
    dirty: 1,
    parentId: parentId,
    title: id,
    kind: kind,
    status: 'aFazer',
    priority: 0,
    hasTime: 0,
    reminderMode: 'notificacao',
    estimatedPomodoros: pomodoros,
    sortOrder: 0,
  );

  test(
    'estudo mantém o visual, filho não herda, estimativa vira tempo',
    () async {
      final schema = await verifier.schemaAt(7);
      final old = v7.DatabaseAtV7(schema.newConnection());
      for (final t in [
        task('prova', kind: 'estudo', pomodoros: 4),
        task('parte', parentId: 'prova'),
        task('mercado'),
      ]) {
        await old.into(old.tasks).insert(t);
      }
      await old.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 8);
      final byId = {for (final t in await db.select(db.tasks).get()) t.id: t};

      expect(
        (byId['prova']!.colorKey, byId['prova']!.iconKey),
        ('violeta', 'graduation-cap'),
      );
      expect(byId['prova']!.estimatedMinutes, 100);
      // Era azul/check (o tipo dele); agora grava para não herdar o violeta.
      expect(
        (byId['parte']!.colorKey, byId['parte']!.iconKey),
        ('azul', 'square-check'),
      );
      expect(
        (byId['mercado']!.colorKey, byId['mercado']!.iconKey),
        (null, null),
      );
      expect(await db.select(db.taskTemplates).get(), isEmpty);
    },
  );
}
