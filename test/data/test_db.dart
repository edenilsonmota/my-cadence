import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';

/// Banco em memória, fechado ao fim do teste.
AppDatabase openTestDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// Simula o sync: marca tudo como enviado e com `updatedAt` antigo.
Future<void> markAllSynced(AppDatabase db, String table) => db.customUpdate(
  'UPDATE $table SET dirty = 0, updated_at = 0',
  updates: {
    for (final t in db.allTables)
      if (t.actualTableName == table) t,
  },
);

/// Linha crua (inclusive excluída logicamente), direto do SQLite.
Future<Map<String, Object?>> rawRow(
  AppDatabase db,
  String table,
  String id,
) async {
  final row = await db
      .customSelect(
        'SELECT * FROM $table WHERE id = ?',
        variables: [Variable(id)],
      )
      .getSingle();
  return row.data;
}
