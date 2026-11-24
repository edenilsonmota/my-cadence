import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';

import 'app/generated/schema.dart';
import 'app/generated/schema_v2.dart' as v2;

/// v2 → v3: páginas ganham `iconKey` vazio, sem perder nada.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  final t0 = DateTime(2026, 11, 24).millisecondsSinceEpoch ~/ 1000;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('páginas mantêm título e conteúdo e ficam sem ícone', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    await old
        .into(old.notebooks)
        .insert(
          v2.NotebooksData(
            id: 'b',
            createdAt: t0,
            updatedAt: t0,
            dirty: 1,
            title: 'Book',
          ),
        );
    await old
        .into(old.notePages)
        .insert(
          v2.NotePagesData(
            id: 'p',
            createdAt: t0,
            updatedAt: t0,
            dirty: 1,
            notebookId: 'b',
            title: 'Página',
            content: '{"x":1}',
            sortOrder: 3,
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
    final page = await db.select(db.notePages).getSingle();
    expect(
      (page.title, page.content, page.sortOrder, page.iconKey),
      ('Página', '{"x":1}', 3, null),
    );
  });
}
