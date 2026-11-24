import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';

import 'app/generated/schema.dart';

// Ao mudar o esquema: incrementar `schemaVersion`, rodar
// `dart run drift_dev make-migrations` e acrescentar um teste de integridade
// dos dados para o novo passo.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('banco criado do zero bate com as tabelas declaradas', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.validateDatabaseSchema();
  });

  test('existe dump do esquema da versão atual', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(GeneratedHelper.versions, contains(db.schemaVersion));
  });

  for (final from in GeneratedHelper.versions) {
    test('migra da versão $from para a atual', () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);
    });
  }

  test('foreign keys ficam ativas ao abrir', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });
}
