import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v1.dart' as v1;
import 'app/generated/schema_v2.dart' as v2;

/// v1 → v2: cores ARGB viram chaves da paleta; emoji dos books sai.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  // Os dados da v1 usam os tipos brutos do SQLite (segundos e 0/1).
  final t0 = DateTime(2026, 11, 20).millisecondsSinceEpoch ~/ 1000;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('tags, tarefas e books mantêm os dados e ganham as chaves', () async {
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old.batch((b) {
      b.insertAll(old.tags, [
        for (final (id, argb) in [
          ('azul', 0xFF1E88E5),
          ('verde', 0xFF43A047),
          ('laranja', 0xFFF4511E),
          ('violeta', 0xFF8E24AA),
          ('ambar', 0xFFFDD835),
          ('ciano', 0xFF00ACC1),
          ('rosa', 0xFFD81B60),
          ('marrom', 0xFF6D4C41),
          ('estranha', 0xFF123456),
        ])
          v1.TagsData(
            id: id,
            createdAt: t0,
            updatedAt: t0,
            dirty: 1,
            name: id,
            color: argb,
          ),
      ]);
      b.insert(
        old.tasks,
        v1.TasksCompanion.insert(
          id: 't1',
          createdAt: t0,
          updatedAt: t0,
          dirty: const Value(1),
          title: 'Estudar',
          color: const Value(0xFF00796B),
        ),
      );
      b.insert(
        old.notebooks,
        v1.NotebooksCompanion.insert(
          id: 'n1',
          createdAt: t0,
          updatedAt: t0,
          dirty: const Value(1),
          title: 'Física',
          icon: const Value('📘'),
        ),
      );
    });
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);

    // Lê pelo esquema da v2 (o AppDatabase atual já tem colunas de versões
    // posteriores em `tasks`).
    final migrated = v2.DatabaseAtV2(schema.newConnection());
    addTearDown(migrated.close);

    final tags = {
      for (final t in await migrated.select(migrated.tags).get())
        t.id: t.colorKey,
    };
    expect(tags, {
      'azul': 'azul',
      'verde': 'verde',
      'laranja': 'laranja',
      'violeta': 'violeta',
      'ambar': 'ambar',
      'ciano': 'ciano',
      'rosa': 'rosa',
      'marrom': 'ardosia',
      'estranha': 'azul',
    });
    final task = await migrated.select(migrated.tasks).getSingle();
    expect((task.title, task.colorKey, task.iconKey), ('Estudar', null, null));
    final book = await migrated.select(migrated.notebooks).getSingle();
    expect((book.title, book.colorKey, book.iconKey), ('Física', null, null));
  });
}
