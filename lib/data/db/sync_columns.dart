import 'package:drift/drift.dart';

import '../../core/ids.dart';

/// Colunas de sincronização presentes em todas as tabelas.
///
/// Nenhuma linha é apagada fisicamente: exclusão grava [deletedAt].
/// Toda escrita deve passar por `SyncWrites` (ver `sync_writes.dart`), que
/// atualiza [updatedAt] e marca [dirty].
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  IntColumn get serverVersion => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
